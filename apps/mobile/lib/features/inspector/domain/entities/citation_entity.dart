// lib/features/inspector/domain/entities/citation_entity.dart
import 'package:equatable/equatable.dart';

class CitationEntity extends Equatable {
  final String id;
  final CitationType citationType;
  final TargetType targetType;
  final String? targetName;
  final String? targetRut;
  final String? targetAddress;
  final String? targetPhone;
  final String? targetPlate;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final String citationNumber;
  final String reason;
  final String? notes;
  final List<String> photos;
  final CitationStatus status;
  final NotificationMethod? notificationMethod;
  final DateTime? notifiedAt;
  final String? issuedBy;
  final String? issuerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CitationEntity({
    required this.id,
    required this.citationType,
    required this.targetType,
    this.targetName,
    this.targetRut,
    this.targetAddress,
    this.targetPhone,
    this.targetPlate,
    this.locationAddress,
    this.latitude,
    this.longitude,
    required this.citationNumber,
    required this.reason,
    this.notes,
    required this.photos,
    required this.status,
    this.notificationMethod,
    this.notifiedAt,
    this.issuedBy,
    this.issuerName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        citationType,
        targetType,
        targetName,
        targetRut,
        targetAddress,
        targetPhone,
        targetPlate,
        locationAddress,
        latitude,
        longitude,
        citationNumber,
        reason,
        notes,
        photos,
        status,
        notificationMethod,
        notifiedAt,
        issuedBy,
        issuerName,
        createdAt,
        updatedAt,
      ];

  CitationEntity copyWith({
    String? id,
    CitationType? citationType,
    TargetType? targetType,
    String? targetName,
    String? targetRut,
    String? targetAddress,
    String? targetPhone,
    String? targetPlate,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? citationNumber,
    String? reason,
    String? notes,
    List<String>? photos,
    CitationStatus? status,
    NotificationMethod? notificationMethod,
    DateTime? notifiedAt,
    String? issuedBy,
    String? issuerName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CitationEntity(
      id: id ?? this.id,
      citationType: citationType ?? this.citationType,
      targetType: targetType ?? this.targetType,
      targetName: targetName ?? this.targetName,
      targetRut: targetRut ?? this.targetRut,
      targetAddress: targetAddress ?? this.targetAddress,
      targetPhone: targetPhone ?? this.targetPhone,
      targetPlate: targetPlate ?? this.targetPlate,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      citationNumber: citationNumber ?? this.citationNumber,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      notificationMethod: notificationMethod ?? this.notificationMethod,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      issuedBy: issuedBy ?? this.issuedBy,
      issuerName: issuerName ?? this.issuerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get targetDisplayName {
    if (targetName != null && targetName!.isNotEmpty) return targetName!;
    if (targetRut != null && targetRut!.isNotEmpty) return 'RUT: $targetRut';
    if (targetPlate != null && targetPlate!.isNotEmpty) return 'Patente: $targetPlate';
    return 'Sin identificar';
  }

  bool get hasLocation => latitude != null && longitude != null;
}

enum CitationType {
  advertencia,
  citacion;

  String get displayName {
    switch (this) {
      case CitationType.advertencia:
        return 'Advertencia';
      case CitationType.citacion:
        return 'Citación';
    }
  }

  static CitationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'advertencia':
        return CitationType.advertencia;
      case 'citacion':
        return CitationType.citacion;
      default:
        return CitationType.citacion;
    }
  }
}

enum TargetType {
  persona,
  domicilio,
  vehiculo,
  comercio,
  otro;

  String get displayName {
    switch (this) {
      case TargetType.persona:
        return 'Persona';
      case TargetType.domicilio:
        return 'Domicilio';
      case TargetType.vehiculo:
        return 'Vehículo';
      case TargetType.comercio:
        return 'Comercio';
      case TargetType.otro:
        return 'Otro';
    }
  }

  static TargetType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'persona':
        return TargetType.persona;
      case 'domicilio':
        return TargetType.domicilio;
      case 'vehiculo':
        return TargetType.vehiculo;
      case 'comercio':
        return TargetType.comercio;
      case 'otro':
        return TargetType.otro;
      default:
        return TargetType.otro;
    }
  }
}

enum CitationStatus {
  pendiente,
  notificado,
  asistio,
  noAsistio,
  cancelado;

  String get displayName {
    switch (this) {
      case CitationStatus.pendiente:
        return 'Pendiente';
      case CitationStatus.notificado:
        return 'Notificado';
      case CitationStatus.asistio:
        return 'Asistió';
      case CitationStatus.noAsistio:
        return 'No Asistió';
      case CitationStatus.cancelado:
        return 'Cancelado';
    }
  }

  static CitationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return CitationStatus.pendiente;
      case 'notificado':
        return CitationStatus.notificado;
      case 'asistio':
        return CitationStatus.asistio;
      case 'no_asistio':
        return CitationStatus.noAsistio;
      case 'cancelado':
        return CitationStatus.cancelado;
      default:
        return CitationStatus.pendiente;
    }
  }

  String toApiString() {
    switch (this) {
      case CitationStatus.pendiente:
        return 'pendiente';
      case CitationStatus.notificado:
        return 'notificado';
      case CitationStatus.asistio:
        return 'asistio';
      case CitationStatus.noAsistio:
        return 'no_asistio';
      case CitationStatus.cancelado:
        return 'cancelado';
    }
  }
}

enum NotificationMethod {
  email,
  sms,
  carta,
  enPersona;

  String get displayName {
    switch (this) {
      case NotificationMethod.email:
        return 'Email';
      case NotificationMethod.sms:
        return 'SMS';
      case NotificationMethod.carta:
        return 'Carta';
      case NotificationMethod.enPersona:
        return 'En Persona';
    }
  }

  static NotificationMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'email':
        return NotificationMethod.email;
      case 'sms':
        return NotificationMethod.sms;
      case 'carta':
        return NotificationMethod.carta;
      case 'en_persona':
        return NotificationMethod.enPersona;
      default:
        return NotificationMethod.enPersona;
    }
  }

  String toApiString() {
    switch (this) {
      case NotificationMethod.email:
        return 'email';
      case NotificationMethod.sms:
        return 'sms';
      case NotificationMethod.carta:
        return 'carta';
      case NotificationMethod.enPersona:
        return 'en_persona';
    }
  }
}
