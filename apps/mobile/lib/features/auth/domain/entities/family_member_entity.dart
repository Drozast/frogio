// lib/features/auth/domain/entities/family_member_entity.dart
import 'package:equatable/equatable.dart';

class FamilyMemberEntity extends Equatable {
  final String? id;
  final String name;
  final String? rut; // RUT del integrante
  final String relationship; // padre, madre, hijo, abuelo, etc.
  final String? phone;
  final bool hasDisability;
  final String? disabilityType;
  final bool hasChronicIllness;
  final String? illnessType;
  final String? notes;

  const FamilyMemberEntity({
    this.id,
    required this.name,
    this.rut,
    required this.relationship,
    this.phone,
    this.hasDisability = false,
    this.disabilityType,
    this.hasChronicIllness = false,
    this.illnessType,
    this.notes,
  });

  FamilyMemberEntity copyWith({
    String? id,
    String? name,
    String? rut,
    String? relationship,
    String? phone,
    bool? hasDisability,
    String? disabilityType,
    bool? hasChronicIllness,
    String? illnessType,
    String? notes,
  }) {
    return FamilyMemberEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      rut: rut ?? this.rut,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      hasDisability: hasDisability ?? this.hasDisability,
      disabilityType: disabilityType ?? this.disabilityType,
      hasChronicIllness: hasChronicIllness ?? this.hasChronicIllness,
      illnessType: illnessType ?? this.illnessType,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'rut': rut,
      'relationship': relationship,
      'phone': phone,
      'hasDisability': hasDisability,
      'disabilityType': disabilityType,
      'hasChronicIllness': hasChronicIllness,
      'illnessType': illnessType,
      'notes': notes,
    };
  }

  factory FamilyMemberEntity.fromJson(Map<String, dynamic> json) {
    return FamilyMemberEntity(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      rut: json['rut'],
      relationship: json['relationship'] ?? '',
      phone: json['phone'],
      hasDisability: json['hasDisability'] ?? false,
      disabilityType: json['disabilityType'],
      hasChronicIllness: json['hasChronicIllness'] ?? false,
      illnessType: json['illnessType'],
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props => [
    id, name, rut, relationship, phone,
    hasDisability, disabilityType,
    hasChronicIllness, illnessType, notes
  ];
}

// Relaciones familiares disponibles
class FamilyRelationships {
  static const List<String> all = [
    'Cónyuge',
    'Hijo/a',
    'Padre',
    'Madre',
    'Abuelo/a',
    'Hermano/a',
    'Nieto/a',
    'Tío/a',
    'Sobrino/a',
    'Otro familiar',
  ];
}
