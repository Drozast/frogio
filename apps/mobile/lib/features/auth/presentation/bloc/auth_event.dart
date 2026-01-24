// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignOutEvent extends AuthEvent {}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String rut;

  const RegisterEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.rut,
  });

  @override
  List<Object> get props => [email, password, name, rut];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}