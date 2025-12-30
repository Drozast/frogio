// lib/features/citizen/data/models/enhanced_report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ReportModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      references: data['references'],
      location: LocationDataModel.fromMap(data['location'] ?? {}).toEntity(),
      citizenId: data['citizenId'] ?? '',
      muniId: data['muniId'] ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => ReportStatus.draft,
      ),
      priority: Priority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => Priority.medium,
      ),
      attachments: (data['attachments'] as List<dynamic>?)
          ?.map((item) => MediaAttachmentModel.fromMap(item).toEntity())
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: (data['statusHistory'] as List<dynamic>?)
          ?.map((item) => StatusHistoryItemModel.fromMap(item).toEntity())
          .toList() ?? [],
      responses: (data['responses'] as List<dynamic>?)
          ?.map((item) => ReportResponseModel.fromMap(item).toEntity())
          .toList() ?? [],
      assignedToId: data['assignedToId'],
      assignedToName: data['assignedToName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'references': references,
      'location': LocationDataModel.fromEntity(location).toMap(),
      'citizenId': citizenId,
      'muniId': muniId,
      'status': status.name,
      'priority': priority.name,
      'attachments': attachments.map((item) => MediaAttachmentModel.fromEntity(item).toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'statusHistory': statusHistory.map((item) => StatusHistoryItemModel.fromEntity(item).toMap()).toList(),
      'responses': responses.map((item) => ReportResponseModel.fromEntity(item).toMap()).toList(),
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }
}

// Modelos auxiliares
class LocationDataModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? manualAddress;
  final LocationSource source;

  const LocationDataModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.manualAddress,
    required this.source,
  });

  factory LocationDataModel.fromMap(Map<String, dynamic> map) {
    return LocationDataModel(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: map['address'],
      manualAddress: map['manualAddress'],
      source: LocationSource.values.firstWhere(
        (source) => source.name == map['source'],
        orElse: () => LocationSource.manual,
      ),
    );
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

  LocationData toEntity() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      manualAddress: manualAddress,
      source: source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'manualAddress': manualAddress,
      'source': source.name,
    };
  }
}

class MediaAttachmentModel {
  final String id;
  final String url;
  final String fileName;
  final MediaType type;
  final int? fileSize;
  final DateTime uploadedAt;

  const MediaAttachmentModel({
    required this.id,
    required this.url,
    required this.fileName,
    required this.type,
    this.fileSize,
    required this.uploadedAt,
  });

  factory MediaAttachmentModel.fromMap(Map<String, dynamic> map) {
    return MediaAttachmentModel(
      id: map['id'] ?? '',
      url: map['url'] ?? '',
      fileName: map['fileName'] ?? '',
      type: MediaType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => MediaType.image,
      ),
      fileSize: map['fileSize'],
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
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

  MediaAttachment toEntity() {
    return MediaAttachment(
      id: id,
      url: url,
      fileName: fileName,
      type: type,
      fileSize: fileSize,
      uploadedAt: uploadedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'fileName': fileName,
      'type': type.name,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
    };
  }
}

class StatusHistoryItemModel {
  final DateTime timestamp;
  final ReportStatus status;
  final String? comment;
  final String? userId;
  final String? userName;

  const StatusHistoryItemModel({
    required this.timestamp,
    required this.status,
    this.comment,
    this.userId,
    this.userName,
  });

  factory StatusHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return StatusHistoryItemModel(
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      status: ReportStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ReportStatus.draft,
      ),
      comment: map['comment'],
      userId: map['userId'],
      userName: map['userName'],
    );
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

  StatusHistoryItem toEntity() {
    return StatusHistoryItem(
      timestamp: timestamp,
      status: status,
      comment: comment,
      userId: userId,
      userName: userName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'status': status.name,
      'comment': comment,
      'userId': userId,
      'userName': userName,
    };
  }
}

class ReportResponseModel {
  final String id;
  final String responderId;
  final String responderName;
  final String message;
  final List<MediaAttachment> attachments;
  final bool isPublic;
  final DateTime createdAt;

  const ReportResponseModel({
    required this.id,
    required this.responderId,
    required this.responderName,
    required this.message,
    required this.attachments,
    required this.isPublic,
    required this.createdAt,
  });

  factory ReportResponseModel.fromMap(Map<String, dynamic> map) {
    return ReportResponseModel(
      id: map['id'] ?? '',
      responderId: map['responderId'] ?? '',
      responderName: map['responderName'] ?? '',
      message: map['message'] ?? '',
      attachments: (map['attachments'] as List<dynamic>?)
          ?.map((item) => MediaAttachmentModel.fromMap(item).toEntity())
          .toList() ?? [],
      isPublic: map['isPublic'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
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

  ReportResponse toEntity() {
    return ReportResponse(
      id: id,
      responderId: responderId,
      responderName: responderName,
      message: message,
      attachments: attachments,
      isPublic: isPublic,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'responderId': responderId,
      'responderName': responderName,
      'message': message,
      'attachments': attachments.map((item) => MediaAttachmentModel.fromEntity(item).toMap()).toList(),
      'isPublic': isPublic,
      'createdAt': createdAt,
    };
  }
}