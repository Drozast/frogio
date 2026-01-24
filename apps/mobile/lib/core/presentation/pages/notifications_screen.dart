// lib/core/presentation/pages/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _autoMarkedThisOpen = false;
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotificationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllAsReadEvent());
                  },
                  icon: const Icon(Icons.done_all, color: Colors.white, size: 20),
                  label: const Text(
                    'Marcar todas',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<NotificationBloc, NotificationState>(
        listener: (context, state) {
          // UX: al abrir la pantalla, considerar "revisadas" las notificaciones visibles
          if (state is NotificationLoaded && !_autoMarkedThisOpen) {
            if (state.unreadCount > 0) {
              _autoMarkedThisOpen = true;
              context.read<NotificationBloc>().add(MarkAllAsReadEvent());
            }
          }
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.emergency.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<NotificationBloc>().add(LoadNotificationsEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(LoadNotificationsEvent());
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationCard(notification);
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin notificaciones',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las notificaciones apareceran aqui',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isPanic = notification.type == NotificationType.panicAlert;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        context.read<NotificationBloc>().add(DismissNotificationEvent(notification.id));
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.emergency,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isPanic && isUnread
                ? AppTheme.emergencyLight
                : isUnread
                    ? AppTheme.primarySurface
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isPanic && isUnread
                  ? AppTheme.emergency.withValues(alpha: 0.3)
                  : isUnread
                      ? AppTheme.primary.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
              width: isPanic && isUnread ? 2 : 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: isPanic
                          ? AppTheme.emergency.withValues(alpha: 0.1)
                          : AppTheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.titleSmall.copyWith(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isPanic ? AppTheme.emergency : AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(notification.createdAt),
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          if (isPanic) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.emergency,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'URGENTE',
                                style: AppTheme.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    HapticFeedback.lightImpact();

    if (!notification.isRead) {
      context.read<NotificationBloc>().add(MarkAsReadEvent(notification.id));
    }

    switch (notification.type) {
      case NotificationType.panicAlert:
        _navigateToPanicAlert(notification);
        break;
      case NotificationType.newCitizenReport:
        _navigateToReport(notification);
        break;
      case NotificationType.reportStatusChanged:
      case NotificationType.reportResponse:
      case NotificationType.reportAssigned:
      case NotificationType.newReport:
        _navigateToReport(notification);
        break;
      default:
        _showNotificationDetail(notification);
    }
  }

  void _navigateToPanicAlert(AppNotification notification) {
    final lat = notification.data['latitude'];
    final lng = notification.data['longitude'];

    if (lat != null && lng != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emergency, color: AppTheme.emergency),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Alerta de Panico')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 16),
              if (notification.data['address'] != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.data['address'],
                        style: AppTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.map),
              label: const Text('Ver en Mapa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      _showNotificationDetail(notification);
    }
  }

  void _navigateToReport(AppNotification notification) {
    _showNotificationDetail(notification);
  }

  void _showNotificationDetail(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: AppTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              notification.body,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: 8),
                Text(
                  _formatFullDate(notification.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Botón "Ir" si hay destino de navegación
                if (_hasNavigationTarget(notification))
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateToNotificationTarget(notification);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Ir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (_hasNavigationTarget(notification))
                  const SizedBox(width: 12),
                // Botón "Entendido"
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.panicAlert:
        return Icons.emergency_rounded;
      case NotificationType.newCitizenReport:
        return Icons.report_problem_rounded;
      case NotificationType.reportStatusChanged:
        return Icons.update_rounded;
      case NotificationType.reportResponse:
        return Icons.reply_rounded;
      case NotificationType.reportAssigned:
        return Icons.person_add_rounded;
      case NotificationType.newReport:
        return Icons.assignment_rounded;
      case NotificationType.reminder:
        return Icons.schedule_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.panicAlert:
        return AppTheme.emergency;
      case NotificationType.newCitizenReport:
        return AppTheme.warning;
      case NotificationType.reportStatusChanged:
        return AppTheme.info;
      case NotificationType.reportResponse:
        return AppTheme.primary;
      case NotificationType.reportAssigned:
        return Colors.purple;
      case NotificationType.newReport:
        return AppTheme.warning;
      case NotificationType.reminder:
        return Colors.amber;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Ahora';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays} dias';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatFullDate(DateTime dateTime) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Verifica si la notificación tiene un destino de navegación
  bool _hasNavigationTarget(AppNotification notification) {
    // Verificar si tiene datos de navegación
    final data = notification.data;

    // Tipos que pueden tener navegación
    switch (notification.type) {
      case NotificationType.panicAlert:
        return data['panicAlertId'] != null || data['alertId'] != null;
      case NotificationType.reportStatusChanged:
      case NotificationType.reportResponse:
      case NotificationType.reportAssigned:
      case NotificationType.newReport:
      case NotificationType.newCitizenReport:
        return data['reportId'] != null;
      default:
        return false;
    }
  }

  /// Navega al destino de la notificación
  void _navigateToNotificationTarget(AppNotification notification) {
    final data = notification.data;

    switch (notification.type) {
      case NotificationType.panicAlert:
        final alertId = data['panicAlertId'] ?? data['alertId'];
        if (alertId != null) {
          // Navegar a la pantalla de alerta de pánico
          Navigator.pushNamed(
            context,
            '/panic-alert-detail',
            arguments: {'alertId': alertId},
          );
        }
        break;
      case NotificationType.reportStatusChanged:
      case NotificationType.reportResponse:
      case NotificationType.reportAssigned:
      case NotificationType.newReport:
      case NotificationType.newCitizenReport:
        final reportId = data['reportId'];
        if (reportId != null) {
          // Navegar a la pantalla de detalle del reporte
          Navigator.pushNamed(
            context,
            '/report-detail',
            arguments: {'reportId': reportId},
          );
        }
        break;
      default:
        break;
    }
  }
}
