import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/panic_alert_entity.dart';
import 'panic_remote_data_source.dart';

class PanicApiDataSource implements PanicRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  PanicApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  Map<String, String> get _headers {
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'X-Tenant-ID': 'santa_juana',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<PanicAlertEntity> createPanicAlert({
    required double latitude,
    required double longitude,
    String? address,
    String? message,
    String? contactPhone,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/panic'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (message != null) 'message': message,
        if (contactPhone != null) 'contactPhone': contactPhone,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _mapToEntity(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al enviar alerta de pánico');
    }
  }

  @override
  Future<PanicAlertEntity> cancelPanicAlert(String alertId) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/panic/$alertId/cancel'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _mapToEntity(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al cancelar alerta');
    }
  }

  @override
  Future<PanicAlertEntity?> getActiveAlert() async {
    final userId = prefs.getString('user_id');
    if (userId == null) return null;

    final response = await client.get(
      Uri.parse('$baseUrl/api/panic?userId=$userId&status=active'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return null;
      return _mapToEntity(data.first);
    }
    return null;
  }

  PanicAlertEntity _mapToEntity(Map<String, dynamic> data) {
    return PanicAlertEntity(
      id: data['id'],
      userId: data['user_id'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      address: data['address'],
      message: data['message'] ?? 'Alerta de emergencia',
      contactPhone: data['contact_phone'],
      status: data['status'],
      responderId: data['responder_id'],
      respondedAt: data['responded_at'] != null
          ? DateTime.parse(data['responded_at'])
          : null,
      resolvedAt: data['resolved_at'] != null
          ? DateTime.parse(data['resolved_at'])
          : null,
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }
}
