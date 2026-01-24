// lib/core/widgets/notification_widget.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NotificationWidget extends StatelessWidget {
  final List<AppNotification> notifications;
  final Function(AppNotification)? onNotificationTap;
  final Function(AppNotification)? onNotificationDismiss;

  const NotificationWidget({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationItem(notifications[index]);
      },
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onNotificationDismiss?.call(notification),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: notification.isRead ? 1 : 3,
        child: ListTile(
          leading: _buildNotificationIcon(notification),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead 
                  ? FontWeight.normal 
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: notification.isRead 
              ? null 
              : Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => onNotificationTap?.call(notification),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.reportStatusChanged:
        icon = Icons.update;
        color = Colors.blue;
        break;
      case NotificationType.reportResponse:
        icon = Icons.reply;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.reportAssigned:
        icon = Icons.person_add;
        color = Colors.purple;
        break;
      case NotificationType.newReport:
        icon = Icons.report;
        color = Colors.orange;
        break;
      case NotificationType.reminder:
        icon = Icons.schedule;
        color = Colors.amber;
        break;
      case NotificationType.panicAlert:
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case NotificationType.newCitizenReport:
        icon = Icons.report_problem;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'ahora';
    }
  }
}

class InAppNotificationOverlay extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const InAppNotificationOverlay({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<InAppNotificationOverlay> createState() => _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismiss();
            },
            child: Card(
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.notifications,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.notification.body,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _dismiss,
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

// Modelos de notificación
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum NotificationType {
  reportStatusChanged,
  reportResponse,
  reportAssigned,
  newReport,
  reminder,
  general,
  panicAlert,
  newCitizenReport,
}