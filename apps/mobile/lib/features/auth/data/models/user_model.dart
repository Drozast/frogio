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

  /// Create model from REST API response
  factory UserModel.fromApi(Map<String, dynamic> data) {
    // Combinar first_name y last_name para nombre completo
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return UserModel(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: fullName.isNotEmpty ? fullName : null,
      role: data['role'] ?? 'citizen',
      muniId: data['tenant_id'], // En la API usamos tenant_id
      phoneNumber: data['phone'],
      address: data['address'],
      profileImageUrl: data['profile_image_url'],
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
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
