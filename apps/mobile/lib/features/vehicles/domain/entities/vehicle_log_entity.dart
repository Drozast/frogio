// lib/features/vehicles/domain/entities/vehicle_log_entity.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class VehicleLogEntity extends Equatable {
  final String id;
  final String vehicleId;
  final String vehiclePlate;
  final String driverId;
  final String driverName;
  final double startKm;
  final double? endKm;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LocationPoint> route;
  final List<TripStop> stops;
  final String? observations;
  final UsageType usageType;
  final String? purpose;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleLogEntity({
    required this.id,
    required this.vehicleId,
    this.vehiclePlate = '',
    required this.driverId,
    required this.driverName,
    required this.startKm,
    this.endKm,
    required this.startTime,
    this.endTime,
    required this.route,
    this.stops = const [],
    this.observations,
    required this.usageType,
    this.purpose,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id, vehicleId, vehiclePlate, driverId, driverName, startKm, endKm,
    startTime, endTime, route, stops, observations, usageType,
    purpose, attachments, createdAt, updatedAt,
  ];

  /// Total de tiempo detenido durante el viaje
  Duration get totalStopTime {
    return stops.fold(Duration.zero, (total, stop) {
      if (stop.duration != null) {
        return total + stop.duration!;
      }
      return total;
    });
  }

  /// Distancia total recorrida calculada desde la ruta GPS
  double get calculatedDistance {
    if (route.length < 2) return 0;

    double total = 0;
    for (int i = 1; i < route.length; i++) {
      total += _calculateDistance(
        route[i - 1].latitude, route[i - 1].longitude,
        route[i].latitude, route[i].longitude,
      );
    }
    return total;
  }

  /// Calcula distancia entre dos puntos en km usando la fórmula de Haversine
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        (1 - (dLat / 2).abs().clamp(-1.0, 1.0)) / 2 +
        (lat1 * 3.14159 / 180).abs().clamp(-1.0, 1.0) *
        (lat2 * 3.14159 / 180).abs().clamp(-1.0, 1.0) *
        (1 - (dLon / 2).abs().clamp(-1.0, 1.0)) / 2;

    return earthRadius * 2 * a.clamp(0, 1);
  }

  double _toRadians(double degrees) => degrees * 3.14159 / 180;

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
    String? vehiclePlate,
    String? driverId,
    String? driverName,
    double? startKm,
    double? endKm,
    DateTime? startTime,
    DateTime? endTime,
    List<LocationPoint>? route,
    List<TripStop>? stops,
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
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      startKm: startKm ?? this.startKm,
      endKm: endKm ?? this.endKm,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      route: route ?? this.route,
      stops: stops ?? this.stops,
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

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
    );
  }
}

/// Representa una parada durante el viaje
class TripStop extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime startTime;
  final DateTime? endTime;
  final StopReason reason;
  final String? details;

  const TripStop({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.startTime,
    this.endTime,
    required this.reason,
    this.details,
  });

  @override
  List<Object?> get props => [
    id, latitude, longitude, address, startTime, endTime, reason, details
  ];

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  TripStop copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? startTime,
    DateTime? endTime,
    StopReason? reason,
    String? details,
  }) {
    return TripStop(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'reason': reason.name,
      'details': details,
    };
  }

  factory TripStop.fromJson(Map<String, dynamic> json) {
    return TripStop(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      reason: StopReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => StopReason.other,
      ),
      details: json['details'] as String?,
    );
  }
}

enum StopReason {
  inspection,
  citation,
  break_,
  fuel,
  maintenance,
  citizen,
  emergency,
  other;

  String get displayName {
    switch (this) {
      case StopReason.inspection:
        return 'Inspección';
      case StopReason.citation:
        return 'Citación';
      case StopReason.break_:
        return 'Descanso';
      case StopReason.fuel:
        return 'Combustible';
      case StopReason.maintenance:
        return 'Mantenimiento';
      case StopReason.citizen:
        return 'Atención Ciudadano';
      case StopReason.emergency:
        return 'Emergencia';
      case StopReason.other:
        return 'Otro';
    }
  }

  IconData get icon {
    switch (this) {
      case StopReason.inspection:
        return Icons.search;
      case StopReason.citation:
        return Icons.assignment;
      case StopReason.break_:
        return Icons.coffee;
      case StopReason.fuel:
        return Icons.local_gas_station;
      case StopReason.maintenance:
        return Icons.build;
      case StopReason.citizen:
        return Icons.person;
      case StopReason.emergency:
        return Icons.emergency;
      case StopReason.other:
        return Icons.more_horiz;
    }
  }
}