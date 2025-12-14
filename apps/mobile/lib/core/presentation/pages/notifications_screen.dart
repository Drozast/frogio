// lib/core/presentation/pages/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/notification/notification_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/notification_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all),
                          SizedBox(width: 8),
                          Text('Marcar todas como leídas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('Limpiar todas'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotificationsEvent());
              },
              child: NotificationWidget(
                notifications: state.notifications,
                onNotificationTap: _onNotificationTap,
                onNotificationDismiss: _onNotificationDismiss,
              ),
            );
          } else if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotificationBloc>().add(LoadNotificationsEvent());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onNotificationTap(AppNotification notification) {
    // Marcar como leída
    context.read<NotificationBloc>().add(MarkAsReadEvent(notification.id));
    
    // Navegar según el tipo
    _navigateBasedOnNotification(notification);
  }

  void _onNotificationDismiss(AppNotification notification) {
    context.read<NotificationBloc>().add(DismissNotificationEvent(notification.id));
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
    }
  }

  void _markAllAsRead() {
    final state = context.read<NotificationBloc>().state;
    if (state is NotificationLoaded) {
      for (final notification in state.notifications) {
        if (!notification.isRead) {
          context.read<NotificationBloc>().add(MarkAsReadEvent(notification.id));
        }
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: const Text('¿Estás seguro de que quieres eliminar todas las notificaciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(ClearAllNotificationsEvent());
            },
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );
  }

  void _navigateBasedOnNotification(AppNotification notification) {
    final data = notification.data;
    
    switch (notification.type) {
      case NotificationType.reportStatusChanged:
      case NotificationType.reportResponse:
        final reportId = data['reportId'];
        if (reportId != null) {
          Navigator.pushNamed(context, '/report-detail', arguments: reportId);
        }
        break;
      case NotificationType.newReport:
        Navigator.pushNamed(context, '/reports');
        break;
      case NotificationType.reminder:
        final reminderType = data['reminderType'];
        if (reminderType == 'incomplete_profile') {
          Navigator.pushNamed(context, '/profile');
        }
        break;
      default:
        break;
    }
  }
}