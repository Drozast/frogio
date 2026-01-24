// lib/features/auth/data/datasources/auth_api_data_source.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/family_member_entity.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class AuthApiDataSource implements AuthRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;
  final String tenantId;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  AuthApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
    required this.tenantId,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Tenant-ID': tenantId,
  };

  Map<String, String> get _authHeaders {
    final token = prefs.getString(_accessTokenKey);
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Guardar tokens
        await prefs.setString(_accessTokenKey, data['accessToken']);
        await prefs.setString(_refreshTokenKey, data['refreshToken']);

        // Guardar datos del usuario
        final user = UserModel.fromApi(data['user']);
        await prefs.setString(_userDataKey, json.encode(data['user']));

        return user;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> registerWithEmailAndPassword(String email, String password, String name, String rut) async {
    try {
      // Dividir el nombre en nombres y apellidos (simplificado)
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Limpiar RUT (quitar puntos y guión para el backend)
      final cleanRut = rut.replaceAll('.', '').replaceAll('-', '');

      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'rut': cleanRut,
          'role': 'citizen',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        // Guardar tokens
        await prefs.setString(_accessTokenKey, data['accessToken']);
        await prefs.setString(_refreshTokenKey, data['refreshToken']);

        // Guardar datos del usuario
        final user = UserModel.fromApi(data['user']);
        await prefs.setString(_userDataKey, json.encode(data['user']));

        return user;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al registrar usuario');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: _authHeaders,
      );

      // Limpiar tokens locales independientemente de la respuesta
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
    } catch (e) {
      // Limpiar tokens incluso si falla la petición
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = prefs.getString(_userDataKey);
      if (userData == null) {
        return null;
      }

      final accessToken = prefs.getString(_accessTokenKey);
      if (accessToken == null) {
        return null;
      }

      // Obtener datos actualizados del usuario (incluyendo profileImageUrl)
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromApi(data);
        await prefs.setString(_userDataKey, json.encode(data));
        return user;
      } else if (response.statusCode == 401) {
        // Token expirado, intentar refrescar
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return getCurrentUser();
        }
        return null;
      } else {
        // Usar datos almacenados localmente
        return UserModel.fromApi(json.decode(userData));
      }
    } catch (e) {
      // En caso de error, devolver datos locales si existen
      final userData = prefs.getString(_userDataKey);
      if (userData != null) {
        return UserModel.fromApi(json.decode(userData));
      }
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: _headers,
        body: json.encode({'email': email}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al solicitar recuperación');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? rut,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    String? referenceNotes,
    List<FamilyMemberEntity>? familyMembers,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) {
        final nameParts = name.split(' ');
        updateData['firstName'] = nameParts.first;
        if (nameParts.length > 1) {
          updateData['lastName'] = nameParts.sublist(1).join(' ');
        }
      }
      if (rut != null) updateData['rut'] = rut;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (referenceNotes != null) updateData['referenceNotes'] = referenceNotes;
      if (familyMembers != null) {
        updateData['familyMembers'] = familyMembers.map((m) => m.toJson()).toList();
      }

      final response = await client.patch(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _authHeaders,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromApi(data);
        await prefs.setString(_userDataKey, json.encode(data));
        return user;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final token = prefs.getString(_accessTokenKey);

      // Usar multipart request para subir archivos
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/files/upload'),
      );

      // Headers
      request.headers['X-Tenant-ID'] = tenantId;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Agregar el archivo con content-type explícito
      final extension = imageFile.path.split('.').last.toLowerCase();
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
        imageFile.path,
        contentType: MediaType('image', mimeType),
      ));

      // Agregar campos adicionales
      request.fields['entityType'] = 'user';
      request.fields['entityId'] = userId;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final fileId = data['id'];

        // Guardar el fileId como referencia, no la URL presignada
        // La URL se obtendrá dinámicamente cuando se necesite mostrar la imagen
        // Formato: file://<fileId> para indicar que es una referencia a archivo
        return 'file://$fileId';
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al subir imagen');
      }
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  @override
  Future<String?> getFileUrl(String fileId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/files/$fileId/url'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfileImage(String userId, String imageUrl) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: _authHeaders,
        body: json.encode({
          'profileImageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromApi(data);
        await prefs.setString(_userDataKey, json.encode(data));
        return user;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar imagen');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Refrescar el access token usando el refresh token
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken == null) {
        return false;
      }

      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _headers,
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await prefs.setString(_accessTokenKey, data['accessToken']);
        await prefs.setString(_refreshTokenKey, data['refreshToken']);
        return true;
      } else {
        // Refresh token inválido, limpiar sesión
        await signOut();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtener access token (útil para otros servicios)
  Future<String?> getAccessToken() async {
    return prefs.getString(_accessTokenKey);
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = prefs.getString(_accessTokenKey);
    return token != null;
  }
}
