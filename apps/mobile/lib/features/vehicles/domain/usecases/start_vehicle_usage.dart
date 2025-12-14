// lib/features/vehicles/domain/usecases/start_vehicle_usage.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:frogio_santa_juana/features/vehicles/domain/entities/vehicle_log_entity.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/vehicle_repository.dart';

class StartVehicleUsage extends UseCase<String, StartVehicleUsageParams> {
  final VehicleRepository repository;

  StartVehicleUsage({required this.repository});

  @override
  Future<Either<Failure, String>> call(StartVehicleUsageParams params) async {
    return await repository.startVehicleUsage(
      vehicleId: params.vehicleId,
      driverId: params.driverId,
      driverName: params.driverName,
      startKm: params.startKm,
      usageType: params.usageType,
      purpose: params.purpose,
    );
  }
}

class StartVehicleUsageParams extends Equatable {
  final String vehicleId;
  final String driverId;
  final String driverName;
  final double startKm;
  final UsageType usageType;
  final String? purpose;

  const StartVehicleUsageParams({
    required this.vehicleId,
    required this.driverId,
    required this.driverName,
    required this.startKm,
    required this.usageType,
    this.purpose,
  });

  @override
  List<Object?> get props => [vehicleId, driverId, driverName, startKm, usageType, purpose];
}