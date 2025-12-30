// lib/features/inspector/data/datasources/infraction_api_data_source.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/infraction_model.dart';
import 'infraction_remote_data_source.dart';

class InfractionApiDataSource implements InfractionRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  static const String _accessTokenKey = 'access_token';

  InfractionApiDataSource({
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
  Future<List<InfractionModel>> getInfractionsByInspector(String inspectorId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/infractions'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => InfractionModel.fromApi(json)).toList();
      } else {
        throw Exception('Error al obtener infracciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> getInfractionById(String infractionId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/infractions/$infractionId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InfractionModel.fromApi(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener infracción');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> createInfraction(InfractionModel infraction) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/infractions'),
        headers: _authHeaders,
        body: json.encode({
          'infractionType': infraction.title,
          'description': infraction.description,
          'location': infraction.location['address'] ?? '',
          'amount': 0, // Debe ser configurado según la ordenanza
          'vehiclePlate': infraction.offenderDocument, // Asumiendo que es patente
          'dueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return InfractionModel.fromApi(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al crear infracción');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> updateInfraction(InfractionModel infraction) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/infractions/${infraction.id}'),
        headers: _authHeaders,
        body: json.encode({
          'description': infraction.description,
          'status': _mapStatusToBackend(infraction.status),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InfractionModel.fromApi(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar infracción');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> updateInfractionStatus(
    String infractionId,
    String status,
    String? comment,
  ) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/infractions/$infractionId'),
        headers: _authHeaders,
        body: json.encode({
          'status': _mapStatusToBackend(status),
          if (comment != null) 'notes': comment,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar estado');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadEvidenceImage(String infractionId, File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/files/upload'),
      );

      final token = prefs.getString(_accessTokenKey);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['entityType'] = 'infraction';
      request.fields['entityId'] = infractionId;

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        image.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        throw Exception('Error al subir imagen');
      }
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadSignature(String infractionId, String signatureData) async {
    // NOTE: Subida de firma como archivo pendiente - usar MinIO para archivos
    throw UnimplementedError('Subida de firma no implementada aún');
  }

  @override
  Future<void> deleteInfraction(String infractionId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/infractions/$infractionId'),
        headers: _authHeaders,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al eliminar infracción');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadInfractionImages(
    List<File> images,
    String infractionId,
  ) async {
    final List<String> uploadedIds = [];

    for (final image in images) {
      try {
        final id = await uploadEvidenceImage(infractionId, image);
        uploadedIds.add(id);
      } catch (e) {
        // Error al subir imagen - continúa con las demás
      }
    }

    return uploadedIds;
  }

  @override
  Future<List<InfractionModel>> getInfractionsByStatus(
    String status, {
    String? muniId,
  }) async {
    try {
      // En el backend actual no hay filtro por status en la URL
      // Obtener todas y filtrar localmente
      final allInfractions = await getInfractionsByInspector('');
      return allInfractions.where((i) => i.status == status).toList();
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<InfractionModel>> getInfractionsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? muniId,
  }) async {
    // NOTE: Búsqueda geográfica pendiente - requiere índice espacial en PostgreSQL
    throw UnimplementedError('Búsqueda por ubicación no implementada aún');
  }

  @override
  Future<Map<String, int>> getInfractionStatistics(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/infractions/stats'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'total': data['total'] ?? 0,
          'pendientes': data['pendientes'] ?? 0,
          'pagadas': data['pagadas'] ?? 0,
        };
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Stream<List<InfractionModel>> watchInfractionsByInspector(String inspectorId) {
    // Para implementar streaming, se necesitaría WebSocket o polling
    // Por ahora, retornar un stream vacío
    throw UnimplementedError('Streaming no implementado con REST API');
  }

  /// Mapear estados del app a estados del backend
  String _mapStatusToBackend(String status) {
    switch (status.toLowerCase()) {
      case 'created':
      case 'pendiente':
        return 'pendiente';
      case 'paid':
      case 'pagada':
        return 'pagada';
      case 'cancelled':
      case 'anulada':
        return 'anulada';
      default:
        return 'pendiente';
    }
  }
}
