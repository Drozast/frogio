import 'package:equatable/equatable.dart';

import '../../domain/entities/query_entity.dart';

class QueryModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String citizenId;
  final String muniId;
  final String status;
  final String? response;
  final String? responderId;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? answeredAt;

  const QueryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.citizenId,
    required this.muniId,
    required this.status,
    this.response,
    this.responderId,
    required this.imageUrls,
    required this.createdAt,
    this.answeredAt,
  });

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    return QueryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      citizenId: json['citizenId'] ?? '',
      muniId: json['muniId'] ?? '',
      status: json['status'] ?? 'pending',
      response: json['response'],
      responderId: json['responderId'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      createdAt: (json['createdAt'] as dynamic).toDate() ?? DateTime.now(),
      answeredAt: json['answeredAt'] != null
          ? (json['answeredAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'citizenId': citizenId,
      'muniId': muniId,
      'status': status,
      'response': response,
      'responderId': responderId,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'answeredAt': answeredAt,
    };
  }

  // Método auxiliar para convertir String a QueryStatus enum
  QueryStatus _getQueryStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'pending':
        return QueryStatus.pending;
      case 'answered':
        return QueryStatus.answered;
      case 'in_progress':
        return QueryStatus.answered; // Mapear a answered si no existe inProgress
      case 'resolved':
        return QueryStatus.answered; // Mapear a answered si no existe resolved
      case 'cancelled':
        return QueryStatus.pending; // Mapear a pending si no existe cancelled
      default:
        return QueryStatus.pending;
    }
  }

  QueryEntity toEntity() {
    return QueryEntity(
      id: id,
      title: title,
      description: description,
      citizenId: citizenId,
      muniId: muniId,
      status: _getQueryStatus(status), // Convertir String a QueryStatus enum
      response: response,
      responderId: responderId,
      imageUrls: imageUrls,
      createdAt: createdAt,
      answeredAt: answeredAt,
      citizenName: '', // Valor por defecto
      citizenEmail: '', // Valor por defecto
      category: QueryCategory.general, // Cambiar según las constantes disponibles en tu enum
      priority: QueryPriority.low, // Cambiar según las constantes disponibles en tu enum
      updatedAt: answeredAt ?? createdAt, // Usar answeredAt o createdAt como fallback
      historyLog: const [], // Lista vacía const
      isUrgent: false, // Valor por defecto
      tags: const [], // Lista vacía const
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        citizenId,
        muniId,
        status,
        response,
        responderId,
        imageUrls,
        createdAt,
        answeredAt,
      ];
}