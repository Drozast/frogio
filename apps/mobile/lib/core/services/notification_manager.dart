// lib/core/services/notification_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../network/auth_http_client.dart';
import '../theme/app_theme.dart';
import '../../features/panic/presentation/pages/panic_alert_detail_screen.dart';
import '../../di/injection_container_api.dart' as di;
import 'notification_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Callback para alertas de pánico (para actualizar UI en tiempo real)
  Function(Map<String, dynamic>)? onPanicAlertReceived;

  Timer? _panicPollTimer;
  String? _lastSeenPanicId;

  Future<void> initialize() async {
    await _notificationService.initialize();
    _setupCallbacks();
    // Start panic polling if already logged in as inspector
    startPanicPolling();
  }

  /// Start polling for active panic alerts (backup for SSE failures on iOS)
  void startPanicPolling() {
    _panicPollTimer?.cancel();

    _panicPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        if (!di.sl.isRegistered<AuthHttpClient>()) return;
        // Only poll if user is inspector or admin
        final prefs = await SharedPreferences.getInstance();
        final role = prefs.getString('user_role');
        if (role != 'inspector' && role != 'admin') return;
        final client = di.sl<AuthHttpClient>();
        final response = await client.get(
          Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/active'),
        );
        if (response.statusCode == 200) {
          final List<dynamic> alerts = json.decode(response.body);
          if (alerts.isNotEmpty) {
            final latest = alerts.first as Map<String, dynamic>;
            final alertId = latest['id']?.toString();
            if (alertId != null && alertId != _lastSeenPanicId) {
              _lastSeenPanicId = alertId;
              final userName = [latest['first_name'], latest['last_name']]
                  .where((s) => s != null && s.toString().isNotEmpty)
                  .join(' ');
              final message = '$userName necesita ayuda!\n${latest['message'] ?? 'Emergencia'}';

              // Trigger the same flow as SSE
              _handlePanicAlertReceived({
                'type': 'panic',
                'title': 'ALERTA DE PANICO',
                'message': message,
                'alertId': alertId,
                'latitude': (latest['latitude'] as num?)?.toDouble(),
                'longitude': (latest['longitude'] as num?)?.toDouble(),
              });

              // Show panic notification (high priority, sound, vibration)
              await _notificationService.showPanicNotificationDirect(
                'ALERTA DE PANICO',
                message,
                {'type': 'panic', 'alertId': alertId},
              );
            }
          }
        }
      } catch (e) {
        log('Panic poll error: $e');
      }
    });
  }

  void stopPanicPolling() {
    _panicPollTimer?.cancel();
    _panicPollTimer = null;
  }

  void _setupCallbacks() {
    _notificationService.onNotificationReceived = _handleNotificationReceived;
    _notificationService.onNotificationTapped = _handleNotificationTapped;
    _notificationService.onPanicAlertReceived = _handlePanicAlertReceived;
  }

  void _handleNotificationReceived(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      _showInAppNotification(context, data);
    }
  }

  void _handleNotificationTapped(Map<String, dynamic> data) {
    log('Notification tapped: $data');
    _navigateBasedOnNotification(data);
  }

  void _handlePanicAlertReceived(Map<String, dynamic> data) {
    log('PANIC ALERT RECEIVED: $data');

    // Validar que la alerta tenga datos válidos
    final message = data['message']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';

    // No mostrar diálogo si no hay mensaje o es un mensaje vacío/de prueba
    if (message.isEmpty && title.isEmpty) {
      log('Ignoring empty panic alert');
      return;
    }

    // Notificar a cualquier listener (ej: InspectorMapScreen)
    onPanicAlertReceived?.call(data);

    // Vibración fuerte repetida
    _vibrateEmergency();

    // Navegar directamente a la pantalla de detalle SOS (más confiable que overlay)
    final context = navigatorKey.currentContext;
    if (context != null) {
      _navigateToPanicDetail(context, data);
    }
  }

  Future<void> _vibrateEmergency() async {
    // Play alarm sound
    try {
      final player = AudioPlayer();
      await player.setVolume(1.0);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/emergency_alarm.wav'));
      // Stop after 15 seconds
      Future.delayed(const Duration(seconds: 15), () => player.stop());
    } catch (e) {
      log('Error playing alarm sound: $e');
    }

    // Strong vibration: 3s on + 0.5s off x5
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 15; j++) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _navigateToPanicDetail(BuildContext context, Map<String, dynamic> data) {
    final lat = data['latitude'] is double
        ? data['latitude'] as double
        : double.tryParse(data['latitude']?.toString() ?? '');
    final lng = data['longitude'] is double
        ? data['longitude'] as double
        : double.tryParse(data['longitude']?.toString() ?? '');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PanicAlertDetailScreen(
          alertId: data['alertId']?.toString(),
          latitude: lat,
          longitude: lng,
          message: data['message']?.toString(),
        ),
      ),
    );
  }


  void _showInAppNotification(BuildContext context, Map<String, dynamic> data) {
    final notificationType = data['type'] ?? 'general';
    final title = data['title'] ?? 'FROGIO';
    final body = data['body'] ?? 'Nueva notificacion';

    // No mostrar snackbar para alertas de pánico (ya se muestra el diálogo)
    if (notificationType == 'panic') return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getNotificationIcon(notificationType),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getNotificationColor(notificationType),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => _navigateBasedOnNotification(data),
        ),
      ),
    );
  }

  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'];
    final reportId = data['reportId'];
    final screen = data['screen'];
    final alertId = data['alertId'];

    switch (type) {
      case 'panic':
        _navigateToPanicDetail(context, data);
        break;
      case 'panic_response':
        Navigator.of(context).pushNamed('/sos-tracking', arguments: {
          if (alertId != null) 'alertId': alertId,
        });
        break;
      case 'report_status_changed':
        _navigateToReportDetail(context, reportId);
        break;
      case 'report_response':
        _navigateToReportDetail(context, reportId);
        break;
      case 'report_assigned':
        _navigateToReportDetail(context, reportId);
        break;
      case 'new_report':
        // Para inspectores: navegar al mapa con la ubicación del reporte
        final reportLat = data['latitude'] is double
            ? data['latitude'] as double
            : double.tryParse(data['latitude']?.toString() ?? '');
        final reportLng = data['longitude'] is double
            ? data['longitude'] as double
            : double.tryParse(data['longitude']?.toString() ?? '');
        Navigator.of(context).pushNamed('/inspector-map', arguments: {
          if (reportLat != null) 'latitude': reportLat,
          if (reportLng != null) 'longitude': reportLng,
          'reportId': data['reportId'],
        });
        break;
      case 'reminder':
        _handleReminder(context, data);
        break;
      default:
        if (alertId != null) {
          Navigator.of(context).pushNamed('/inspector-map');
        } else if (screen != null) {
          _navigateToScreen(context, screen);
        }
    }
  }

  void _navigateToReportDetail(BuildContext context, String? reportId) {
    if (reportId != null) {
      Navigator.of(context).pushNamed('/report-detail', arguments: reportId);
    }
  }

  void _navigateToScreen(BuildContext context, String screen) {
    Navigator.of(context).pushNamed(screen);
  }

  void _handleReminder(BuildContext context, Map<String, dynamic> data) {
    final reminderType = data['reminderType'];

    switch (reminderType) {
      case 'incomplete_profile':
        Navigator.of(context).pushNamed('/profile');
        break;
      case 'pending_reports':
        Navigator.of(context).pushNamed('/reports');
        break;
      default:
        Navigator.of(context).pushNamed('/dashboard');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'panic':
        return Icons.warning;
      case 'report_status_changed':
        return Icons.update;
      case 'report_response':
        return Icons.reply;
      case 'report_assigned':
        return Icons.person_add;
      case 'new_report':
        return Icons.report;
      case 'reminder':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'panic':
        return Colors.red;
      case 'report_status_changed':
        return Colors.blue;
      case 'report_response':
        return AppTheme.primaryColor;
      case 'report_assigned':
        return Colors.purple;
      case 'new_report':
        return Colors.orange;
      case 'reminder':
        return Colors.amber;
      default:
        return AppTheme.primaryColor;
    }
  }

  // Métodos para suscripciones basadas en roles
  Future<void> subscribeToUserTopics(String userId, String role, {String? tenantId}) async {
    final effectiveTenantId = tenantId ?? ApiConfig.tenantId;
    // Configurar topics para el usuario y conectar a SSE
    await _notificationService.setupUserTopics(
      userId: userId,
      tenantId: effectiveTenantId,
      role: role,
    );

    log('Usuario suscrito a notificaciones: $userId (role: $role)');

    // Register APNs/FCM device token for push notifications
    _registerDeviceToken();

    // Start panic polling as backup (SSE can fail on iOS)
    startPanicPolling();
  }

  static const _apnsChannel = MethodChannel('com.frogio.apns');

  Future<void> _registerDeviceToken() async {
    try {
      if (Platform.isIOS) {
        // Get APNs token via native method channel (more reliable than firebase_messaging)
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          try {
            apnsToken = await _apnsChannel.invokeMethod<String>('getAPNsToken');
          } catch (_) {}
          if (apnsToken != null) break;
          debugPrint('FROGIO: APNs token not ready, retry ${i + 1}/10...');
          await Future.delayed(const Duration(seconds: 2));
        }

        if (apnsToken != null) {
          await _sendTokenToServer(apnsToken, 'ios');
          debugPrint('FROGIO: APNs token registered: ${apnsToken.substring(0, 16)}...');
        } else {
          debugPrint('FROGIO: Could not get APNs token after retries');
        }
      } else {
        // Android: use FCM
        final messaging = FirebaseMessaging.instance;
        final fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          await _sendTokenToServer(fcmToken, 'android');
          debugPrint('FROGIO: FCM token registered');
        }
      }
    } catch (e) {
      debugPrint('FROGIO: Error registering device token: $e');
    }
  }

  Future<void> _sendTokenToServer(String token, String platform) async {
    try {
      if (!di.sl.isRegistered<AuthHttpClient>()) return;
      final client = di.sl<AuthHttpClient>();
      await client.post(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/auth/device-token'),
        body: json.encode({'deviceToken': token, 'platform': platform}),
      );
    } catch (e) {
      log('Error sending token to server: $e');
    }
  }

  Future<void> unsubscribeFromAllTopics() async {
    await _notificationService.clearTopics();
  }

  // Reconectar a notificaciones (útil cuando la app vuelve al foreground)
  Future<void> reconnect() async {
    await _notificationService.connectToSSE();
  }

  // Desconectar (útil cuando la app va a background)
  Future<void> disconnect() async {
    await _notificationService.disconnectSSE();
  }

  // Estado de conexión
  bool get isConnected => _notificationService.isConnected;

  // Mostrar notificaciones locales para acciones de la app
  Future<void> showReportStatusUpdate(String reportId, String newStatus) async {
    await _notificationService.showLocalNotification(
      title: 'Estado actualizado',
      body: 'Tu denuncia cambió a: $newStatus',
      data: {
        'type': 'report_status_changed',
        'reportId': reportId,
      },
    );
  }

  Future<void> showNewResponse(String reportId, String responderName) async {
    await _notificationService.showLocalNotification(
      title: 'Nueva respuesta',
      body: '$responderName respondió a tu denuncia',
      data: {
        'type': 'report_response',
        'reportId': reportId,
      },
    );
  }

  Future<void> showReportAssigned(String reportId, String inspectorName) async {
    await _notificationService.showLocalNotification(
      title: 'Reporte asignado',
      body: 'Asignado a $inspectorName',
      data: {
        'type': 'report_assigned',
        'reportId': reportId,
      },
    );
  }

  Future<void> showReminder(String title, String message, String type) async {
    await _notificationService.showLocalNotification(
      title: title,
      body: message,
      data: {
        'type': 'reminder',
        'reminderType': type,
      },
    );
  }

  Future<void> showPanicAlert(String userName, String? address, double? lat, double? lng) async {
    await _notificationService.showLocalNotification(
      title: '🚨 ALERTA DE PÁNICO',
      body: '$userName necesita ayuda!\n${address ?? 'Ubicación: $lat, $lng'}',
      data: {
        'type': 'panic',
        'latitude': lat,
        'longitude': lng,
      },
      highPriority: true,
    );
  }
}
