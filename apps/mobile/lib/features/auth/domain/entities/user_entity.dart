// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String? muniId;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.muniId,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
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

  // Crear copia con nuevos valores
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? muniId,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      muniId: muniId ?? this.muniId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, email, name, role, muniId, phoneNumber, 
    address, profileImageUrl, createdAt, updatedAt
  ];
}