// lib/features/vehicles/domain/repositories/vehicle_repository.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';

abstract class VehicleRepository {
  /// Obtiene la lista de vehículos
  Future<Either<Failure, List<VehicleEntity>>> getVehicles(String muniId);

  /// Obtiene un vehículo por ID
  Future<Either<Failure, VehicleEntity>> getVehicleById(String vehicleId);

  /// Obtiene vehículos disponibles
  Future<Either<Failure, List<VehicleEntity>>> getAvailableVehicles(String muniId);

  /// Obtiene vehículos por estado
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByStatus(VehicleStatus status, String muniId);

  /// Inicia el uso de un vehículo
  Future<Either<Failure, String>> startVehicleUsage({
    required String vehicleId,
    required String driverId,
    required String driverName,
    required double startKm,
    required UsageType usageType,
    String? purpose,
  });

  /// Finaliza el uso de un vehículo
  Future<Either<Failure, void>> endVehicleUsage({
    required String logId,
    required double endKm,
    String? observations,
    List<String>? attachments,
    List<LocationPoint>? route,
    List<TripStop>? stops,
  });

  /// Actualiza la ubicación del vehículo
  Future<Either<Failure, void>> updateVehicleLocation({
    required String logId,
    required double latitude,
    required double longitude,
    double? speed,
  });

  /// Obtiene el historial de uso de un vehículo
  Future<Either<Failure, List<VehicleLogEntity>>> getVehicleLogs(String vehicleId);

  /// Obtiene el historial de uso de un conductor
  Future<Either<Failure, List<VehicleLogEntity>>> getDriverLogs(String driverId);

  /// Obtiene el uso actual de un vehículo (si existe)
  Future<Either<Failure, VehicleLogEntity?>> getCurrentVehicleUsage(String vehicleId);

  /// Obtiene todos los usos activos del municipio
  Future<Either<Failure, List<VehicleLogEntity>>> getActiveUsages(String muniId);

  /// Actualiza el estado de un vehículo
  Future<Either<Failure, void>> updateVehicleStatus(String vehicleId, VehicleStatus status);

  /// Actualiza el kilometraje de un vehículo
  Future<Either<Failure, void>> updateVehicleKm(String vehicleId, double km);

  /// Programa mantenimiento
  Future<Either<Failure, void>> scheduleMaintenance(String vehicleId, DateTime maintenanceDate);

  /// Completa mantenimiento
  Future<Either<Failure, void>> completeMaintenance(String vehicleId, String observations);

  /// Obtiene estadísticas de vehículos
  Future<Either<Failure, Map<String, dynamic>>> getVehicleStatistics(String muniId);

  /// Obtiene estadísticas de un conductor
  Future<Either<Failure, Map<String, dynamic>>> getDriverStatistics(String driverId);

  /// Observa vehículos en tiempo real
  Stream<List<VehicleEntity>> watchVehicles(String muniId);

  /// Observa usos activos en tiempo real
  Stream<List<VehicleLogEntity>> watchActiveUsages(String muniId);

  /// Observa el uso de un vehículo específico
  Stream<VehicleLogEntity?> watchVehicleUsage(String vehicleId);
}