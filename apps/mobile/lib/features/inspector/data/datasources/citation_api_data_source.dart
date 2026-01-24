// lib/features/inspector/data/datasources/citation_api_data_source.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../models/citation_model.dart';
import 'citation_remote_data_source.dart';

class CitationApiDataSource implements CitationRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  static const String _accessTokenKey = 'access_token';

  CitationApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  Map<String, String> get _authHeaders {
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
      'x-tenant-id': ApiConfig.tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<CitationModel>> getCitations({CitationFilters? filters}) async {
    try {
      final queryParams = filters?.toQueryParams() ?? {};
      final uri = Uri.parse('$baseUrl/api/citations').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await client.get(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CitationModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener citaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<CitationModel> getCitationById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/citations/$id'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CitationModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener citación');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<CitationModel> createCitation(CreateCitationDto dto) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/citations'),
        headers: _authHeaders,
        body: json.encode(dto.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CitationModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al crear citación');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<CitationModel> updateCitation(String id, UpdateCitationDto dto) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/citations/$id'),
        headers: _authHeaders,
        body: json.encode(dto.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CitationModel.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar citación');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCitation(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/api/citations/$id'),
        headers: _authHeaders,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al eliminar citación');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<CitationModel>> getMyCitations() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/citations/my'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CitationModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener mis citaciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> generateCitationNumber() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/citations/generate-number'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['citationNumber'] as String;
      } else {
        // Generar número localmente como fallback
        final now = DateTime.now();
        return 'CIT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
      }
    } catch (e) {
      // Generar número localmente como fallback
      final now = DateTime.now();
      return 'CIT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}';
    }
  }

  @override
  Future<List<String>> uploadPhotos(List<File> photos) async {
    final List<String> uploadedUrls = [];
    // UUID temporal para archivos de citación (se usa UUID válido de placeholder)
    const tempEntityId = '00000000-0000-0000-0000-000000000001';

    for (final photo in photos) {
      try {
        final token = prefs.getString(_accessTokenKey);

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/files/upload'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['entityType'] = 'citation';
        request.fields['entityId'] = tempEntityId;

        // Determinar el content type basado en la extensión
        final extension = photo.path.split('.').last.toLowerCase();
        String contentType;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
          default:
            contentType = 'image/jpeg'; // Default a JPEG
        }

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          photo.path,
          contentType: MediaType.parse(contentType),
        ));

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = json.decode(response.body);
          // Get the file URL from response
          final fileId = data['id'] as String;
          uploadedUrls.add('$baseUrl/api/files/serve/santa_juana/$fileId');
        } else {
          final error = json.decode(response.body);
          throw Exception(error['error'] ?? 'Error al subir foto');
        }
      } catch (e) {
        throw Exception('Error al subir foto: ${e.toString()}');
      }
    }

    return uploadedUrls;
  }
}
