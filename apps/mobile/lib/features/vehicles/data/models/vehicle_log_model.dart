// lib/features/vehicles/data/models/vehicle_log_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/vehicle_log_entity.dart';

class VehicleLogModel extends Equatable {
  final String id;
  final String vehicleId;
  final String driverId;
  final String driverName;
  final double startKm;
  final double? endKm;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LocationPointModel> route;
  final String? observations;
  final String usageType;
  final String? purpose;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleLogModel({
    required this.id,
    required this.vehicleId,
    required this.driverId,
    required this.driverName,
    required this.startKm,
    this.endKm,
    required this.startTime,
    this.endTime,
    required this.route,
    this.observations,
    required this.usageType,
    this.purpose,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleLogModel.fromJson(Map<String, dynamic> json) {
    return VehicleLogModel(
      id: json['id'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      driverId: json['driverId'] ?? '',
      driverName: json['driverName'] ?? '',
      startKm: (json['startKm'] ?? 0).toDouble(),
      endKm: json['endKm'] != null ? (json['endKm']).toDouble() : null,
      startTime: json['startTime'] is Timestamp
          ? (json['startTime'] as Timestamp).toDate()
          : DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] != null
          ? json['endTime'] is Timestamp
              ? (json['endTime'] as Timestamp).toDate()
              : DateTime.parse(json['endTime'])
          : null,
      route: json['route'] != null
          ? (json['route'] as List)
              .map((item) => LocationPointModel.fromMap(item as Map<String, dynamic>))
              .toList()
          : <LocationPointModel>[],
      observations: json['observations'],
      usageType: json['usageType'] ?? 'other',
      purpose: json['purpose'],
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory VehicleLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleLogModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'driverName': driverName,
      'startKm': startKm,
      'endKm': endKm,
      'startTime': startTime,
      'endTime': endTime,
      'route': route.map((point) => point.toMap()).toList(),
      'observations': observations,
      'usageType': usageType,
      'purpose': purpose,
      'attachments': attachments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vehicleId': vehicleId,
      'driverId': driverId,
      'driverName': driverName,
      'startKm': startKm,
      'endKm': endKm,
      'startTime': startTime,
      'endTime': endTime,
      'route': route.map((point) => point.toMap()).toList(),
      'observations': observations,
      'usageType': usageType,
      'purpose': purpose,
      'attachments': attachments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  VehicleLogEntity toEntity() {
    return VehicleLogEntity(
      id: id,
      vehicleId: vehicleId,
      driverId: driverId,
      driverName: driverName,
      startKm: startKm,
      endKm: endKm,
      startTime: startTime,
      endTime: endTime,
      route: route.map((point) => point.toEntity()).toList(),
      observations: observations,
      usageType: UsageType.values.firstWhere(
        (type) => type.name == usageType,
        orElse: () => UsageType.other,
      ),
      purpose: purpose,
      attachments: attachments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory VehicleLogModel.fromEntity(VehicleLogEntity entity) {
    return VehicleLogModel(
      id: entity.id,
      vehicleId: entity.vehicleId,
      driverId: entity.driverId,
      driverName: entity.driverName,
      startKm: entity.startKm,
      endKm: entity.endKm,
      startTime: entity.startTime,
      endTime: entity.endTime,
      route: entity.route.map((point) => LocationPointModel.fromEntity(point)).toList(),
      observations: entity.observations,
      usageType: entity.usageType.name,
      purpose: entity.purpose,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        driverId,
        driverName,
        startKm,
        endKm,
        startTime,
        endTime,
        route,
        observations,
        usageType,
        purpose,
        attachments,
        createdAt,
        updatedAt,
      ];
}

class LocationPointModel extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  const LocationPointModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  factory LocationPointModel.fromMap(Map<String, dynamic> map) {
    return LocationPointModel(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      speed: map['speed']?.toDouble(),
      accuracy: map['accuracy']?.toDouble(),
    );
  }

  factory LocationPointModel.fromEntity(LocationPoint entity) {
    return LocationPointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      speed: entity.speed,
      accuracy: entity.accuracy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  LocationPoint toEntity() {
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      speed: speed,
      accuracy: accuracy,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp, speed, accuracy];
}