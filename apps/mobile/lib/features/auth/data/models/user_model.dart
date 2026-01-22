// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.rut,
    required super.role,
    super.muniId,
    super.phoneNumber,
    super.address,
    super.profileImageUrl,
    required super.createdAt,
    super.updatedAt,
    super.latitude,
    super.longitude,
    super.referenceNotes,
    super.familyMembers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parsear family members si existen
    List<FamilyMemberEntity> familyMembers = [];
    if (json['familyMembers'] != null) {
      familyMembers = (json['familyMembers'] as List)
          .map((m) => FamilyMemberEntity.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['firstName'] != null || json['lastName'] != null
          ? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim()
          : json['name'] as String?,
      rut: json['rut'] as String?,
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
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      referenceNotes: json['referenceNotes'] as String?,
      familyMembers: familyMembers,
    );
  }

  Map<String, dynamic> toJson() {
    final nameParts = name?.split(' ') ?? ['', ''];
    return {
      'id': id,
      'email': email,
      'firstName': nameParts.isNotEmpty ? nameParts.first : '',
      'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      'rut': rut,
      'role': role,
      'tenantId': muniId,
      'phoneNumber': phoneNumber,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'referenceNotes': referenceNotes,
      'familyMembers': familyMembers.map((m) => m.toJson()).toList(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      rut: entity.rut,
      role: entity.role,
      muniId: entity.muniId,
      phoneNumber: entity.phoneNumber,
      address: entity.address,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      latitude: entity.latitude,
      longitude: entity.longitude,
      referenceNotes: entity.referenceNotes,
      familyMembers: entity.familyMembers,
    );
  }

  /// Create model from REST API response (alias for fromJson)
  factory UserModel.fromApi(Map<String, dynamic> json) => UserModel.fromJson(json);
}
