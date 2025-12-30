// lib/features/citizen/data/models/report_model.dart
import '../../domain/entities/enhanced_report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    super.references,
    required super.location,
    required super.citizenId,
    required super.muniId,
    required super.status,
    required super.priority,
    required super.attachments,
    required super.createdAt,
    required super.updatedAt,
    required super.statusHistory,
    required super.responses,
    super.assignedToId,
    super.assignedToName,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sin titulo',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      references: json['references'] as String?,
      location: LocationDataModel.fromJson(
        json['location'] as Map<String, dynamic>? ?? {
          'latitude': json['latitude'] ?? 0.0,
          'longitude': json['longitude'] ?? 0.0,
          'address': json['address'],
        },
      ),
      citizenId: json['citizenId'] as String? ?? json['userId'] as String? ?? '',
      muniId: json['muniId'] as String? ?? json['tenantId'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      priority: _parsePriority(json['priority'] as String?),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MediaAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      responses: (json['responses'] as List<dynamic>?)
              ?.map((e) => ReportResponseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignedToId: json['assignedToId'] as String?,
      assignedToName: json['assignedToName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'references': references,
      'location': LocationDataModel.fromEntity(location).toJson(),
      'citizenId': citizenId,
      'muniId': muniId,
      'status': status.name,
      'priority': priority.name,
      'attachments': attachments
          .map((e) => MediaAttachmentModel.fromEntity(e).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'statusHistory': statusHistory
          .map((e) => StatusHistoryItemModel.fromEntity(e).toJson())
          .toList(),
      'responses': responses
          .map((e) => ReportResponseModel.fromEntity(e).toJson())
          .toList(),
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }

  static ReportStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return ReportStatus.draft;
      case 'submitted':
        return ReportStatus.submitted;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'in_progress':
      case 'inprogress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      case 'archived':
        return ReportStatus.archived;
      default:
        return ReportStatus.submitted;
    }
  }

  static Priority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      case 'urgent':
        return Priority.urgent;
      default:
        return Priority.medium;
    }
  }

  factory ReportModel.fromEntity(ReportEntity entity) {
    return ReportModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      references: entity.references,
      location: entity.location,
      citizenId: entity.citizenId,
      muniId: entity.muniId,
      status: entity.status,
      priority: entity.priority,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      statusHistory: entity.statusHistory,
      responses: entity.responses,
      assignedToId: entity.assignedToId,
      assignedToName: entity.assignedToName,
    );
  }

  /// Create model from REST API response (alias for fromJson)
  factory ReportModel.fromApi(Map<String, dynamic> json) => ReportModel.fromJson(json);
}

class LocationDataModel extends LocationData {
  const LocationDataModel({
    required super.latitude,
    required super.longitude,
    super.address,
    super.manualAddress,
    required super.source,
  });

  factory LocationDataModel.fromJson(Map<String, dynamic> json) {
    return LocationDataModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      manualAddress: json['manualAddress'] as String?,
      source: _parseSource(json['source'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'manualAddress': manualAddress,
      'source': source.name,
    };
  }

  static LocationSource _parseSource(String? source) {
    switch (source?.toLowerCase()) {
      case 'gps':
        return LocationSource.gps;
      case 'map':
        return LocationSource.map;
      case 'manual':
        return LocationSource.manual;
      default:
        return LocationSource.gps;
    }
  }

  factory LocationDataModel.fromEntity(LocationData entity) {
    return LocationDataModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      manualAddress: entity.manualAddress,
      source: entity.source,
    );
  }
}

class MediaAttachmentModel extends MediaAttachment {
  const MediaAttachmentModel({
    required super.id,
    required super.url,
    required super.fileName,
    required super.type,
    super.fileSize,
    required super.uploadedAt,
  });

  factory MediaAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MediaAttachmentModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'file',
      type: (json['type'] as String?)?.toLowerCase() == 'video'
          ? MediaType.video
          : MediaType.image,
      fileSize: json['fileSize'] as int?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'type': type.name,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory MediaAttachmentModel.fromEntity(MediaAttachment entity) {
    return MediaAttachmentModel(
      id: entity.id,
      url: entity.url,
      fileName: entity.fileName,
      type: entity.type,
      fileSize: entity.fileSize,
      uploadedAt: entity.uploadedAt,
    );
  }
}

class StatusHistoryItemModel extends StatusHistoryItem {
  const StatusHistoryItemModel({
    required super.timestamp,
    required super.status,
    super.comment,
    super.userId,
    super.userName,
  });

  factory StatusHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItemModel(
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      status: ReportModel._parseStatus(json['status'] as String?),
      comment: json['comment'] as String?,
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'comment': comment,
      'userId': userId,
      'userName': userName,
    };
  }

  factory StatusHistoryItemModel.fromEntity(StatusHistoryItem entity) {
    return StatusHistoryItemModel(
      timestamp: entity.timestamp,
      status: entity.status,
      comment: entity.comment,
      userId: entity.userId,
      userName: entity.userName,
    );
  }
}

class ReportResponseModel extends ReportResponse {
  const ReportResponseModel({
    required super.id,
    required super.responderId,
    required super.responderName,
    required super.message,
    required super.attachments,
    required super.isPublic,
    required super.createdAt,
  });

  factory ReportResponseModel.fromJson(Map<String, dynamic> json) {
    return ReportResponseModel(
      id: json['id'] as String? ?? '',
      responderId: json['responderId'] as String? ?? '',
      responderName: json['responderName'] as String? ?? 'Usuario',
      message: json['message'] as String? ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MediaAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'responderId': responderId,
      'responderName': responderName,
      'message': message,
      'attachments': attachments
          .map((e) => MediaAttachmentModel.fromEntity(e).toJson())
          .toList(),
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportResponseModel.fromEntity(ReportResponse entity) {
    return ReportResponseModel(
      id: entity.id,
      responderId: entity.responderId,
      responderName: entity.responderName,
      message: entity.message,
      attachments: entity.attachments,
      isPublic: entity.isPublic,
      createdAt: entity.createdAt,
    );
  }
}
