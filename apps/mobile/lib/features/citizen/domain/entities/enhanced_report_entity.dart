// lib/features/citizen/domain/entities/enhanced_report_entity.dart
import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? references;
  final LocationData location;
  final String citizenId;
  final String muniId;
  final ReportStatus status;
  final Priority priority;
  final List<MediaAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusHistoryItem> statusHistory;
  final List<ReportResponse> responses;
  final String? assignedToId;
  final String? assignedToName;
  final String? citizenName;
  final String? citizenPhone;
  final String? citizenEmail;

  const ReportEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.references,
    required this.location,
    required this.citizenId,
    required this.muniId,
    required this.status,
    required this.priority,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
    required this.responses,
    this.assignedToId,
    this.assignedToName,
    this.citizenName,
    this.citizenPhone,
    this.citizenEmail,
  });

  @override
  List<Object?> get props => [
    id, title, description, category, references, location,
    citizenId, muniId, status, priority, attachments,
    createdAt, updatedAt, statusHistory, responses,
    assignedToId, assignedToName, citizenName, citizenPhone, citizenEmail,
  ];

  ReportEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? references,
    LocationData? location,
    String? citizenId,
    String? muniId,
    ReportStatus? status,
    Priority? priority,
    List<MediaAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StatusHistoryItem>? statusHistory,
    List<ReportResponse>? responses,
    String? assignedToId,
    String? assignedToName,
    String? citizenName,
    String? citizenPhone,
    String? citizenEmail,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      references: references ?? this.references,
      location: location ?? this.location,
      citizenId: citizenId ?? this.citizenId,
      muniId: muniId ?? this.muniId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      responses: responses ?? this.responses,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      citizenName: citizenName ?? this.citizenName,
      citizenPhone: citizenPhone ?? this.citizenPhone,
      citizenEmail: citizenEmail ?? this.citizenEmail,
    );
  }
}

// Enums y clases relacionadas
enum ReportStatus {
  /// Denuncia nueva, sin inspector asignado → backend: 'pendiente'
  pendiente,
  /// Inspector la tomó, en gestión → backend: 'en_proceso'
  enProceso,
  /// Cerrada positivamente → backend: 'resuelto'
  resuelto,
  /// Cerrada negativamente / rechazada / duplicada → backend: 'rechazado'
  rechazado;

  String get displayName {
    switch (this) {
      case ReportStatus.pendiente:
        return 'Pendiente';
      case ReportStatus.enProceso:
        return 'En Proceso';
      case ReportStatus.resuelto:
        return 'Resuelta';
      case ReportStatus.rechazado:
        return 'Rechazada';
    }
  }

  /// Valor a enviar a la API
  String toApiString() {
    switch (this) {
      case ReportStatus.pendiente:
        return 'pendiente';
      case ReportStatus.enProceso:
        return 'en_proceso';
      case ReportStatus.resuelto:
        return 'resuelto';
      case ReportStatus.rechazado:
        return 'rechazado';
    }
  }

  /// Parsear valor recibido de la API
  static ReportStatus fromApiString(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
      case 'submitted':
      case 'draft':
        return ReportStatus.pendiente;
      case 'en_proceso':
      case 'inprogress':
      case 'in_progress':
      case 'reviewing':
        return ReportStatus.enProceso;
      case 'resuelto':
      case 'resolved':
        return ReportStatus.resuelto;
      case 'rechazado':
      case 'rejected':
      case 'duplicate':
      case 'archived':
      case 'cancelled':
        return ReportStatus.rechazado;
      default:
        return ReportStatus.pendiente;
    }
  }
}

enum Priority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Baja';
      case Priority.medium:
        return 'Media';
      case Priority.high:
        return 'Alta';
      case Priority.urgent:
        return 'Urgente';
    }
  }
}

enum LocationSource {
  gps,
  map,
  manual;
}

enum MediaType {
  image,
  video;
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? manualAddress;
  final LocationSource source;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.manualAddress,
    required this.source,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, manualAddress, source];
}

class MediaAttachment extends Equatable {
  final String id;
  final String url;
  final String fileName;
  final MediaType type;
  final int? fileSize;
  final DateTime uploadedAt;

  const MediaAttachment({
    required this.id,
    required this.url,
    required this.fileName,
    required this.type,
    this.fileSize,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, url, fileName, type, fileSize, uploadedAt];
}

class StatusHistoryItem extends Equatable {
  final DateTime timestamp;
  final ReportStatus status;
  final String? comment;
  final String? userId;
  final String? userName;
  /// true si es un seguimiento del inspector sin cambio de estado
  final bool isFollowUp;
  /// Fotos/archivos adjuntos en esta entrada del historial
  final List<String> attachments;

  const StatusHistoryItem({
    required this.timestamp,
    required this.status,
    this.comment,
    this.userId,
    this.userName,
    this.isFollowUp = false,
    this.attachments = const [],
  });

  @override
  List<Object?> get props => [timestamp, status, comment, userId, userName, isFollowUp, attachments];
}

class ReportResponse extends Equatable {
  final String id;
  final String responderId;
  final String responderName;
  final String message;
  final List<MediaAttachment> attachments;
  final bool isPublic;
  final DateTime createdAt;

  const ReportResponse({
    required this.id,
    required this.responderId,
    required this.responderName,
    required this.message,
    required this.attachments,
    required this.isPublic,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, responderId, responderName, message,
    attachments, isPublic, createdAt,
  ];
}