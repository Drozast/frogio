// lib/features/auth/presentation/bloc/profile/profile_event.dart
import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class UpdateProfileEvent extends ProfileEvent {
  final String userId;
  final String? name;
  final String? phoneNumber;
  final String? address;

  const UpdateProfileEvent({
    required this.userId,
    this.name,
    this.phoneNumber,
    this.address,
  });

  @override
  List<Object?> get props => [userId, name, phoneNumber, address];
}

class UploadProfileImageEvent extends ProfileEvent {
  final String userId;
  final File imageFile;

  const UploadProfileImageEvent({
    required this.userId,
    required this.imageFile,
  });

  @override
  List<Object> get props => [userId, imageFile];
}