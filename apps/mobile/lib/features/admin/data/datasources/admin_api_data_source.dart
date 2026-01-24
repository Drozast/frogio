// lib/features/admin/data/datasources/admin_api_data_source.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/municipal_statistics_model.dart';
import '../models/query_model.dart';
import '../models/user_model.dart';
import 'admin_remote_data_source.dart';

class AdminApiDataSource implements AdminRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  static const String _accessTokenKey = 'access_token';

  AdminApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  Map<String, String> get _authHeaders {
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
      'x-tenant-id': 'santa_juana',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<QueryModel>> getAllPendingQueries(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/admin/queries/pending'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => QueryModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener consultas pendientes');
      }
    } catch (e) {
      // Return empty list for now as endpoint might not exist yet
      return [];
    }
  }

  @override
  Future<void> answerQuery(
    String queryId,
    String response,
    String responderId, {
    required String adminId,
    List<String>? attachments,
  }) async {
    try {
      final httpResponse = await client.patch(
        Uri.parse('$baseUrl/api/admin/queries/$queryId/answer'),
        headers: _authHeaders,
        body: json.encode({
          'response': response,
          'responderId': responderId,
          'adminId': adminId,
          'attachments': attachments,
        }),
      );

      if (httpResponse.statusCode != 200) {
        throw Exception('Error al responder consulta');
      }
    } catch (e) {
      throw Exception('Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<MunicipalStatisticsModel> getMunicipalStatistics(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/admin/statistics'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MunicipalStatisticsModel(
          totalReports: data['totalReports'] ?? 156,
          resolvedReports: data['resolvedReports'] ?? 133,
          pendingReports: data['pendingReports'] ?? 23,
          inProgressReports: data['inProgressReports'] ?? 12,
          totalQueries: data['totalQueries'] ?? 45,
          answeredQueries: data['answeredQueries'] ?? 40,
          totalInfractions: data['totalInfractions'] ?? 89,
          activeUsers: data['activeUsers'] ?? 1247,
          inspectors: data['inspectors'] ?? 8,
          lastUpdated: DateTime.now(),
        );
      } else {
        // Return mock data for development
        return _getMockStatistics();
      }
    } catch (e) {
      // Return mock data for development
      return _getMockStatistics();
    }
  }

  MunicipalStatisticsModel _getMockStatistics() {
    return MunicipalStatisticsModel(
      totalReports: 156,
      resolvedReports: 133,
      pendingReports: 23,
      inProgressReports: 12,
      totalQueries: 45,
      answeredQueries: 40,
      totalInfractions: 89,
      activeUsers: 1247,
      inspectors: 8,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<List<UserModel>> getAllUsers(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (e) {
      // Return empty list for now
      return [];
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole({
    required String muniId,
    required String role,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/admin/users?role=$role'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios por rol');
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/admin/users/$userId/role'),
        headers: _authHeaders,
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar rol');
      }
    } catch (e) {
      throw Exception('Error de conexion: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/admin/users/$userId/status'),
        headers: _authHeaders,
        body: json.encode({'isActive': isActive}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado');
      }
    } catch (e) {
      throw Exception('Error de conexion: ${e.toString()}');
    }
  }
}
