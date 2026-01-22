// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';
import 'family_member_entity.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? rut; // RUT del usuario
  final String role;
  final String? muniId;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nuevos campos para perfil completo
  final double? latitude;
  final double? longitude;
  final String? referenceNotes; // Cuadro de referencia
  final List<FamilyMemberEntity> familyMembers;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.rut,
    required this.role,
    this.muniId,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.latitude,
    this.longitude,
    this.referenceNotes,
    this.familyMembers = const [],
  });

  // Capitalizar nombre automáticamente
  String get displayName {
    if (name == null || name!.isEmpty) return 'Usuario';
    return name!.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Verificar si el perfil está completo
  bool get isProfileComplete {
    return name != null && 
           name!.isNotEmpty && 
           phoneNumber != null && 
           phoneNumber!.isNotEmpty && 
           address != null && 
           address!.isNotEmpty;
  }

  // Verificar si tiene coordenadas guardadas
  bool get hasLocation => latitude != null && longitude != null;

  // Crear copia con nuevos valores
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? rut,
    String? role,
    String? muniId,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? referenceNotes,
    List<FamilyMemberEntity>? familyMembers,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      rut: rut ?? this.rut,
      role: role ?? this.role,
      muniId: muniId ?? this.muniId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      referenceNotes: referenceNotes ?? this.referenceNotes,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }

  @override
  List<Object?> get props => [
    id, email, name, rut, role, muniId, phoneNumber,
    address, profileImageUrl, createdAt, updatedAt,
    latitude, longitude, referenceNotes, familyMembers
  ];
}