// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/notification_manager.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/sign_in_user.dart';
import '../../domain/usecases/sign_out_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUser getCurrentUser;
  final SignInUser signInUser;
  final SignOutUser signOutUser;
  final RegisterUser registerUser;
  final ForgotPassword forgotPassword;

  AuthBloc({
    required this.getCurrentUser,
    required this.signInUser,
    required this.signOutUser,
    required this.registerUser,
    required this.forgotPassword,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignIn);
    on<SignOutEvent>(_onSignOut);
    on<RegisterEvent>(_onRegister);
    on<ForgotPasswordEvent>(_onForgotPassword);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await getCurrentUser(NoParams());
      
      result.fold(
        (failure) => emit(Unauthenticated()),
        (user) {
          if (user != null) {
            // Suscribir a notificaciones después de autenticar
            _subscribeToNotifications(user.id, user.role);
            emit(Authenticated(user));
          } else {
            emit(Unauthenticated());
          }
        },
      );
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _subscribeToNotifications(String userId, String role) async {
    try {
      await NotificationManager().subscribeToUserTopics(userId, role);
      log('Notificaciones activadas para usuario $userId con rol $role');
    } catch (e) {
      log('Error al suscribir notificaciones: $e');
    }
  }

  Future<void> _onSignIn(
    SignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await signInUser(
        SignInParams(
          email: event.email,
          password: event.password,
        ),
      );
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) {
          // Suscribir a notificaciones después del login
          _subscribeToNotifications(user.id, user.role);
          emit(Authenticated(user));
        },
      );
    } catch (e) {
      emit(AuthError('Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await signOutUser(NoParams());

      // Desuscribir de notificaciones (no bloquear si falla)
      try {
        await NotificationManager().unsubscribeFromAllTopics();
      } catch (_) {
        // Ignorar errores de notificaciones
      }

      result.fold(
        (failure) {
          // Incluso si el servidor falla, cerrar sesión localmente
          emit(Unauthenticated());
        },
        (_) {
          emit(Unauthenticated());
        },
      );
    } catch (e) {
      // Forzar logout incluso si hay error
      try {
        await NotificationManager().unsubscribeFromAllTopics();
      } catch (_) {}
      emit(Unauthenticated());
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await registerUser(
        RegisterParams(
          email: event.email,
          password: event.password,
          name: event.name,
          rut: event.rut,
        ),
      );
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (user) {
          // Suscribir a notificaciones después del registro
          _subscribeToNotifications(user.id, user.role);
          emit(Authenticated(user));
        },
      );
    } catch (e) {
      emit(AuthError('Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final result = await forgotPassword(event.email);
      
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => emit(PasswordResetSent()),
      );
    } catch (e) {
      emit(AuthError('Error inesperado: ${e.toString()}'));
    }
  }
}