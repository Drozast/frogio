// lib/features/inspector/domain/entities/infraction_entity.dart
import 'package:equatable/equatable.dart';

class InfractionEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String ordinanceRef;
  final LocationData location;
  final String offenderId;
  final String offenderName;
  final String offenderDocument;
  final String inspectorId;
  final String muniId;
  final List<String> evidence;
  final List<String> signatures;
  final InfractionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InfractionHistoryItem> historyLog;

  const InfractionEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.ordinanceRef,
    required this.location,
    required this.offenderId,
    required this.offenderName,
    required this.offenderDocument,
    required this.inspectorId,
    required this.muniId,
    required this.evidence,
    required this.signatures,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.historyLog,
  });

  @override
  List<Object?> get props => [
    id, title, description, ordinanceRef, location,
    offenderId, offenderName, offenderDocument, inspectorId,
    muniId, evidence, signatures, status, createdAt, updatedAt, historyLog,
  ];

  InfractionEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? ordinanceRef,
    LocationData? location,
    String? offenderId,
    String? offenderName,
    String? offenderDocument,
    String? inspectorId,
    String? muniId,
    List<String>? evidence,
    List<String>? signatures,
    InfractionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InfractionHistoryItem>? historyLog,
  }) {
    return InfractionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ordinanceRef: ordinanceRef ?? this.ordinanceRef,
      location: location ?? this.location,
      offenderId: offenderId ?? this.offenderId,
      offenderName: offenderName ?? this.offenderName,
      offenderDocument: offenderDocument ?? this.offenderDocument,
      inspectorId: inspectorId ?? this.inspectorId,
      muniId: muniId ?? this.muniId,
      evidence: evidence ?? this.evidence,
      signatures: signatures ?? this.signatures,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      historyLog: historyLog ?? this.historyLog,
    );
  }
}

enum InfractionStatus {
  created,
  signed,
  submitted,
  reviewed,
  appealed,
  confirmed,
  cancelled,
  paid,
  pending;

  String get displayName {
    switch (this) {
      case InfractionStatus.created:
        return 'Creada';
      case InfractionStatus.signed:
        return 'Firmada';
      case InfractionStatus.submitted:
        return 'Enviada';
      case InfractionStatus.reviewed:
        return 'Revisada';
      case InfractionStatus.appealed:
        return 'Apelada';
      case InfractionStatus.confirmed:
        return 'Confirmada';
      case InfractionStatus.cancelled:
        return 'Cancelada';
      case InfractionStatus.paid:
        return 'Pagada';
      case InfractionStatus.pending:
        return 'Pendiente';
    }
  }
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String city;
  final String region;
  final String country;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.city,
    required this.region,
    required this.country,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, city, region, country];

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? region,
    String? country,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
    );
  }
}

class InfractionHistoryItem extends Equatable {
  final DateTime timestamp;
  final InfractionStatus status;
  final String? comment;
  final String? userId;
  final String? userName;

  const InfractionHistoryItem({
    required this.timestamp,
    required this.status,
    this.comment,
    this.userId,
    this.userName,
  });

  @override
  List<Object?> get props => [timestamp, status, comment, userId, userName];

  InfractionHistoryItem copyWith({
    DateTime? timestamp,
    InfractionStatus? status,
    String? comment,
    String? userId,
    String? userName,
  }) {
    return InfractionHistoryItem(
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      comment: comment ?? this.comment,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }
}