// lib/features/vehicles/domain/entities/vehicle_log_entity.dart
import 'package:equatable/equatable.dart';

class VehicleLogEntity extends Equatable {
  final String id;
  final String vehicleId;
  final String driverId;
  final String driverName;
  final double startKm;
  final double? endKm;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LocationPoint> route;
  final String? observations;
  final UsageType usageType;
  final String? purpose;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleLogEntity({
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

  @override
  List<Object?> get props => [
    id, vehicleId, driverId, driverName, startKm, endKm,
    startTime, endTime, route, observations, usageType,
    purpose, attachments, createdAt, updatedAt,
  ];

  bool get isActive => endTime == null;
  
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
  
  double? get distanceTraveled {
    if (endKm == null) return null;
    return endKm! - startKm;
  }

  VehicleLogEntity copyWith({
    String? id,
    String? vehicleId,
    String? driverId,
    String? driverName,
    double? startKm,
    double? endKm,
    DateTime? startTime,
    DateTime? endTime,
    List<LocationPoint>? route,
    String? observations,
    UsageType? usageType,
    String? purpose,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleLogEntity(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      startKm: startKm ?? this.startKm,
      endKm: endKm ?? this.endKm,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      route: route ?? this.route,
      observations: observations ?? this.observations,
      usageType: usageType ?? this.usageType,
      purpose: purpose ?? this.purpose,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum UsageType {
  patrol,
  emergency,
  maintenance,
  transport,
  other;

  String get displayName {
    switch (this) {
      case UsageType.patrol:
        return 'Patrullaje';
      case UsageType.emergency:
        return 'Emergencia';
      case UsageType.maintenance:
        return 'Mantenimiento';
      case UsageType.transport:
        return 'Transporte';
      case UsageType.other:
        return 'Otro';
    }
  }
}

class LocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, timestamp, speed, accuracy];

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? accuracy,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}