// lib/features/vehicles/domain/entities/vehicle_entity.dart
import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
  final String id;
  final String plate;
  final String model;
  final String brand;
  final int year;
  final String muniId;
  final VehicleStatus status;
  final VehicleType type;
  final double currentKm;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final String? currentDriverId;
  final String? currentDriverName;
  final List<String> assignedAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final VehicleSpecs specs;

  const VehicleEntity({
    required this.id,
    required this.plate,
    required this.model,
    required this.brand,
    required this.year,
    required this.muniId,
    required this.status,
    required this.type,
    required this.currentKm,
    this.lastMaintenance,
    this.nextMaintenance,
    this.currentDriverId,
    this.currentDriverName,
    required this.assignedAreas,
    required this.createdAt,
    required this.updatedAt,
    required this.specs,
  });

  @override
  List<Object?> get props => [
    id, plate, model, brand, year, muniId, status, type, currentKm,
    lastMaintenance, nextMaintenance, currentDriverId, currentDriverName,
    assignedAreas, createdAt, updatedAt, specs,
  ];

  VehicleEntity copyWith({
    String? id,
    String? plate,
    String? model,
    String? brand,
    int? year,
    String? muniId,
    VehicleStatus? status,
    VehicleType? type,
    double? currentKm,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    String? currentDriverId,
    String? currentDriverName,
    List<String>? assignedAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
    VehicleSpecs? specs,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      year: year ?? this.year,
      muniId: muniId ?? this.muniId,
      status: status ?? this.status,
      type: type ?? this.type,
      currentKm: currentKm ?? this.currentKm,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      currentDriverName: currentDriverName ?? this.currentDriverName,
      assignedAreas: assignedAreas ?? this.assignedAreas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      specs: specs ?? this.specs,
    );
  }

  bool get isAvailable => status == VehicleStatus.available;
  bool get isInUse => status == VehicleStatus.inUse;
  bool get needsMaintenance => 
      nextMaintenance != null && DateTime.now().isAfter(nextMaintenance!);
}

enum VehicleStatus {
  available,
  inUse,
  maintenance,
  outOfService;

  String get displayName {
    switch (this) {
      case VehicleStatus.available:
        return 'Disponible';
      case VehicleStatus.inUse:
        return 'En Uso';
      case VehicleStatus.maintenance:
        return 'En Mantenimiento';
      case VehicleStatus.outOfService:
        return 'Fuera de Servicio';
    }
  }
}

enum VehicleType {
  car,
  motorcycle,
  truck,
  van,
  bicycle;

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Automóvil';
      case VehicleType.motorcycle:
        return 'Motocicleta';
      case VehicleType.truck:
        return 'Camión';
      case VehicleType.van:
        return 'Furgoneta';
      case VehicleType.bicycle:
        return 'Bicicleta';
    }
  }
}

class VehicleSpecs extends Equatable {
  final String? color;
  final String? engine;
  final String? transmission;
  final String? fuelType;
  final double? fuelCapacity;
  final int? seatingCapacity;
  final Map<String, dynamic>? additionalInfo;

  const VehicleSpecs({
    this.color,
    this.engine,
    this.transmission,
    this.fuelType,
    this.fuelCapacity,
    this.seatingCapacity,
    this.additionalInfo,
  });

  @override
  List<Object?> get props => [
    color, engine, transmission, fuelType, fuelCapacity,
    seatingCapacity, additionalInfo,
  ];
}