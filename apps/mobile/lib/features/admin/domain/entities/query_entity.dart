// lib/features/admin/domain/entities/query_entity.dart
import 'package:equatable/equatable.dart';

class QueryEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String citizenId;
  final String citizenName;
  final String citizenEmail;
  final String muniId;
  final QueryStatus status;
  final QueryCategory category;
  final QueryPriority priority;
  final List<String> imageUrls;
  final String? response;
  final String? responderId;
  final String? responderName;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime updatedAt;
  final List<QueryHistoryItem> historyLog;
  final bool isUrgent;
  final List<String> tags;

  const QueryEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.citizenId,
    required this.citizenName,
    required this.citizenEmail,
    required this.muniId,
    required this.status,
    required this.category,
    required this.priority,
    required this.imageUrls,
    this.response,
    this.responderId,
    this.responderName,
    required this.createdAt,
    this.answeredAt,
    required this.updatedAt,
    required this.historyLog,
    required this.isUrgent,
    required this.tags,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    citizenId,
    citizenName,
    citizenEmail,
    muniId,
    status,
    category,
    priority,
    imageUrls,
    response,
    responderId,
    responderName,
    createdAt,
    answeredAt,
    updatedAt,
    historyLog,
    isUrgent,
    tags,
  ];

  QueryEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? citizenId,
    String? citizenName,
    String? citizenEmail,
    String? muniId,
    QueryStatus? status,
    QueryCategory? category,
    QueryPriority? priority,
    List<String>? imageUrls,
    String? response,
    String? responderId,
    String? responderName,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? updatedAt,
    List<QueryHistoryItem>? historyLog,
    bool? isUrgent,
    List<String>? tags,
  }) {
    return QueryEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      citizenEmail: citizenEmail ?? this.citizenEmail,
      muniId: muniId ?? this.muniId,
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      imageUrls: imageUrls ?? this.imageUrls,
      response: response ?? this.response,
      responderId: responderId ?? this.responderId,
      responderName: responderName ?? this.responderName,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      historyLog: historyLog ?? this.historyLog,
      isUrgent: isUrgent ?? this.isUrgent,
      tags: tags ?? this.tags,
    );
  }

  // Métodos útiles
  bool get isAnswered => status == QueryStatus.answered;
  bool get isPending => status == QueryStatus.pending;
  bool get isOverdue => DateTime.now().difference(createdAt).inDays > 5 && !isAnswered;
  
  Duration? get responseTime {
    if (answeredAt == null) return null;
    return answeredAt!.difference(createdAt);
  }
}

enum QueryStatus {
  pending,
  inReview,
  answered,
  closed,
  escalated;

  String get displayName {
    switch (this) {
      case QueryStatus.pending:
        return 'Pendiente';
      case QueryStatus.inReview:
        return 'En Revisión';
      case QueryStatus.answered:
        return 'Respondida';
      case QueryStatus.closed:
        return 'Cerrada';
      case QueryStatus.escalated:
        return 'Escalada';
    }
  }

  String get description {
    switch (this) {
      case QueryStatus.pending:
        return 'Esperando respuesta del municipio';
      case QueryStatus.inReview:
        return 'Siendo revisada por el equipo';
      case QueryStatus.answered:
        return 'Respondida por el municipio';
      case QueryStatus.closed:
        return 'Consulta cerrada';
      case QueryStatus.escalated:
        return 'Escalada a nivel superior';
    }
  }
}

enum QueryCategory {
  general,
  services,
  infrastructure,
  security,
  environment,
  permits,
  complaints,
  suggestions;

  String get displayName {
    switch (this) {
      case QueryCategory.general:
        return 'General';
      case QueryCategory.services:
        return 'Servicios';
      case QueryCategory.infrastructure:
        return 'Infraestructura';
      case QueryCategory.security:
        return 'Seguridad';
      case QueryCategory.environment:
        return 'Medio Ambiente';
      case QueryCategory.permits:
        return 'Permisos';
      case QueryCategory.complaints:
        return 'Reclamos';
      case QueryCategory.suggestions:
        return 'Sugerencias';
    }
  }
}

enum QueryPriority {
  low,
  normal,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case QueryPriority.low:
        return 'Baja';
      case QueryPriority.normal:
        return 'Normal';
      case QueryPriority.high:
        return 'Alta';
      case QueryPriority.urgent:
        return 'Urgente';
    }
  }
}

class QueryHistoryItem extends Equatable {
  final DateTime timestamp;
  final QueryStatus status;
  final String? comment;
  final String? userId;
  final String? userName;
  final String? userRole;

  const QueryHistoryItem({
    required this.timestamp,
    required this.status,
    this.comment,
    this.userId,
    this.userName,
    this.userRole,
  });

  @override
  List<Object?> get props => [
    timestamp,
    status,
    comment,
    userId,
    userName,
    userRole,
  ];
}