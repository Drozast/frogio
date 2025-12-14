// lib/core/services/notification_service.dart
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callback para manejar notificaciones recibidas
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onNotificationTapped;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
    await _requestPermissions();
    await _getFCMToken();
    _setupMessageHandlers();
  }

  Future<void> _initializeLocalNotifications() async {
    // Solo inicializar notificaciones locales en plataformas móviles
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

  Future<void> _initializeFirebaseMessaging() async {
    // Configurar opciones para iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _requestPermissions() async {
    try {
      // En web, no necesitamos permisos de Platform
      if (!kIsWeb) {
        // Solo usar Permission.notification en plataformas móviles
        await Permission.notification.request();
      }
      
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      log('Error requesting permissions: $e');
    }
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      log('FCM Token: $_fcmToken');
    } catch (e) {
      log('Error getting FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Mensaje tocado cuando la app está en segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
    
    // Verificar si hay mensaje que abrió la app
    _checkInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log('Foreground message received: ${message.notification?.title}');
    
    final data = message.data;
    onNotificationReceived?.call(data);
    
    // Mostrar notificación local en primer plano solo en plataformas móviles
    if (!kIsWeb) {
      await _showLocalNotification(message);
    }
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    log('Background message tapped: ${message.notification?.title}');
    onNotificationTapped?.call(message.data);
  }

  Future<void> _checkInitialMessage() async {
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      log('App opened from terminated state via notification');
      onNotificationTapped?.call(initialMessage.data);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Parsear payload como JSON si es necesario
      log('Local notification tapped: $payload');
      // onNotificationTapped?.call(jsonDecode(payload));
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Solo funciona en plataformas móviles
    if (kIsWeb) return;

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
      message.hashCode,
      message.notification?.title ?? 'FROGIO',
      message.notification?.body ?? 'Nueva notificación',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  // Suscribirse a tópicos
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  // Enviar token al servidor
  Future<void> sendTokenToServer(String userId, String userRole) async {
    if (_fcmToken == null) return;
    
    try {
      // En implementación real, enviar al backend
      log('Sending token to server for user $userId with role $userRole');
      
      // Ejemplo de estructura de datos:
      
      // await apiService.saveUserToken(tokenData);
      
    } catch (e) {
      log('Error sending token to server: $e');
    }
  }

  // Limpiar token cuando el usuario cierre sesión
  Future<void> clearToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      log('FCM token cleared');
    } catch (e) {
      log('Error clearing token: $e');
    }
  }

  // Mostrar notificación local personalizada
  Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? icon,
  }) async {
    // Solo funciona en plataformas móviles
    if (kIsWeb) {
      log('Custom notifications not supported on web');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'frogio_custom',
      'FROGIO Custom',
      channelDescription: 'Notificaciones personalizadas de FROGIO',
      importance: Importance.high,
      priority: Priority.high,
      icon: icon ?? '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();
    
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: data?.toString(),
    );
  }
}

// Handler para mensajes en background (debe estar en nivel global)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background message received: ${message.notification?.title}');
  // No hacer operaciones pesadas aquí
}