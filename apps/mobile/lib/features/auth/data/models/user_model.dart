// lib/features/auth/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    required super.role,
    super.muniId,
    super.phoneNumber,
    super.address,
    super.profileImageUrl,
    required super.createdAt,
    super.updatedAt,
  });

  factory UserModel.fromFirebase(Map<String, dynamic> data, String uid) {
    return UserModel(
      id: uid,
      email: data['email'] ?? '',
      name: data['name'],
      role: data['role'] ?? 'citizen',
      muniId: data['muniId'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'muniId': muniId,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Crear modelo desde entidad
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      role: entity.role,
      muniId: entity.muniId,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}