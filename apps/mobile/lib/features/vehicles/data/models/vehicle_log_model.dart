// lib/features/vehicles/data/models/vehicle_log_model.dart
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
  final UsageType usageType;
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
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      driverId: json['driverId'] as String? ?? '',
      driverName: json['driverName'] as String? ?? '',
      startKm: (json['startKm'] as num?)?.toDouble() ?? 0.0,
      endKm: (json['endKm'] as num?)?.toDouble(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'].toString())
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'].toString())
          : null,
      route: (json['route'] as List<dynamic>?)
              ?.map((e) => LocationPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      observations: json['observations'] as String?,
      usageType: _parseUsageType(json['usageType'] as String?),
      purpose: json['purpose'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'driverName': driverName,
      'startKm': startKm,
      'endKm': endKm,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'route': route.map((e) => e.toJson()).toList(),
      'observations': observations,
      'usageType': usageType.name,
      'purpose': purpose,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
      route: route.map((e) => e.toEntity()).toList(),
      observations: observations,
      usageType: usageType,
      purpose: purpose,
      attachments: attachments,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static UsageType _parseUsageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'patrol':
        return UsageType.patrol;
      case 'emergency':
        return UsageType.emergency;
      case 'maintenance':
        return UsageType.maintenance;
      case 'transport':
        return UsageType.transport;
      default:
        return UsageType.other;
    }
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
      route: entity.route.map((e) => LocationPointModel.fromEntity(e)).toList(),
      observations: entity.observations,
      usageType: entity.usageType,
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

  factory LocationPointModel.fromJson(Map<String, dynamic> json) {
    return LocationPointModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      speed: (json['speed'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
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

  factory LocationPointModel.fromEntity(LocationPoint entity) {
    return LocationPointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      timestamp: entity.timestamp,
      speed: entity.speed,
      accuracy: entity.accuracy,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp, speed, accuracy];
}
