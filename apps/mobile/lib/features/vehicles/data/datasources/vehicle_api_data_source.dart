// lib/features/vehicles/data/datasources/vehicle_api_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_model.dart';
import '../models/vehicle_log_model.dart';
import 'vehicle_remote_data_source.dart';

class VehicleApiDataSource implements VehicleRemoteDataSource {
  final http.Client client;
  final SharedPreferences prefs;
  final String baseUrl;

  static const String _accessTokenKey = 'access_token';

  VehicleApiDataSource({
    required this.client,
    required this.prefs,
    required this.baseUrl,
  });

  Map<String, String> get _authHeaders {
    final token = prefs.getString(_accessTokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<VehicleModel>> getVehicles(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/vehicles'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => VehicleModel.fromJson(_mapApiToModel(json))).toList();
      } else {
        throw Exception('Error al obtener vehículos');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<VehicleModel> getVehicleById(String vehicleId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VehicleModel.fromJson(_mapApiToModel(data));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener vehículo');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleModel>> getAvailableVehicles(String muniId) async {
    try {
      final allVehicles = await getVehicles(muniId);
      return allVehicles.where((v) => v.status.name == 'available').toList();
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleModel>> getVehiclesByStatus(String status, String muniId) async {
    try {
      final allVehicles = await getVehicles(muniId);
      return allVehicles.where((v) => v.status.name == status).toList();
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<String> startVehicleUsage({
    required String vehicleId,
    required String driverId,
    required String driverName,
    required double startKm,
    required String usageType,
    String? purpose,
  }) async {
    try {
      // TODO: Implementar endpoint en backend para vehicle logs
      // Por ahora, actualizar el estado del vehículo a "in_use"
      await updateVehicleStatus(vehicleId, 'in_use');

      // Retornar un ID temporal
      return 'log_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Error al iniciar uso de vehículo: ${e.toString()}');
    }
  }

  @override
  Future<void> endVehicleUsage({
    required String logId,
    required double endKm,
    String? observations,
    List<String>? attachments,
  }) async {
    try {
      // TODO: Implementar endpoint en backend para finalizar uso
      // Por ahora solo marcamos como disponible
      // Necesitaríamos el vehicleId del log
    } catch (e) {
      throw Exception('Error al finalizar uso de vehículo: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVehicleLocation({
    required String logId,
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    // TODO: Implementar tracking de ubicación en backend
  }

  @override
  Future<List<VehicleLogModel>> getVehicleLogs(String vehicleId) async {
    // TODO: Implementar endpoint en backend
    return [];
  }

  @override
  Future<List<VehicleLogModel>> getDriverLogs(String driverId) async {
    // TODO: Implementar endpoint en backend
    return [];
  }

  @override
  Future<VehicleLogModel?> getCurrentVehicleUsage(String vehicleId) async {
    // TODO: Implementar endpoint en backend
    return null;
  }

  @override
  Future<List<VehicleLogModel>> getActiveUsages(String muniId) async {
    // TODO: Implementar endpoint en backend
    return [];
  }

  @override
  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId'),
        headers: _authHeaders,
        body: json.encode({
          'isActive': status == 'available',
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar estado');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVehicleKm(String vehicleId, double km) async {
    // TODO: Agregar campo de kilometraje en backend
  }

  @override
  Future<void> scheduleMaintenance(String vehicleId, DateTime maintenanceDate) async {
    // TODO: Implementar en backend
  }

  @override
  Future<void> completeMaintenance(String vehicleId, String observations) async {
    // TODO: Implementar en backend
  }

  @override
  Future<Map<String, dynamic>> getVehicleStatistics(String muniId) async {
    try {
      final vehicles = await getVehicles(muniId);
      return {
        'total': vehicles.length,
        'available': vehicles.where((v) => v.status.name == 'available').length,
        'inUse': vehicles.where((v) => v.status.name == 'inUse').length,
        'maintenance': vehicles.where((v) => v.status.name == 'maintenance').length,
      };
    } catch (e) {
      return {'total': 0, 'available': 0, 'inUse': 0, 'maintenance': 0};
    }
  }

  @override
  Future<Map<String, dynamic>> getDriverStatistics(String driverId) async {
    // TODO: Implementar en backend
    return {'totalTrips': 0, 'totalKm': 0, 'totalHours': 0};
  }

  @override
  Stream<List<VehicleModel>> watchVehicles(String muniId) {
    // REST API no soporta streaming, usar polling o WebSocket
    throw UnimplementedError('Streaming no disponible con REST API');
  }

  @override
  Stream<List<VehicleLogModel>> watchActiveUsages(String muniId) {
    throw UnimplementedError('Streaming no disponible con REST API');
  }

  @override
  Stream<VehicleLogModel?> watchVehicleUsage(String vehicleId) {
    throw UnimplementedError('Streaming no disponible con REST API');
  }

  /// Mapear respuesta de API a formato esperado por el modelo
  Map<String, dynamic> _mapApiToModel(Map<String, dynamic> apiData) {
    return {
      'id': apiData['id'],
      'plate': apiData['plate'],
      'brand': apiData['brand'] ?? '',
      'model': apiData['model'] ?? '',
      'year': apiData['year'] ?? 0,
      'type': _mapVehicleType(apiData['vehicleType'] ?? apiData['vehicle_type']),
      'status': apiData['isActive'] == true ? 'available' : 'out_of_service',
      'currentKm': 0.0, // No disponible en API actual
      'muniId': apiData['tenantId'] ?? '',
      'lastMaintenance': null,
      'nextMaintenance': null,
      'currentDriverId': apiData['ownerId'] ?? apiData['owner_id'],
      'currentDriverName': apiData['ownerName'],
      'assignedAreas': <String>[],
      'createdAt': apiData['createdAt'] ?? apiData['created_at'],
      'updatedAt': apiData['updatedAt'] ?? apiData['updated_at'],
      'specs': {
        'color': apiData['color'],
        'engine': null,
        'transmission': null,
        'fuelType': null,
        'fuelCapacity': null,
        'seatingCapacity': null,
        'additionalInfo': {'vin': apiData['vin']},
      },
    };
  }

  String _mapVehicleType(String? type) {
    switch (type?.toLowerCase()) {
      case 'auto':
        return 'car';
      case 'moto':
        return 'motorcycle';
      case 'camion':
        return 'truck';
      case 'camioneta':
        return 'van';
      case 'bus':
        return 'van';
      default:
        return 'car';
    }
  }
}
