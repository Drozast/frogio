// lib/features/citizen/domain/entities/report_entity.dart
import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final LocationData location;
  final String citizenId;
  final String muniId;
  final String status;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<HistoryLogItem> historyLog;

  const ReportEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.citizenId,
    required this.muniId,
    required this.status,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    required this.historyLog,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        location,
        citizenId,
        muniId,
        status,
        imageUrls,
        createdAt,
        updatedAt,
        historyLog,
      ];
}

class LocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

class HistoryLogItem extends Equatable {
  final DateTime timestamp;
  final String status;
  final String? comment;
  final String? userId;

  const HistoryLogItem({
    required this.timestamp,
    required this.status,
    this.comment,
    this.userId,
  });

  @override
  List<Object?> get props => [timestamp, status, comment, userId];
}