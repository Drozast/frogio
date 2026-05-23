// lib/features/citizen/data/datasources/enhanced_report_api_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/enhanced_report_entity.dart';
import '../models/enhanced_report_model.dart';
import 'enhanced_report_remote_data_source.dart';

class EnhancedReportApiDataSource implements ReportRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  EnhancedReportApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/reports'),
        // AuthHttpClient handles auth headers automatically
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? decoded['reports'] ?? []);
        return data.map((json) => ReportModel.fromApi(json)).toList();
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : <String, dynamic>{};
        throw Exception(errorBody['error'] ?? 'Error al obtener reportes (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<ReportModel> getReportById(String reportId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        // AuthHttpClient handles auth headers automatically
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReportModel.fromApi(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener reporte');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> createReport(CreateReportParams params) async {
    try {
      // Mapear categoría del app a tipo de reporte del backend
      final reportType = _mapCategoryToType(params.category);
      final priority = _mapPriorityToBackend(params.priority);

      // Crear el reporte primero
      final response = await client.post(
        Uri.parse('$baseUrl/api/reports'),
        // AuthHttpClient handles auth headers automatically
        body: json.encode({
          'title': params.title,
          'description': params.description,
          'type': reportType,
          'priority': priority,
          'address': params.location.address ?? '',
          'latitude': params.location.latitude,
          'longitude': params.location.longitude,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final reportId = data['id'];

        // Subir imágenes si las hay
        if (params.attachments.isNotEmpty) {
          await uploadAttachments(params.attachments, reportId);
        }

        return reportId;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al crear reporte');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
    String? assignedTo,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        // AuthHttpClient handles auth headers automatically
        body: json.encode({
          'status': _mapStatusToBackend(status),
          if (comment != null) 'resolution': comment,
          if (assignedTo != null) 'assignedTo': assignedTo,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar reporte');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> addResponse({
    required String reportId,
    required String responderId,
    required String responderName,
    required String message,
    List<File>? attachments,
    required bool isPublic,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/reports/$reportId/responses'),
        // AuthHttpClient handles auth headers automatically
        body: json.encode({
          'message': message,
          'isPublic': isPublic,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al agregar respuesta');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<ReportModel>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
    String? createdBy,
  }) async {
    try {
      final queryParams = <String, String>{
        'status': _mapStatusToBackend(status),
      };
      if (assignedTo != null) {
        queryParams['assignedTo'] = assignedTo;
      }
      if (createdBy != null) {
        queryParams['createdBy'] = createdBy;
      }

      final uri = Uri.parse('$baseUrl/api/reports').replace(queryParameters: queryParams);
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? decoded['reports'] ?? []);
        return data.map((json) => ReportModel.fromApi(json)).toList();
      } else {
        throw Exception('Error al obtener reportes por estado');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> assignReport({
    required String reportId,
    required String assignedToId,
    required String assignedById,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        // AuthHttpClient handles auth headers automatically
        body: json.encode({
          'assignedTo': assignedToId,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al asignar reporte');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadAttachments(List<File> attachments, String reportId) async {
    try {
      final List<String> uploadedIds = [];

      for (final file in attachments) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/files/upload'),
        );

        // AuthHttpClient handles auth headers automatically via client.send()
        request.fields['entityType'] = 'report';
        request.fields['entityId'] = reportId;

        // Determinar el tipo MIME
        final extension = file.path.split('.').last.toLowerCase();
        String mimeType = 'jpeg';
        if (extension == 'png') {
          mimeType = 'png';
        } else if (extension == 'gif') {
          mimeType = 'gif';
        } else if (extension == 'webp') {
          mimeType = 'webp';
        }

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: http_parser.MediaType('image', mimeType),
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          uploadedIds.add(data['id']);
        }
      }

      return uploadedIds;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al subir archivos: ${e.toString()}');
    }
  }

  @override
  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    // Para REST API, usamos polling o simplemente retornamos un stream vacío
    // En producción, esto debería usar WebSockets o SSE
    return const Stream.empty();
  }

  @override
  Stream<List<ReportModel>> watchReportsByStatus(ReportStatus status, String muniId) {
    // Para REST API, usamos polling o simplemente retornamos un stream vacío
    return const Stream.empty();
  }

  String _mapCategoryToType(String category) {
    // Backend espera: 'denuncia' | 'sugerencia' | 'emergencia' | 'infraestructura' | 'otro'
    switch (category.toLowerCase()) {
      case 'infraestructura':
        return 'infraestructura';
      case 'seguridad':
        return 'denuncia';
      case 'medio ambiente':
        return 'denuncia';
      case 'servicios públicos':
        return 'infraestructura';
      case 'transporte':
        return 'infraestructura';
      case 'emergencia':
        return 'emergencia';
      case 'sugerencia':
        return 'sugerencia';
      case 'otro':
      default:
        return 'otro';
    }
  }

  String _mapPriorityToBackend(Priority priority) {
    // Backend espera: 'baja' | 'media' | 'alta' | 'urgente'
    switch (priority) {
      case Priority.low:
        return 'baja';
      case Priority.medium:
        return 'media';
      case Priority.high:
        return 'alta';
      case Priority.urgent:
        return 'urgente';
    }
  }

  String _mapStatusToBackend(ReportStatus status) {
    return status.toApiString();
  }
}
