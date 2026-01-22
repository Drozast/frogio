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

  static const String _accessTokenKey = 'access_token';

  EnhancedReportApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  Map<String, String> get _authHeaders {
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/reports'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ReportModel.fromApi(json)).toList();
      } else {
        throw Exception('Error al obtener reportes');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<ReportModel> getReportById(String reportId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReportModel.fromApi(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener reporte');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> createReport(CreateReportParams params) async {
    try {
      // Mapear categoría del app a tipo de reporte del backend
      final reportType = _mapCategoryToType(params.category);

      // Crear el reporte primero
      final response = await client.post(
        Uri.parse('$baseUrl/api/reports'),
        headers: _authHeaders,
        body: json.encode({
          'title': params.title,
          'description': params.description,
          'reportType': reportType,
          'priority': params.priority.name,
          'location': '${params.location.latitude},${params.location.longitude}',
          'locationDetails': params.location.address ?? '',
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
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        headers: _authHeaders,
        body: json.encode({
          'status': _mapStatusToBackend(status),
          if (comment != null) 'response': comment,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar reporte');
      }
    } catch (e) {
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
        headers: _authHeaders,
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
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<ReportModel>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
  }) async {
    try {
      final queryParams = <String, String>{
        'status': _mapStatusToBackend(status),
      };
      if (assignedTo != null) {
        queryParams['assignedTo'] = assignedTo;
      }

      final uri = Uri.parse('$baseUrl/api/reports').replace(queryParameters: queryParams);
      final response = await client.get(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ReportModel.fromApi(json)).toList();
      } else {
        throw Exception('Error al obtener reportes por estado');
      }
    } catch (e) {
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
        headers: _authHeaders,
        body: json.encode({
          'assignedTo': assignedToId,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al asignar reporte');
      }
    } catch (e) {
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

        final token = prefs.getString(_accessTokenKey);
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

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
    switch (category.toLowerCase()) {
      case 'denuncia':
      case 'complaint':
        return 'complaint';
      case 'sugerencia':
      case 'suggestion':
        return 'suggestion';
      case 'emergencia':
      case 'emergency':
        return 'emergency';
      case 'solicitud':
      case 'request':
        return 'request';
      case 'incidente':
      case 'incident':
        return 'incident';
      default:
        return 'complaint';
    }
  }

  String _mapStatusToBackend(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'borrador';
      case ReportStatus.submitted:
        return 'pendiente';
      case ReportStatus.reviewing:
        return 'en_revision';
      case ReportStatus.inProgress:
        return 'en_proceso';
      case ReportStatus.resolved:
        return 'resuelto';
      case ReportStatus.rejected:
        return 'rechazado';
      case ReportStatus.archived:
        return 'archivado';
    }
  }
}
