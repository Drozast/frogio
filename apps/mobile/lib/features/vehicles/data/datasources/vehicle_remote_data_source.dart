// lib/features/vehicles/data/datasources/vehicle_remote_data_source.dart
import '../models/vehicle_model.dart';

abstract class VehicleRemoteDataSource {
  Future<List<VehicleModel>> getVehicles(String muniId);
  Future<VehicleModel> getVehicleById(String vehicleId);
  Future<List<VehicleModel>> getAvailableVehicles(String muniId);
  Future<List<VehicleModel>> getVehiclesByStatus(String status, String muniId);
  
  Future<String> startVehicleUsage({
    required String vehicleId,
    required String driverId,
    required String driverName,
    required double startKm,
    required String usageType,
    String? purpose,
  });
  
  Future<void> endVehicleUsage({
    required String logId,
    required double endKm,
    String? observations,
    List<String>? attachments,
  });
  
  Future<void> updateVehicleLocation({
    required String logId,
    required double latitude,
    required double longitude,
    double? speed,
  });
  
  Future<List<VehicleLogModel>> getVehicleLogs(String vehicleId);
  Future<List<VehicleLogModel>> getDriverLogs(String driverId);
  Future<VehicleLogModel?> getCurrentVehicleUsage(String vehicleId);
  Future<List<VehicleLogModel>> getActiveUsages(String muniId);
  
  Future<void> updateVehicleStatus(String vehicleId, String status);
  Future<void> updateVehicleKm(String vehicleId, double km);
  Future<void> scheduleMaintenance(String vehicleId, DateTime maintenanceDate);
  Future<void> completeMaintenance(String vehicleId, String observations);
  
  Future<Map<String, dynamic>> getVehicleStatistics(String muniId);
  Future<Map<String, dynamic>> getDriverStatistics(String driverId);
  
  Stream<List<VehicleModel>> watchVehicles(String muniId);
  Stream<List<VehicleLogModel>> watchActiveUsages(String muniId);
  Stream<VehicleLogModel?> watchVehicleUsage(String vehicleId);
}