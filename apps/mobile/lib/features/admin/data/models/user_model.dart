// lib/features/admin/data/models/user_model.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? muniId;
  final String? profileImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.muniId,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      muniId: json['muniId'],
      profileImageUrl: json['profileImageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'muniId': muniId,
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: name,
      firstName: null,
      lastName: null,
      role: role,
      muniId: muniId,
      muniName: null,
      isActive: isActive,
      isEmailVerified: true, // Valor por defecto
      phoneNumber: null,
      address: null,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt, // CORREGIDO: usar createdAt del modelo
      updatedAt: updatedAt ?? createdAt, // CORREGIDO: usar updatedAt o createdAt como fallback
      lastLoginAt: null,
      permissions: UserPermissions.fromRole(role),
      statistics: UserStatistics.empty(),
      assignedAreas: const [],
      preferences: null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        muniId,
        profileImageUrl,
        isActive,
        createdAt,
        updatedAt,
      ];
}