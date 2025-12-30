import 'package:equatable/equatable.dart';

import '../../domain/entities/infraction_entity.dart';

class InfractionModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String ordinanceRef;
  final Map<String, dynamic> location;
  final String offenderId;
  final String offenderName;
  final String offenderDocument;
  final String inspectorId;
  final String muniId;
  final List<String> evidence;
  final List<String> signatures;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Map<String, dynamic>> historyLog;

  const InfractionModel({
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
    this.updatedAt,
    required this.historyLog,
  });

  factory InfractionModel.fromJson(Map<String, dynamic> json) {
    return InfractionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      ordinanceRef: json['ordinanceRef'] ?? '',
      location: Map<String, dynamic>.from(json['location'] ?? {}),
      offenderId: json['offenderId'] ?? '',
      offenderName: json['offenderName'] ?? '',
      offenderDocument: json['offenderDocument'] ?? '',
      inspectorId: json['inspectorId'] ?? '',
      muniId: json['muniId'] ?? '',
      evidence: List<String>.from(json['evidence'] ?? []),
      signatures: List<String>.from(json['signatures'] ?? []),
      status: json['status'] ?? 'created',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      historyLog: List<Map<String, dynamic>>.from(json['historyLog'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ordinanceRef': ordinanceRef,
      'location': location,
      'offenderId': offenderId,
      'offenderName': offenderName,
      'offenderDocument': offenderDocument,
      'inspectorId': inspectorId,
      'muniId': muniId,
      'evidence': evidence,
      'signatures': signatures,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'historyLog': historyLog,
    };
  }

  // Método auxiliar para convertir Map a LocationData
  LocationData _createLocationData() {
    return LocationData(
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0.0,
      address: location['address'] as String?,
      city: location['city'] as String? ?? '',
      region: location['region'] as String? ?? '',
      country: location['country'] as String? ?? '',
    );
  }

  // Método auxiliar para convertir String a InfractionStatus enum
  InfractionStatus _getInfractionStatus() {
    switch (status.toLowerCase()) {
      case 'created':
        return InfractionStatus.created;
      case 'signed':
        return InfractionStatus.signed;
      case 'submitted':
        return InfractionStatus.submitted;
      case 'reviewed':
        return InfractionStatus.reviewed;
      case 'appealed':
        return InfractionStatus.appealed;
      case 'confirmed':
        return InfractionStatus.confirmed;
      case 'cancelled':
        return InfractionStatus.cancelled;
      case 'paid':
        return InfractionStatus.paid;
      case 'pending':
        return InfractionStatus.pending;
      default:
        return InfractionStatus.created;
    }
  }

  InfractionEntity toEntity() {
    return InfractionEntity(
      id: id,
      title: title,
      description: description,
      ordinanceRef: ordinanceRef,
      location: _createLocationData(),
      offenderId: offenderId,
      offenderName: offenderName,
      offenderDocument: offenderDocument,
      inspectorId: inspectorId,
      muniId: muniId,
      evidence: evidence,
      signatures: signatures,
      status: _getInfractionStatus(),
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      historyLog: historyLog.map((item) => InfractionHistoryItem(
        timestamp: item['timestamp'] != null
            ? DateTime.parse(item['timestamp'].toString())
            : DateTime.now(),
        status: _stringToInfractionStatus(item['status'] ?? 'created'),
        comment: item['comment'],
        userId: item['userId'],
        userName: item['userName'],
      )).toList(),
    );
  }

  InfractionStatus _stringToInfractionStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'created':
        return InfractionStatus.created;
      case 'signed':
        return InfractionStatus.signed;
      case 'submitted':
        return InfractionStatus.submitted;
      case 'reviewed':
        return InfractionStatus.reviewed;
      case 'appealed':
        return InfractionStatus.appealed;
      case 'confirmed':
        return InfractionStatus.confirmed;
      case 'cancelled':
        return InfractionStatus.cancelled;
      case 'paid':
        return InfractionStatus.paid;
      case 'pending':
        return InfractionStatus.pending;
      default:
        return InfractionStatus.created;
    }
  }

  // Método auxiliar para convertir LocationData a Map
  static Map<String, dynamic> _locationDataToMap(LocationData locationData) {
    return {
      'latitude': locationData.latitude,
      'longitude': locationData.longitude,
      'address': locationData.address,
      'city': locationData.city,
      'region': locationData.region,
      'country': locationData.country,
    };
  }

  // Método auxiliar para convertir InfractionStatus enum a String
  static String _infractionStatusToString(InfractionStatus status) {
    return status.name;
  }

  factory InfractionModel.fromEntity(InfractionEntity entity) {
    return InfractionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      ordinanceRef: entity.ordinanceRef,
      location: _locationDataToMap(entity.location),
      offenderId: entity.offenderId,
      offenderName: entity.offenderName,
      offenderDocument: entity.offenderDocument,
      inspectorId: entity.inspectorId,
      muniId: entity.muniId,
      evidence: entity.evidence,
      signatures: entity.signatures,
      status: _infractionStatusToString(entity.status),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      historyLog: entity.historyLog.map((item) => {
        'timestamp': item.timestamp,
        'status': item.status.name,
        'comment': item.comment,
        'userId': item.userId,
        'userName': item.userName,
      }).toList(),
    );
  }

  InfractionModel copyWith({
    String? id,
    String? title,
    String? description,
    String? ordinanceRef,
    Map<String, dynamic>? location,
    String? offenderId,
    String? offenderName,
    String? offenderDocument,
    String? inspectorId,
    String? muniId,
    List<String>? evidence,
    List<String>? signatures,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? historyLog,
  }) {
    return InfractionModel(
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

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        ordinanceRef,
        location,
        offenderId,
        offenderName,
        offenderDocument,
        inspectorId,
        muniId,
        evidence,
        signatures,
        status,
        createdAt,
        updatedAt,
        historyLog,
      ];

  /// Create model from REST API response
  factory InfractionModel.fromApi(Map<String, dynamic> data) {
    // Parsear ubicación
    final locationStr = data['location'] as String? ?? '';
    final location = {
      'latitude': 0.0,
      'longitude': 0.0,
      'address': locationStr,
    };

    return InfractionModel(
      id: data['id'] ?? '',
      title: data['type'] ?? '',
      description: data['description'] ?? '',
      ordinanceRef: data['ordinance_reference'] ?? '',
      location: location,
      offenderId: data['user_id'] ?? '',
      offenderName: '${data['user_first_name'] ?? ''} ${data['user_last_name'] ?? ''}',
      offenderDocument: data['vehicle_plate'] ?? '',
      inspectorId: data['inspector_id'] ?? '',
      muniId: data['tenant_id'] ?? '',
      evidence: [], // Evidencias se obtienen por separado
      signatures: [],
      status: data['status'] ?? 'pendiente',
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'])
          : null,
      historyLog: [],
    );
  }
}
