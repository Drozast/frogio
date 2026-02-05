// lib/core/services/notification_manager.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'notification_service.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final NotificationService _notificationService = NotificationService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Callback para alertas de pánico (para actualizar UI en tiempo real)
  Function(Map<String, dynamic>)? onPanicAlertReceived;

  Future<void> initialize() async {
    await _notificationService.initialize();
    _setupCallbacks();
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

  OverlayEntry? _activePanicOverlay;

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

    // Mostrar banner superior de alerta que se repite 3 veces
    final context = navigatorKey.currentContext;
    if (context != null) {
      _showRepeatingPanicBanner(context, data);
    }
  }

  /// Muestra un banner de pánico en la parte superior 3 veces con vibración
  void _showRepeatingPanicBanner(BuildContext context, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'ALERTA DE PANICO';
    final message = data['message']?.toString() ?? 'Un ciudadano necesita ayuda';
    final lat = data['latitude'] as double?;
    final lng = data['longitude'] as double?;

    int repeatCount = 0;

    void showBanner() {
      if (repeatCount >= 3) {
        // Después de las 3 repeticiones, mostrar el diálogo de acción
        _showPanicActionDialog(context, data);
        return;
      }
      repeatCount++;

      // Vibración fuerte
      HapticFeedback.heavyImpact();

      // Remover overlay previo si existe
      _activePanicOverlay?.remove();
      _activePanicOverlay = null;

      final overlay = Overlay.of(context);

      _activePanicOverlay = OverlayEntry(
        builder: (overlayContext) => _PanicBannerOverlay(
          title: title,
          message: message,
          repeatNumber: repeatCount,
          onDismiss: () {
            _activePanicOverlay?.remove();
            _activePanicOverlay = null;
          },
          onTap: () {
            _activePanicOverlay?.remove();
            _activePanicOverlay = null;
            _refreshAndNavigateToMap(context, latitude: lat, longitude: lng);
          },
          onAnimationComplete: () {
            // Esperar un poco y mostrar la siguiente repetición
            Future.delayed(const Duration(milliseconds: 500), () {
              if (repeatCount < 3) {
                showBanner();
              } else {
                _activePanicOverlay?.remove();
                _activePanicOverlay = null;
                _showPanicActionDialog(context, data);
              }
            });
          },
        ),
      );

      overlay.insert(_activePanicOverlay!);
    }

    showBanner();
  }

  void _showPanicActionDialog(BuildContext context, Map<String, dynamic> data) {
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final hasLocation = latitude != null && longitude != null;
    final message = data['message']?.toString() ?? 'Un ciudadano necesita ayuda';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ALERTA DE PANICO',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
            if (hasLocation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ubicacion disponible',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _refreshAndNavigateToMap(
                context,
                latitude: latitude is double ? latitude : double.tryParse(latitude?.toString() ?? ''),
                longitude: longitude is double ? longitude : double.tryParse(longitude?.toString() ?? ''),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Ver en Mapa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshAndNavigateToMap(BuildContext context, {double? latitude, double? longitude}) {
    // Navegar al mapa con ubicación del SOS si está disponible
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/inspector-map',
      (route) => route.isFirst,
      arguments: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
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
        final lat = data['latitude'] is double
            ? data['latitude'] as double
            : double.tryParse(data['latitude']?.toString() ?? '');
        final lng = data['longitude'] is double
            ? data['longitude'] as double
            : double.tryParse(data['longitude']?.toString() ?? '');
        Navigator.of(context).pushNamed('/inspector-map', arguments: {
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
        });
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
        _navigateToReportsList(context);
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

  void _navigateToReportsList(BuildContext context) {
    Navigator.of(context).pushNamed('/reports');
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
  Future<void> subscribeToUserTopics(String userId, String role, {String tenantId = 'santa_juana'}) async {
    // Configurar topics para el usuario y conectar a SSE
    await _notificationService.setupUserTopics(
      userId: userId,
      tenantId: tenantId,
      role: role,
    );

    log('Usuario suscrito a notificaciones: $userId (role: $role)');
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

/// Banner superior de alerta de pánico con animación de entrada/salida
class _PanicBannerOverlay extends StatefulWidget {
  final String title;
  final String message;
  final int repeatNumber;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;
  final VoidCallback? onAnimationComplete;

  const _PanicBannerOverlay({
    required this.title,
    required this.message,
    required this.repeatNumber,
    this.onDismiss,
    this.onTap,
    this.onAnimationComplete,
  });

  @override
  State<_PanicBannerOverlay> createState() => _PanicBannerOverlayState();
}

class _PanicBannerOverlayState extends State<_PanicBannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Vibrar al aparecer
    HapticFeedback.heavyImpact();

    // Auto-ocultar después de 3 segundos
    _autoDismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onAnimationComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade900],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono pulsante
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Contenido
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ALERTA SOS [${widget.repeatNumber}/3]',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Flecha para ver mapa
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
