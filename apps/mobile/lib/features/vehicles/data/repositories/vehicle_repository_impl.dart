// lib/features/vehicles/data/repositories/vehicle_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:frogio_santa_juana/features/vehicles/data/datasources/vehicle_remote_data_source.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';
import 'vehicle_repository.dart';


class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehicles(String muniId) async {
    try {
      final vehicles = await remoteDataSource.getVehicles(muniId);
      return Right(vehicles);
    } catch (e) {
      return Left(ServerFailure('Error al obtener vehículos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleById(String vehicleId) async {
    try {
      final vehicle = await remoteDataSource.getVehicleById(vehicleId);
      return Right(vehicle);
    } catch (e) {
      return Left(ServerFailure('Error al obtener vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getAvailableVehicles(String muniId) async {
    try {
      final vehicles = await remoteDataSource.getAvailableVehicles(muniId);
      return Right(vehicles);
    } catch (e) {
      return Left(ServerFailure('Error al obtener vehículos disponibles: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByStatus(
    VehicleStatus status, 
    String muniId,
  ) async {
    try {
      final vehicles = await remoteDataSource.getVehiclesByStatus(status.name, muniId);
      return Right(vehicles);
    } catch (e) {
      return Left(ServerFailure('Error al obtener vehículos por estado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> startVehicleUsage({
    required String vehicleId,
    required String driverId,
    required String driverName,
    required double startKm,
    required UsageType usageType,
    String? purpose,
  }) async {
    try {
      final logId = await remoteDataSource.startVehicleUsage(
        vehicleId: vehicleId,
        driverId: driverId,
        driverName: driverName,
        startKm: startKm,
        usageType: usageType.name,
        purpose: purpose,
      );
      return Right(logId);
    } catch (e) {
      return Left(ServerFailure('Error al iniciar uso de vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> endVehicleUsage({
    required String logId,
    required double endKm,
    String? observations,
    List<String>? attachments,
  }) async {
    try {
      await remoteDataSource.endVehicleUsage(
        logId: logId,
        endKm: endKm,
        observations: observations,
        attachments: attachments,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al finalizar uso de vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicleLocation({
    required String logId,
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    try {
      await remoteDataSource.updateVehicleLocation(
        logId: logId,
        latitude: latitude,
        longitude: longitude,
        speed: speed,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar ubicación: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleLogEntity>>> getVehicleLogs(String vehicleId) async {
    try {
      final logs = await remoteDataSource.getVehicleLogs(vehicleId);
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure('Error al obtener historial del vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleLogEntity>>> getDriverLogs(String driverId) async {
    try {
      final logs = await remoteDataSource.getDriverLogs(driverId);
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure('Error al obtener historial del conductor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VehicleLogEntity?>> getCurrentVehicleUsage(String vehicleId) async {
    try {
      final log = await remoteDataSource.getCurrentVehicleUsage(vehicleId);
      return Right(log);
    } catch (e) {
      return Left(ServerFailure('Error al obtener uso actual del vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<VehicleLogEntity>>> getActiveUsages(String muniId) async {
    try {
      final logs = await remoteDataSource.getActiveUsages(muniId);
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure('Error al obtener usos activos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicleStatus(String vehicleId, VehicleStatus status) async {
    try {
      await remoteDataSource.updateVehicleStatus(vehicleId, status.name);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar estado del vehículo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateVehicleKm(String vehicleId, double km) async {
    try {
      await remoteDataSource.updateVehicleKm(vehicleId, km);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar kilometraje: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleMaintenance(String vehicleId, DateTime maintenanceDate) async {
    try {
      await remoteDataSource.scheduleMaintenance(vehicleId, maintenanceDate);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al programar mantenimiento: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> completeMaintenance(String vehicleId, String observations) async {
    try {
      await remoteDataSource.completeMaintenance(vehicleId, observations);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al completar mantenimiento: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getVehicleStatistics(String muniId) async {
    try {
      final statistics = await remoteDataSource.getVehicleStatistics(muniId);
      return Right(statistics);
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas de vehículos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDriverStatistics(String driverId) async {
    try {
      final statistics = await remoteDataSource.getDriverStatistics(driverId);
      return Right(statistics);
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas del conductor: ${e.toString()}'));
    }
  }

  @override
  Stream<List<VehicleEntity>> watchVehicles(String muniId) {
    return remoteDataSource.watchVehicles(muniId);
  }

  @override
  Stream<List<VehicleLogEntity>> watchActiveUsages(String muniId) {
    return remoteDataSource.watchActiveUsages(muniId);
  }

  @override
  Stream<VehicleLogEntity?> watchVehicleUsage(String vehicleId) {
    return remoteDataSource.watchVehicleUsage(vehicleId);
  }
}