// lib/features/vehicles/data/models/vehicle_model.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/vehicle_entity.dart';

class VehicleModel extends Equatable {
  final String id;
  final String plate;
  final String brand;
  final String model;
  final int year;
  final VehicleType type;
  final VehicleStatus status;
  final double currentKm;
  final String muniId;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String? currentDriverId;
  final String? currentDriverName;
  final List<String> assignedAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VehicleSpecs specs;

  const VehicleModel({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.type,
    required this.status,
    required this.currentKm,
    required this.muniId,
    this.lastMaintenance,
    this.nextMaintenance,
    this.currentDriverId,
    this.currentDriverName,
    required this.assignedAreas,
    required this.createdAt,
    required this.updatedAt,
    required this.specs,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      type: _parseVehicleType(json['type'] as String?),
      status: _parseVehicleStatus(json['status'] as String?),
      currentKm: (json['currentKm'] as num?)?.toDouble() ?? 0.0,
      muniId: json['muniId'] as String? ?? json['tenantId'] as String? ?? '',
      lastMaintenance: json['lastMaintenance'] != null
          ? DateTime.parse(json['lastMaintenance'].toString())
          : null,
      nextMaintenance: json['nextMaintenance'] != null
          ? DateTime.parse(json['nextMaintenance'].toString())
          : null,
      currentDriverId: json['currentDriverId'] as String?,
      currentDriverName: json['currentDriverName'] as String?,
      assignedAreas: (json['assignedAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      specs: VehicleSpecsModel.fromJson(
          json['specs'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'brand': brand,
      'model': model,
      'year': year,
      'type': type.name,
      'status': status.name,
      'currentKm': currentKm,
      'muniId': muniId,
      'lastMaintenance': lastMaintenance?.toIso8601String(),
      'nextMaintenance': nextMaintenance?.toIso8601String(),
      'currentDriverId': currentDriverId,
      'currentDriverName': currentDriverName,
      'assignedAreas': assignedAreas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'specs': VehicleSpecsModel.fromSpecs(specs).toJson(),
    };
  }

  VehicleEntity toEntity() {
    return VehicleEntity(
      id: id,
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      type: type,
      status: status,
      currentKm: currentKm,
      muniId: muniId,
      lastMaintenance: lastMaintenance,
      nextMaintenance: nextMaintenance,
      currentDriverId: currentDriverId,
      currentDriverName: currentDriverName,
      assignedAreas: assignedAreas,
      createdAt: createdAt,
      updatedAt: updatedAt,
      specs: specs,
    );
  }

  static VehicleStatus _parseVehicleStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'available':
        return VehicleStatus.available;
      case 'in_use':
      case 'inuse':
        return VehicleStatus.inUse;
      case 'maintenance':
        return VehicleStatus.maintenance;
      case 'out_of_service':
      case 'outofservice':
        return VehicleStatus.outOfService;
      default:
        return VehicleStatus.available;
    }
  }

  static VehicleType _parseVehicleType(String? type) {
    switch (type?.toLowerCase()) {
      case 'car':
        return VehicleType.car;
      case 'motorcycle':
        return VehicleType.motorcycle;
      case 'truck':
        return VehicleType.truck;
      case 'van':
        return VehicleType.van;
      case 'bicycle':
        return VehicleType.bicycle;
      default:
        return VehicleType.car;
    }
  }

  factory VehicleModel.fromEntity(VehicleEntity entity) {
    return VehicleModel(
      id: entity.id,
      plate: entity.plate,
      brand: entity.brand,
      model: entity.model,
      year: entity.year,
      type: entity.type,
      status: entity.status,
      currentKm: entity.currentKm,
      muniId: entity.muniId,
      lastMaintenance: entity.lastMaintenance,
      nextMaintenance: entity.nextMaintenance,
      currentDriverId: entity.currentDriverId,
      currentDriverName: entity.currentDriverName,
      assignedAreas: entity.assignedAreas,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      specs: entity.specs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        plate,
        brand,
        model,
        year,
        type,
        status,
        currentKm,
        muniId,
        lastMaintenance,
        nextMaintenance,
        currentDriverId,
        currentDriverName,
        assignedAreas,
        createdAt,
        updatedAt,
        specs,
      ];
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

  factory VehicleSpecsModel.fromJson(Map<String, dynamic> json) {
    return VehicleSpecsModel(
      color: json['color'] as String?,
      engine: json['engine'] as String?,
      transmission: json['transmission'] as String?,
      fuelType: json['fuelType'] as String?,
      fuelCapacity: (json['fuelCapacity'] as num?)?.toDouble(),
      seatingCapacity: json['seatingCapacity'] as int?,
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
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

  factory VehicleSpecsModel.fromSpecs(VehicleSpecs specs) {
    return VehicleSpecsModel(
      color: specs.color,
      engine: specs.engine,
      transmission: specs.transmission,
      fuelType: specs.fuelType,
      fuelCapacity: specs.fuelCapacity,
      seatingCapacity: specs.seatingCapacity,
      additionalInfo: specs.additionalInfo,
    );
  }
}
