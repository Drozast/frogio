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
      final response = await client.post(
        Uri.parse('$baseUrl/api/vehicles/logs/start'),
        headers: _authHeaders,
        body: json.encode({
          'vehicleId': vehicleId,
          'driverId': driverId,
          'driverName': driverName,
          'startKm': startKm,
          'usageType': usageType,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] as String;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al iniciar uso de vehículo');
      }
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
      final response = await client.patch(
        Uri.parse('$baseUrl/api/vehicles/logs/$logId/end'),
        headers: _authHeaders,
        body: json.encode({
          'endKm': endKm,
          'observations': observations,
          'attachments': attachments,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al finalizar uso de vehículo');
      }
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
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/vehicles/$vehicleId/logs'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VehicleLogModel.fromJson(_mapLogApiToModel(item))).toList();
      } else {
        throw Exception('Error al obtener historial de uso');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleLogModel>> getDriverLogs(String driverId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/vehicles/logs/my'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VehicleLogModel.fromJson(_mapLogApiToModel(item))).toList();
      } else {
        throw Exception('Error al obtener mis usos');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  @override
  Future<VehicleLogModel?> getCurrentVehicleUsage(String vehicleId) async {
    try {
      final logs = await getVehicleLogs(vehicleId);
      // Find active log for this vehicle
      final activeLogs = logs.where((log) => log.endTime == null).toList();
      return activeLogs.isNotEmpty ? activeLogs.first : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<VehicleLogModel>> getActiveUsages(String muniId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/vehicles/logs/active'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => VehicleLogModel.fromJson(_mapLogApiToModel(item))).toList();
      } else {
        throw Exception('Error al obtener usos activos');
      }
    } catch (e) {
      throw Exception('Error de conexión: ${e.toString()}');
    }
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

  /// Mapear respuesta de API de logs a formato esperado por el modelo
  Map<String, dynamic> _mapLogApiToModel(Map<String, dynamic> apiData) {
    return {
      'id': apiData['id'],
      'vehicleId': apiData['vehicle_id'] ?? apiData['vehicleId'],
      'driverId': apiData['driver_id'] ?? apiData['driverId'],
      'driverName': apiData['driver_name'] ?? apiData['driverName'] ??
                    '${apiData['driver_first_name'] ?? ''} ${apiData['driver_last_name'] ?? ''}'.trim(),
      'startKm': apiData['start_km'] ?? apiData['startKm'] ?? 0.0,
      'endKm': apiData['end_km'] ?? apiData['endKm'],
      'startTime': apiData['start_time'] ?? apiData['startTime'] ?? apiData['created_at'],
      'endTime': apiData['end_time'] ?? apiData['endTime'],
      'route': apiData['route'] ?? [],
      'observations': apiData['observations'],
      'usageType': apiData['usage_type'] ?? apiData['usageType'] ?? 'other',
      'purpose': apiData['purpose'],
      'attachments': apiData['attachments'] ?? [],
      'createdAt': apiData['created_at'] ?? apiData['createdAt'],
      'updatedAt': apiData['updated_at'] ?? apiData['updatedAt'],
    };
  }
}
