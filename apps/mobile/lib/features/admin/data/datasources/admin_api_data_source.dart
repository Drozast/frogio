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
        Uri.parse('$baseUrl/api/dashboard/stats'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse the dashboard stats response
        final summary = data['summary'] ?? {};
        final reportsByStatus = data['reportsByStatus'] ?? {};

        // Calculate pending and resolved reports from status breakdown
        final pendingReports = (reportsByStatus['pending'] ?? 0) as int;
        final inProgressReports = (reportsByStatus['in_progress'] ?? 0) as int;
        final resolvedReports = (reportsByStatus['resolved'] ?? 0) as int;

        return MunicipalStatisticsModel(
          totalReports: summary['totalReports'] ?? 0,
          resolvedReports: resolvedReports,
          pendingReports: pendingReports,
          inProgressReports: inProgressReports,
          totalQueries: 0, // Not available in this endpoint
          answeredQueries: 0, // Not available in this endpoint
          totalInfractions: summary['totalInfractions'] ?? 0,
          activeUsers: summary['totalUsers'] ?? 0,
          inspectors: data['inspectorsCount'] ?? 0,
          lastUpdated: DateTime.now(),
          totalVehicles: summary['totalVehicles'] ?? 0,
          activeTrips: data['bitacora']?['activeTrips'] ?? 0,
          totalKmToday: (data['bitacora']?['totalKmToday'] ?? 0).toDouble(),
          citizensCount: data['citizensCount'] ?? 0,
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
      totalReports: 0,
      resolvedReports: 0,
      pendingReports: 0,
      inProgressReports: 0,
      totalQueries: 0,
      answeredQueries: 0,
      totalInfractions: 0,
      activeUsers: 0,
      inspectors: 0,
      lastUpdated: DateTime.now(),
      totalVehicles: 0,
      activeTrips: 0,
      totalKmToday: 0.0,
      citizensCount: 0,
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
