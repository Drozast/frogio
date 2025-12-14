// lib/core/blocs/notification/notification_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/notification_widget.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {}

class AddNotificationEvent extends NotificationEvent {
  final AppNotification notification;
  
  const AddNotificationEvent(this.notification);
  
  @override
  List<Object> get props => [notification];
}

class MarkAsReadEvent extends NotificationEvent {
  final String notificationId;
  
  const MarkAsReadEvent(this.notificationId);
  
  @override
  List<Object> get props => [notificationId];
}

class DismissNotificationEvent extends NotificationEvent {
  final String notificationId;
  
  const DismissNotificationEvent(this.notificationId);
  
  @override
  List<Object> get props => [notificationId];
}

class ClearAllNotificationsEvent extends NotificationEvent {}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  
  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });
  
  @override
  List<Object> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  
  const NotificationError(this.message);
  
  @override
  List<Object> get props => [message];
}

// BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final List<AppNotification> _notifications = [];
  
  NotificationBloc() : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<AddNotificationEvent>(_onAddNotification);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<DismissNotificationEvent>(_onDismissNotification);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
  }

  void _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationLoading());
    
    try {
      // En implementación real, cargar desde base de datos local o API
      _loadMockNotifications();
      
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError('Error al cargar notificaciones: ${e.toString()}'));
    }
  }

  void _onAddNotification(
    AddNotificationEvent event,
    Emitter<NotificationState> emit,
  ) {
    _notifications.insert(0, event.notification);
    
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    emit(NotificationLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));
  }

  void _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) {
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      
      final unreadCount = _notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        unreadCount: unreadCount,
      ));
    }
  }

  void _onDismissNotification(
    DismissNotificationEvent event,
    Emitter<NotificationState> emit,
  ) {
    _notifications.removeWhere((n) => n.id == event.notificationId);
    
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    emit(NotificationLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));
  }

  void _onClearAllNotifications(
    ClearAllNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) {
    _notifications.clear();
    emit(const NotificationLoaded(notifications: [], unreadCount: 0));
  }

  void _loadMockNotifications() {
    _notifications.addAll([
      AppNotification(
        id: '1',
        title: 'Estado actualizado',
        body: 'Tu denuncia #123 cambió a "En Proceso"',
        type: NotificationType.reportStatusChanged,
        data: {'reportId': '123'},
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'Nueva respuesta',
        body: 'El inspector Juan Pérez respondió a tu denuncia',
        type: NotificationType.reportResponse,
        data: {'reportId': '456'},
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '3',
        title: 'Recordatorio',
        body: 'Completa tu perfil para crear denuncias',
        type: NotificationType.reminder,
        data: {'reminderType': 'incomplete_profile'},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
    ]);
  }
}