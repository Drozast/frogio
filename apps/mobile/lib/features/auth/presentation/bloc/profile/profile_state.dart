// lib/features/auth/presentation/bloc/profile/profile_state.dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileUpdated extends ProfileState {
  final UserEntity user;

  const ProfileUpdated({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileImageUploading extends ProfileState {}

class ProfileImageUploaded extends ProfileState {
  final UserEntity user;

  const ProfileImageUploaded({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}