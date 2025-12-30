// lib/core/services/notification_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de notificaciones usando ntfy.sh (sin Firebase)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();

  // Configuracion de ntfy
  static const String _ntfyBaseUrl = 'https://ntfy.sh';
  String? _userTopic;
  String? _tenantTopic;

  // Callback para manejar notificaciones recibidas
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onNotificationTapped;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _loadSavedTopics();
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      log('Notificaciones locales no disponibles en web');
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _loadSavedTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userTopic = prefs.getString('ntfy_user_topic');
      _tenantTopic = prefs.getString('ntfy_tenant_topic');
    } catch (e) {
      log('Error loading saved topics: $e');
    }
  }

  /// Configurar topics para el usuario
  Future<void> setupUserTopics({
    required String userId,
    required String tenantId,
    required String role,
  }) async {
    try {
      // Crear topics unicos para el usuario y tenant
      _userTopic = 'frogio_${tenantId}_user_$userId';
      _tenantTopic = 'frogio_${tenantId}_$role';

      // Guardar topics
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ntfy_user_topic', _userTopic!);
      await prefs.setString('ntfy_tenant_topic', _tenantTopic!);

      log('Topics configurados: user=$_userTopic, tenant=$_tenantTopic');
    } catch (e) {
      log('Error setting up topics: $e');
    }
  }

  /// Enviar notificacion via ntfy
  Future<bool> sendNotification({
    required String topic,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    int priority = 3, // 1-5, 3 es normal
  }) async {
    try {
      final response = await _dio.post(
        '$_ntfyBaseUrl/$topic',
        data: message,
        options: Options(
          headers: {
            'Title': title,
            'Priority': priority.toString(),
            'Tags': 'frogio',
            if (data != null) 'X-Data': jsonEncode(data),
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error sending notification: $e');
      return false;
    }
  }

  /// Suscribirse a un topic y escuchar notificaciones
  Future<void> subscribeToTopic(String topic) async {
    log('Subscribed to topic: $topic');
    // En una implementacion real, usar SSE o WebSocket para escuchar
    // Por ahora, las notificaciones se manejan via polling o push del servidor
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    log('Unsubscribed from topic: $topic');
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        onNotificationTapped?.call(data);
      } catch (e) {
        log('Error parsing notification payload: $e');
      }
    }
  }

  /// Mostrar notificacion local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb) {
      log('Local notifications not supported on web');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'frogio_channel',
      'FROGIO Notifications',
      channelDescription: 'Notificaciones de la app FROGIO',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Limpiar cuando el usuario cierre sesion
  Future<void> clearTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ntfy_user_topic');
      await prefs.remove('ntfy_tenant_topic');
      _userTopic = null;
      _tenantTopic = null;
      log('Topics cleared');
    } catch (e) {
      log('Error clearing topics: $e');
    }
  }

  // Getters
  String? get userTopic => _userTopic;
  String? get tenantTopic => _tenantTopic;
}
