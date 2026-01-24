// lib/features/inspector/data/models/citation_model.dart
import '../../domain/entities/citation_entity.dart';

// Helper para parsear photos que puede venir como String o List
List<String> _parsePhotos(dynamic photos) {
  if (photos == null) return [];
  if (photos is List) {
    return photos.map((e) => e.toString()).toList();
  }
  if (photos is String) {
    // Puede venir como "{url1,url2}" o "url" o vacío
    if (photos.isEmpty) return [];
    // Remover llaves si existen
    String cleaned = photos;
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.isEmpty) return [];
    // Separar por coma si hay múltiples URLs
    return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return [];
}

class CitationModel extends CitationEntity {
  const CitationModel({
    required super.id,
    required super.citationType,
    required super.targetType,
    super.targetName,
    super.targetRut,
    super.targetAddress,
    super.targetPhone,
    super.targetPlate,
    super.locationAddress,
    super.latitude,
    super.longitude,
    required super.citationNumber,
    required super.reason,
    super.notes,
    required super.photos,
    required super.status,
    super.notificationMethod,
    super.notifiedAt,
    super.issuedBy,
    super.issuerName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      id: json['id'] as String,
      citationType: CitationType.fromString(json['citation_type'] as String? ?? 'citacion'),
      targetType: TargetType.fromString(json['target_type'] as String? ?? 'otro'),
      targetName: json['target_name'] as String?,
      targetRut: json['target_rut'] as String?,
      targetAddress: json['target_address'] as String?,
      targetPhone: json['target_phone'] as String?,
      targetPlate: json['target_plate'] as String?,
      locationAddress: json['location_address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      citationNumber: json['citation_number'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      notes: json['notes'] as String?,
      photos: _parsePhotos(json['photos']),
      status: CitationStatus.fromString(json['status'] as String? ?? 'pendiente'),
      notificationMethod: json['notification_method'] != null
          ? NotificationMethod.fromString(json['notification_method'] as String)
          : null,
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'] as String)
          : null,
      issuedBy: json['issued_by'] as String?,
      issuerName: _buildIssuerName(json),
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  static String? _buildIssuerName(Map<String, dynamic> json) {
    final firstName = json['issuer_first_name'] as String?;
    final lastName = json['issuer_last_name'] as String?;
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'citation_type': citationType.name,
      'target_type': targetType.name,
      'target_name': targetName,
      'target_rut': targetRut,
      'target_address': targetAddress,
      'target_phone': targetPhone,
      'target_plate': targetPlate,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'citation_number': citationNumber,
      'reason': reason,
      'notes': notes,
      'photos': photos,
      'status': status.toApiString(),
      'notification_method': notificationMethod?.toApiString(),
      'notified_at': notifiedAt?.toIso8601String(),
      'issued_by': issuedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CitationEntity toEntity() {
    return CitationEntity(
      id: id,
      citationType: citationType,
      targetType: targetType,
      targetName: targetName,
      targetRut: targetRut,
      targetAddress: targetAddress,
      targetPhone: targetPhone,
      targetPlate: targetPlate,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      citationNumber: citationNumber,
      reason: reason,
      notes: notes,
      photos: photos,
      status: status,
      notificationMethod: notificationMethod,
      notifiedAt: notifiedAt,
      issuedBy: issuedBy,
      issuerName: issuerName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CreateCitationDto {
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
  final List<String>? photos;

  const CreateCitationDto({
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
    this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      'citationType': citationType.name,
      'targetType': targetType.name,
      if (targetName != null) 'targetName': targetName,
      if (targetRut != null) 'targetRut': targetRut,
      if (targetAddress != null) 'targetAddress': targetAddress,
      if (targetPhone != null) 'targetPhone': targetPhone,
      if (targetPlate != null) 'targetPlate': targetPlate,
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'citationNumber': citationNumber,
      'reason': reason,
      if (notes != null) 'notes': notes,
      if (photos != null && photos!.isNotEmpty) 'photos': photos,
    };
  }
}

class UpdateCitationDto {
  final CitationStatus? status;
  final NotificationMethod? notificationMethod;
  final String? notes;
  final String? targetName;
  final String? targetRut;
  final String? targetAddress;
  final String? targetPhone;
  final String? targetPlate;
  final String? locationAddress;
  final double? latitude;
  final double? longitude;
  final List<String>? photos;

  const UpdateCitationDto({
    this.status,
    this.notificationMethod,
    this.notes,
    this.targetName,
    this.targetRut,
    this.targetAddress,
    this.targetPhone,
    this.targetPlate,
    this.locationAddress,
    this.latitude,
    this.longitude,
    this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      if (status != null) 'status': status!.toApiString(),
      if (notificationMethod != null) 'notificationMethod': notificationMethod!.toApiString(),
      if (notes != null) 'notes': notes,
      if (targetName != null) 'targetName': targetName,
      if (targetRut != null) 'targetRut': targetRut,
      if (targetAddress != null) 'targetAddress': targetAddress,
      if (targetPhone != null) 'targetPhone': targetPhone,
      if (targetPlate != null) 'targetPlate': targetPlate,
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photos != null) 'photos': photos,
    };
  }
}

class CitationFilters {
  final CitationStatus? status;
  final CitationType? citationType;
  final TargetType? targetType;
  final String? issuedBy;
  final String? search;
  final DateTime? fromDate;
  final DateTime? toDate;

  const CitationFilters({
    this.status,
    this.citationType,
    this.targetType,
    this.issuedBy,
    this.search,
    this.fromDate,
    this.toDate,
  });

  Map<String, String> toQueryParams() {
    return {
      if (status != null) 'status': status!.toApiString(),
      if (citationType != null) 'citationType': citationType!.name,
      if (targetType != null) 'targetType': targetType!.name,
      if (issuedBy != null) 'issuedBy': issuedBy!,
      if (search != null) 'search': search!,
      if (fromDate != null) 'fromDate': fromDate!.toIso8601String().split('T')[0],
      if (toDate != null) 'toDate': toDate!.toIso8601String().split('T')[0],
    };
  }
}
