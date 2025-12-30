// lib/features/auth/data/models/user_model.dart
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['firstName'] != null || json['lastName'] != null
          ? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim()
          : json['name'] as String?,
      role: json['role'] as String,
      muniId: json['tenantId'] as String? ?? json['muniId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profileImageUrl'] as String? ?? json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final nameParts = name?.split(' ') ?? ['', ''];
    return {
      'id': id,
      'email': email,
      'firstName': nameParts.isNotEmpty ? nameParts.first : '',
      'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      'role': role,
      'tenantId': muniId,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

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

  /// Create model from REST API response (alias for fromJson)
  factory UserModel.fromApi(Map<String, dynamic> json) => UserModel.fromJson(json);
}
