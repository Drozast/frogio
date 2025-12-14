// lib/features/citizen/data/datasources/report_api_data_source.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';
import 'report_remote_data_source.dart';

class ReportApiDataSource implements ReportRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  static const String _accessTokenKey = 'access_token';

  ReportApiDataSource({
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
  Future<String> createReport({
    required String title,
    required String description,
    required String category,
    required LocationData location,
    required String userId,
    required List<File> images,
  }) async {
    try {
      // Mapear categoría del app a tipo de reporte del backend
      final reportType = _mapCategoryToType(category);

      // Crear el reporte primero
      final response = await client.post(
        Uri.parse('$baseUrl/api/reports'),
        headers: _authHeaders,
        body: json.encode({
          'title': title,
          'description': description,
          'reportType': reportType,
          'priority': 'medium', // Default
          'location': '${location.latitude},${location.longitude}',
          'locationDetails': location.address ?? '',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final reportId = data['id'];

        // Subir imágenes si las hay
        if (images.isNotEmpty) {
          await uploadReportImages(images, reportId);
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
  Future<void> updateReportStatus(
    String reportId,
    String status,
    String? comment,
    String userId,
  ) async {
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
  Future<void> deleteReport(String reportId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        headers: _authHeaders,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al eliminar reporte');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadReportImages(List<File> images, String reportId) async {
    try {
      final List<String> uploadedUrls = [];

      for (final image in images) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/files/upload'),
        );

        // Agregar headers de autorización
        final token = prefs.getString(_accessTokenKey);
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Agregar campos del formulario
        request.fields['entityType'] = 'report';
        request.fields['entityId'] = reportId;

        // Agregar archivo
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          image.path,
        ));

        // Enviar request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          uploadedUrls.add(data['id']); // ID del archivo en MinIO
        } else {
          // Error al subir imagen - se registra en el throw posterior si todas fallan
        }
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Error al subir imágenes: ${e.toString()}');
    }
  }

  /// Mapear categorías del app a tipos de reporte del backend
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

  /// Mapear estados del app a estados del backend
  String _mapStatusToBackend(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'pending':
        return 'pendiente';
      case 'en proceso':
      case 'in_progress':
        return 'en_proceso';
      case 'resuelto':
      case 'resolved':
        return 'resuelto';
      case 'rechazado':
      case 'rejected':
        return 'rechazado';
      default:
        return 'pendiente';
    }
  }
}
