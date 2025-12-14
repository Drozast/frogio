// lib/features/citizen/data/models/report_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.location,
    required super.citizenId,
    required super.muniId,
    required super.status,
    required super.imageUrls,
    required super.createdAt,
    required super.updatedAt,
    required super.historyLog,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Ubicación
    final locationData = data['location'] as Map<String, dynamic>;
    final location = LocationData(
      latitude: locationData['latitude'] ?? 0.0,
      longitude: locationData['longitude'] ?? 0.0,
      address: locationData['address'],
    );
    
    // Historial
    final historyList = (data['historyLog'] as List<dynamic>?)?.map((historyItem) {
      final item = historyItem as Map<String, dynamic>;
      return HistoryLogItem(
        timestamp: (item['timestamp'] as Timestamp).toDate(),
        status: item['status'],
        comment: item['comment'],
        userId: item['userId'],
      );
    }).toList() ?? [];
    
    return ReportModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: location,
      citizenId: data['citizenId'] ?? '',
      muniId: data['muniId'] ?? '',
      status: data['status'] ?? 'Pendiente',
      imageUrls: List<String>.from(data['images'] ?? []),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      historyLog: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
      },
      'citizenId': citizenId,
      'muniId': muniId,
      'status': status,
      'images': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'historyLog': historyLog.map((item) => {
        'timestamp': item.timestamp,
        'status': item.status,
        'comment': item.comment,
        'userId': item.userId,
      }).toList(),
    };
  }
}