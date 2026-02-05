// lib/core/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Servicio de notificaciones usando ntfy con SSE (Server-Sent Events)
/// No requiere instalar la app ntfy - todo está integrado en la app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // SSE streams para recibir notificaciones en tiempo real
  final Map<String, StreamSubscription> _sseSubscriptions = {};
  http.Client? _sseClient;

  // Topics activos
  String? _userTopic;
  String? _tenantTopic;
  String? _panicTopic;
  String? _userRole;

  // Callbacks para manejar notificaciones recibidas
  Function(Map<String, dynamic>)? onNotificationReceived;
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(Map<String, dynamic>)? onPanicAlertReceived;

  // Estado de conexión
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Timer para reconexión automática
  Timer? _reconnectTimer;

  // Control de backoff exponencial
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _baseReconnectDelay = 5; // segundos

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _loadSavedTopics();
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) {
      log('Notificaciones locales no disponibles en web');
      return;
    }

    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const macOSSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: macOSSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Crear canal de notificaciones para alertas de pánico (alta prioridad)
      await _createNotificationChannels();

      // Solicitar permiso de notificaciones (Android 13+)
      await _requestNotificationPermission();
    } catch (e) {
      // En macOS desktop las notificaciones pueden no estar disponibles
      log('Error initializing local notifications (may be unsupported platform): $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      log('Notification permission granted: $granted');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Canal normal
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'frogio_channel',
          'FROGIO Notifications',
          description: 'Notificaciones generales de la app FROGIO',
          importance: Importance.high,
        ),
      );

      // Canal de emergencia para alertas de pánico
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'frogio_panic_channel',
          'Alertas de Pánico',
          description: 'Alertas de emergencia que requieren atención inmediata',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  Future<void> _loadSavedTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userTopic = prefs.getString('ntfy_user_topic');
      _tenantTopic = prefs.getString('ntfy_tenant_topic');
      _userRole = prefs.getString('user_role');

      // Solo cargar panic topic si el usuario es inspector o admin
      // Los ciudadanos NUNCA deben recibir alertas de pánico
      if (_userRole == 'inspector' || _userRole == 'admin') {
        _panicTopic = prefs.getString('ntfy_panic_topic');
      } else {
        _panicTopic = null;
        // Limpiar el panic topic si existía para ciudadanos
        await prefs.remove('ntfy_panic_topic');
      }
    } catch (e) {
      log('Error loading saved topics: $e');
    }
  }

  /// Configurar topics para el usuario y conectar a SSE
  Future<void> setupUserTopics({
    required String userId,
    required String tenantId,
    required String role,
  }) async {
    try {
      // Crear topics únicos para el usuario y tenant
      _userTopic = 'frogio_${tenantId}_user_$userId';
      _tenantTopic = 'frogio_${tenantId}_$role';
      _userRole = role;

      // Guardar topics
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ntfy_user_topic', _userTopic!);
      await prefs.setString('ntfy_tenant_topic', _tenantTopic!);
      await prefs.setString('user_role', role);

      // Solo inspectores y admins reciben alertas de pánico
      // Los ciudadanos NUNCA deben suscribirse a este topic
      if (role == 'inspector' || role == 'admin') {
        _panicTopic = 'frogio-panic';
        await prefs.setString('ntfy_panic_topic', _panicTopic!);
        log('Topics configurados: user=$_userTopic, tenant=$_tenantTopic, panic=$_panicTopic');
      } else {
        _panicTopic = null;
        await prefs.remove('ntfy_panic_topic');
        log('Topics configurados (sin pánico): user=$_userTopic, tenant=$_tenantTopic');
      }

      // Conectar a SSE para recibir notificaciones en tiempo real
      await connectToSSE(resetAttempts: true);
    } catch (e) {
      log('Error setting up topics: $e');
    }
  }

  /// Conectar a ntfy via SSE para recibir notificaciones en tiempo real
  Future<void> connectToSSE({bool resetAttempts = false}) async {
    if (kIsWeb) {
      log('SSE not available on web');
      return;
    }

    // Resetear contador si se solicita (ej: reconexión manual)
    if (resetAttempts) {
      _reconnectAttempts = 0;
    }

    // Desconectar primero si ya hay conexiones
    await disconnectSSE();

    _sseClient = http.Client();

    // Determinar topics a suscribir
    final topicsToSubscribe = <String>[];

    if (_userTopic != null) topicsToSubscribe.add(_userTopic!);
    if (_tenantTopic != null) topicsToSubscribe.add(_tenantTopic!);

    // Solo inspectores y admins reciben alertas de pánico
    if (_userRole == 'inspector' || _userRole == 'admin') {
      if (_panicTopic != null) topicsToSubscribe.add(_panicTopic!);
    }

    for (final topic in topicsToSubscribe) {
      await _subscribeToTopicSSE(topic);
    }

    _isConnected = true;
    log('Conectado a SSE para ${topicsToSubscribe.length} topics');
  }

  Future<void> _subscribeToTopicSSE(String topic) async {
    try {
      final ntfyUrl = ApiConfig.activeNtfyUrl;
      final uri = Uri.parse('$ntfyUrl/$topic/sse');

      log('Subscribing to SSE: $uri');

      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';

      final response = await _sseClient!.send(request).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout for $topic');
        },
      );

      if (response.statusCode == 200) {
        final subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) => _handleSSELine(line, topic),
              onError: (error) {
                log('SSE error for $topic: $error');
                _scheduleReconnect();
              },
              onDone: () {
                log('SSE connection closed for $topic');
                _scheduleReconnect();
              },
              cancelOnError: false,
            );

        _sseSubscriptions[topic] = subscription;
        _reconnectAttempts = 0; // Reset counter on success
        log('SSE subscription active for topic: $topic');
      } else {
        log('Failed to subscribe to $topic: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || e is TimeoutException) {
        log('Cannot reach ntfy server for $topic: $e');
      } else {
        log('Error subscribing to $topic: $e');
      }
      _scheduleReconnect();
    }
  }

  void _handleSSELine(String line, String topic) {
    if (line.isEmpty || line.startsWith(':')) return; // Ignorar comentarios y líneas vacías

    if (line.startsWith('data:')) {
      final jsonStr = line.substring(5).trim();
      if (jsonStr.isEmpty) return;

      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        _handleNotification(data, topic);
      } catch (e) {
        log('Error parsing SSE data: $e');
      }
    }
  }

  void _handleNotification(Map<String, dynamic> data, String topic) {
    log('Notification received from $topic: $data');

    var title = data['title']?.toString() ?? '';
    var message = data['message']?.toString() ?? '';
    final priority = data['priority'] ?? 3;
    final clickUrl = data['click'] ?? '';

    // Fallback: if message is raw JSON (ntfy didn't parse the body), extract title/message
    if (message.startsWith('{') && message.endsWith('}')) {
      try {
        final parsed = jsonDecode(message) as Map<String, dynamic>;
        if (parsed.containsKey('message') || parsed.containsKey('title')) {
          title = parsed['title']?.toString() ?? title;
          message = parsed['message']?.toString() ?? message;
        }
      } catch (_) {
        // Not valid JSON, use as-is
      }
    }

    // Ignorar notificaciones vacías o eventos keepalive de ntfy
    // ntfy envía eventos con event: "open" o sin mensaje real
    final eventType = data['event']?.toString() ?? '';
    if (eventType == 'open' || eventType == 'keepalive') {
      log('Ignoring SSE event: $eventType');
      return;
    }

    // Ignorar si no hay título ni mensaje
    if (title.isEmpty && message.isEmpty) {
      log('Ignoring empty notification');
      return;
    }

    // Extraer datos adicionales si existen
    Map<String, dynamic>? extraData;
    if (data['extras'] != null && data['extras']['data'] != null) {
      try {
        extraData = jsonDecode(data['extras']['data']) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Intentar extraer coordenadas del click URL (formato: https://maps.google.com/?q=lat,lng)
    double? latitude;
    double? longitude;
    if (clickUrl.contains('maps.google.com')) {
      final match = RegExp(r'q=(-?[\d.]+),(-?[\d.]+)').firstMatch(clickUrl);
      if (match != null) {
        latitude = double.tryParse(match.group(1) ?? '');
        longitude = double.tryParse(match.group(2) ?? '');
      }
    }

    // Verificar si es una alerta de pánico
    final tags = data['tags'];
    final isPanicAlert = topic == _panicTopic ||
                        (tags != null && tags is List && tags.contains('sos'));

    if (isPanicAlert) {
      // Ignorar alertas de pánico vacías o sin mensaje válido
      if (message.isEmpty && (title.isEmpty || title == 'FROGIO')) {
        log('Ignoring empty panic alert from SSE');
        return;
      }

      final panicData = {
        'type': 'panic',
        'title': title,
        'message': message,
        'topic': topic,
        'latitude': latitude,
        'longitude': longitude,
        'click': clickUrl,
        ...?extraData,
      };

      // Mostrar notificación de pánico con máxima prioridad
      _showPanicNotification(title, message, panicData);
      onPanicAlertReceived?.call(panicData);
    } else {
      // Check if it's a panic response notification (citizen gets notified inspector is on the way)
      Map<String, dynamic>? notifData = extraData;
      if (clickUrl.startsWith('frogio://panic_response')) {
        try {
          final uri = Uri.parse(clickUrl);
          notifData = {
            'type': 'panic_response',
            'alertId': uri.queryParameters['alertId'],
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            ...?extraData,
          };
        } catch (_) {}
      }

      // Notificación normal
      showLocalNotification(
        title: title,
        body: message,
        data: notifData,
        highPriority: priority >= 4,
      );
    }

    // Callback general
    onNotificationReceived?.call({
      'title': title,
      'body': message,
      'topic': topic,
      'type': isPanicAlert ? 'panic' : 'general',
      'latitude': latitude,
      'longitude': longitude,
      ...?extraData,
    });
  }

  /// Muestra notificación de pánico 3 veces con intervalos para máxima atención
  Future<void> _showPanicNotification(String title, String message, Map<String, dynamic>? data) async {
    if (kIsWeb) return;

    try {
      final androidDetails = AndroidNotificationDetails(
      'frogio_panic_channel',
      'Alertas de Pánico',
      channelDescription: 'Alertas de emergencia',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 500]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails, // Same as iOS for Darwin platforms
    );

    final payload = data != null ? jsonEncode(data) : null;
    final baseId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Repetir 3 veces con 2 segundos de intervalo para máxima atención
    for (int i = 0; i < 3; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }
      await _localNotifications.show(
        baseId + i,
        '🚨 $title',
        i == 0 ? message : '[${i + 1}/3] $message',
        notificationDetails,
        payload: payload,
      );
    }
    } catch (e) {
      log('Error showing panic notification: $e');
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;

    // Verificar límite de reintentos
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('Max reconnection attempts reached ($_maxReconnectAttempts). Stopping reconnection.');
      return;
    }

    _reconnectAttempts++;

    // Calcular delay con backoff exponencial: 5, 10, 20, 40, 80... hasta max 300 segundos (5 min)
    final delay = (_baseReconnectDelay * (1 << (_reconnectAttempts - 1))).clamp(5, 300);

    log('Scheduling reconnection attempt $_reconnectAttempts/$_maxReconnectAttempts in $delay seconds...');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      log('Attempting to reconnect to SSE (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
      connectToSSE();
    });
  }

  Future<void> disconnectSSE() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0; // Reset counter

    for (final subscription in _sseSubscriptions.values) {
      await subscription.cancel();
    }
    _sseSubscriptions.clear();

    _sseClient?.close();
    _sseClient = null;

    _isConnected = false;
    log('Disconnected from SSE');
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

  /// Mostrar notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool highPriority = false,
  }) async {
    if (kIsWeb) {
      log('Local notifications not supported on web');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'frogio_channel',
        'FROGIO Notifications',
        channelDescription: 'Notificaciones de la app FROGIO',
        importance: highPriority ? Importance.max : Importance.high,
        priority: highPriority ? Priority.max : Priority.high,
        icon: '@drawable/ic_notification',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      log('Error showing local notification: $e');
    }
  }

  /// Limpiar cuando el usuario cierre sesión
  Future<void> clearTopics() async {
    try {
      await disconnectSSE();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ntfy_user_topic');
      await prefs.remove('ntfy_tenant_topic');
      await prefs.remove('ntfy_panic_topic');
      await prefs.remove('user_role');

      _userTopic = null;
      _tenantTopic = null;
      _panicTopic = null;
      _userRole = null;

      log('Topics cleared');
    } catch (e) {
      log('Error clearing topics: $e');
    }
  }

  // Getters
  String? get userTopic => _userTopic;
  String? get tenantTopic => _tenantTopic;
  String? get panicTopic => _panicTopic;
}
