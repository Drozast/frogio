// lib/features/vehicles/data/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.plate,
    required super.model,
    required super.brand,
    required super.year,
    required super.muniId,
    required super.status,
    required super.type,
    required super.currentKm,
    super.lastMaintenance,
    super.nextMaintenance,
    super.currentDriverId,
    super.currentDriverName,
    required super.assignedAreas,
    required super.createdAt,
    required super.updatedAt,
    required super.specs,
  });

  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VehicleModel(
      id: doc.id,
      plate: data['plate'] ?? '',
      model: data['model'] ?? '',
      brand: data['brand'] ?? '',
      year: data['year']?.toInt() ?? DateTime.now().year,
      muniId: data['muniId'] ?? '',
      status: VehicleStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => VehicleStatus.available,
      ),
      type: VehicleType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => VehicleType.car,
      ),
      currentKm: (data['currentKm'] ?? 0).toDouble(),
      lastMaintenance: (data['lastMaintenance'] as Timestamp?)?.toDate(),
      nextMaintenance: (data['nextMaintenance'] as Timestamp?)?.toDate(),
      currentDriverId: data['currentDriverId'],
      currentDriverName: data['currentDriverName'],
      assignedAreas: List<String>.from(data['assignedAreas'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      specs: VehicleSpecsModel.fromMap(data['specs'] ?? {}),
    );
  }

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] ?? '',
      plate: map['plate'] ?? '',
      model: map['model'] ?? '',
      brand: map['brand'] ?? '',
      year: map['year']?.toInt() ?? DateTime.now().year,
      muniId: map['muniId'] ?? '',
      status: VehicleStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => VehicleStatus.available,
      ),
      type: VehicleType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => VehicleType.car,
      ),
      currentKm: (map['currentKm'] ?? 0).toDouble(),
      lastMaintenance: map['lastMaintenance'] is Timestamp
          ? (map['lastMaintenance'] as Timestamp).toDate()
          : map['lastMaintenance'] != null
              ? DateTime.parse(map['lastMaintenance'])
              : null,
      nextMaintenance: map['nextMaintenance'] is Timestamp
          ? (map['nextMaintenance'] as Timestamp).toDate()
          : map['nextMaintenance'] != null
              ? DateTime.parse(map['nextMaintenance'])
              : null,
      currentDriverId: map['currentDriverId'],
      currentDriverName: map['currentDriverName'],
      assignedAreas: List<String>.from(map['assignedAreas'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      specs: VehicleSpecsModel.fromMap(map['specs'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plate': plate,
      'model': model,
      'brand': brand,
      'year': year,
      'muniId': muniId,
      'status': status.name,
      'type': type.name,
      'currentKm': currentKm,
      'lastMaintenance': lastMaintenance,
      'nextMaintenance': nextMaintenance,
      'currentDriverId': currentDriverId,
      'currentDriverName': currentDriverName,
      'assignedAreas': assignedAreas,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'specs': (specs as VehicleSpecsModel).toMap(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plate': plate,
      'model': model,
      'brand': brand,
      'year': year,
      'muniId': muniId,
      'status': status.name,
      'type': type.name,
      'currentKm': currentKm,
      'lastMaintenance': lastMaintenance?.toIso8601String(),
      'nextMaintenance': nextMaintenance?.toIso8601String(),
      'currentDriverId': currentDriverId,
      'currentDriverName': currentDriverName,
      'assignedAreas': assignedAreas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'specs': (specs as VehicleSpecsModel).toMap(),
    };
  }
}

class VehicleSpecsModel extends VehicleSpecs {
  const VehicleSpecsModel({
    super.color,
    super.engine,
    super.transmission,
    super.fuelType,
    super.fuelCapacity,
    super.seatingCapacity,
    super.additionalInfo,
  });

  factory VehicleSpecsModel.fromMap(Map<String, dynamic> map) {
    return VehicleSpecsModel(
      color: map['color'],
      engine: map['engine'],
      transmission: map['transmission'],
      fuelType: map['fuelType'],
      fuelCapacity: map['fuelCapacity']?.toDouble(),
      seatingCapacity: map['seatingCapacity']?.toInt(),
      additionalInfo: map['additionalInfo'] != null 
          ? Map<String, dynamic>.from(map['additionalInfo'])
          : null,
    );
  }

  factory VehicleSpecsModel.fromEntity(VehicleSpecs entity) {
    return VehicleSpecsModel(
      color: entity.color,
      engine: entity.engine,
      transmission: entity.transmission,
      fuelType: entity.fuelType,
      fuelCapacity: entity.fuelCapacity,
      seatingCapacity: entity.seatingCapacity,
      additionalInfo: entity.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'engine': engine,
      'transmission': transmission,
      'fuelType': fuelType,
      'fuelCapacity': fuelCapacity,
      'seatingCapacity': seatingCapacity,
      'additionalInfo': additionalInfo,
    };
  }
}

class VehicleLogModel extends VehicleLogEntity {
  const VehicleLogModel({
    required super.id,
    required super.vehicleId,
    required super.driverId,
    required super.driverName,
    required super.startKm,
    super.endKm,
    required super.startTime,
    super.endTime,
    required super.route,
    super.observations,
    required super.usageType,
    super.purpose,
    required super.attachments,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VehicleLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VehicleLogModel(
      id: doc.id,
      vehicleId: data['vehicleId'] ?? '',
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      startKm: (data['startKm'] ?? 0).toDouble(),
      endKm: data['endKm']?.toDouble(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      route: _parseRoute(data['route']),
      observations: data['observations'],
      usageType: UsageType.values.firstWhere(
        (type) => type.name == data['usageType'],
        orElse: () => UsageType.other,
      ),
      purpose: data['purpose'],
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory VehicleLogModel.fromMap(Map<String, dynamic> map) {
    return VehicleLogModel(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      startKm: (map['startKm'] ?? 0).toDouble(),
      endKm: map['endKm']?.toDouble(),
      startTime: map['startTime'] is Timestamp
          ? (map['startTime'] as Timestamp).toDate()
          : DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: map['endTime'] is Timestamp
          ? (map['endTime'] as Timestamp).toDate()
          : map['endTime'] != null
              ? DateTime.parse(map['endTime'])
              : null,
      route: _parseRoute(map['route']),
      observations: map['observations'],
      usageType: UsageType.values.firstWhere(
        (type) => type.name == map['usageType'],
        orElse: () => UsageType.other,
      ),
      purpose: map['purpose'],
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
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
      'route': route.map((point) => LocationPointModel.fromEntity(point).toMap()).toList(),
      'observations': observations,
      'usageType': usageType.name,
      'purpose': purpose,
      'attachments': attachments,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'driverName': driverName,
      'startKm': startKm,
      'endKm': endKm,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'route': route.map((point) => LocationPointModel.fromEntity(point).toMap()).toList(),
      'observations': observations,
      'usageType': usageType.name,
      'purpose': purpose,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<LocationPoint> _parseRoute(dynamic routeData) {
    if (routeData == null) return [];
    
    return (routeData as List)
        .map((data) => LocationPointModel.fromMap(data as Map<String, dynamic>))
        .toList();
  }
}

class LocationPointModel extends LocationPoint {
  const LocationPointModel({
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    super.speed,
    super.accuracy,
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
}