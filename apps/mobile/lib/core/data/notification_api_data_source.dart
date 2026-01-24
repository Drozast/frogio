// lib/core/data/notification_api_data_source.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../widgets/notification_widget.dart';

class NotificationApiDataSource {
  final http.Client client; // This should be AuthHttpClient for auto token refresh
  final String baseUrl;

  NotificationApiDataSource({
    required this.client,
    required this.baseUrl,
  });

  Future<List<AppNotification>> getNotifications({int limit = 50}) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/notifications?limit=$limit'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => _mapToNotification(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Token inválido o expirado');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al obtener notificaciones');
    }
  }

  Future<int> getUnreadCount() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/notifications/unread/count'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] as int? ?? 0;
    }
    return 0;
  }

  Future<void> markAsRead(String notificationId) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al marcar como leída');
    }
  }

  Future<void> markAllAsRead() async {
    final response = await client.patch(
      Uri.parse('$baseUrl/api/notifications/read-all'),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al marcar todas como leídas');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/notifications/$notificationId'),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error al eliminar notificación');
    }
  }

  AppNotification _mapToNotification(Map<String, dynamic> data) {
    return AppNotification(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? 'Notificación',
      body: data['message'] ?? '',
      type: _parseType(data['type']),
      data: data['metadata'] != null
          ? (data['metadata'] is String
              ? jsonDecode(data['metadata'])
              : Map<String, dynamic>.from(data['metadata']))
          : {},
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      isRead: data['read_at'] != null,
    );
  }

  NotificationType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'report_status':
      case 'status_changed':
        return NotificationType.reportStatusChanged;
      case 'response':
      case 'report_response':
        return NotificationType.reportResponse;
      case 'assigned':
      case 'report_assigned':
        return NotificationType.reportAssigned;
      case 'new_report':
        return NotificationType.newReport;
      case 'reminder':
        return NotificationType.reminder;
      case 'panic_alert':
      case 'panic':
        return NotificationType.panicAlert;
      case 'new_citizen_report':
      case 'citizen_report':
        return NotificationType.newCitizenReport;
      case 'urgent':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }
}
