// lib/features/auth/data/datasources/auth_api_data_source.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<UserModel> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Dividir el nombre en nombres y apellidos (simplificado)
      final nameParts = name.split(' ');
      final firstName = nameParts.first;
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final response = await client.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'rut': '', // RUT será solicitado en pantalla de registro
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

      // Obtener datos actualizados del usuario
      final response = await client.get(
        Uri.parse('$baseUrl/api/auth/me'),
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
    // TODO: Implementar endpoint de recuperación de contraseña en backend
    throw UnimplementedError('Recuperación de contraseña no implementada aún');
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? address,
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
      if (phoneNumber != null) updateData['phone'] = phoneNumber;
      if (address != null) updateData['address'] = address;

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
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await client.post(
        Uri.parse('$baseUrl/api/files/upload'),
        headers: _authHeaders,
        body: json.encode({
          'file': base64Image,
          'fileName': imageFile.path.split('/').last,
          'entityType': 'user',
          'entityId': userId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id']; // Retorna el ID del archivo
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al subir imagen');
      }
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
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
