// lib/core/blocs/notification/notification_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notification_api_data_source.dart';
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

class MarkAllAsReadEvent extends NotificationEvent {}

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
  final NotificationApiDataSource? apiDataSource;
  final List<AppNotification> _notifications = [];

  NotificationBloc({this.apiDataSource}) : super(NotificationInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<AddNotificationEvent>(_onAddNotification);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<DismissNotificationEvent>(_onDismissNotification);
    on<ClearAllNotificationsEvent>(_onClearAllNotifications);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    try {
      if (apiDataSource != null) {
        // Cargar desde API
        final notifications = await apiDataSource!.getNotifications(limit: 50);
        _notifications.clear();
        _notifications.addAll(notifications);
      }

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

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      try {
        // Marcar como leída en el API
        await apiDataSource?.markAsRead(event.notificationId);

        _notifications[index] = _notifications[index].copyWith(isRead: true);

        final unreadCount = _notifications.where((n) => !n.isRead).length;
        emit(NotificationLoaded(
          notifications: List.from(_notifications),
          unreadCount: unreadCount,
        ));
      } catch (_) {
        // Marcar localmente aunque falle el API
        _notifications[index] = _notifications[index].copyWith(isRead: true);

        final unreadCount = _notifications.where((n) => !n.isRead).length;
        emit(NotificationLoaded(
          notifications: List.from(_notifications),
          unreadCount: unreadCount,
        ));
      }
    }
  }

  Future<void> _onDismissNotification(
    DismissNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await apiDataSource?.deleteNotification(event.notificationId);
    } catch (_) {
      // Continuar aunque falle el API
    }

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

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await apiDataSource?.markAllAsRead();

      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }

      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        unreadCount: 0,
      ));
    } catch (e) {
      emit(const NotificationError('Error al marcar todas como leídas'));
    }
  }
}
