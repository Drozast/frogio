import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frogio_santa_juana/features/vehicles/domain/entities/vehicle_log_entity.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../models/vehicle_model.dart';
import 'vehicle_remote_data_source.dart';

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final FirebaseFirestore firestore;
  final Uuid uuid;

  VehicleRemoteDataSourceImpl({
    required this.firestore,
    required this.uuid,
  });

  @override
  Future<List<VehicleModel>> getVehicles(String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicles')
          .where('muniId', isEqualTo: muniId)
          .orderBy('plate')
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar vehículos: ${e.toString()}');
    }
  }

  @override
  Future<VehicleModel> getVehicleById(String vehicleId) async {
    try {
      final docSnapshot = await firestore.collection('vehicles').doc(vehicleId).get();

      if (!docSnapshot.exists) {
        throw const ServerFailure('Vehículo no encontrado');
      }

      return VehicleModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw ServerFailure('Error al cargar vehículo: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleModel>> getAvailableVehicles(String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicles')
          .where('muniId', isEqualTo: muniId)
          .where('status', isEqualTo: VehicleStatus.available.name)
          .orderBy('plate')
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar vehículos disponibles: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleModel>> getVehiclesByStatus(String status, String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicles')
          .where('muniId', isEqualTo: muniId)
          .where('status', isEqualTo: status)
          .orderBy('plate')
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar vehículos por estado: ${e.toString()}');
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
      final logId = uuid.v4();
      final now = DateTime.now();

      // Crear el log de uso
      final logData = VehicleLogModel(
        id: logId,
        vehicleId: vehicleId,
        driverId: driverId,
        driverName: driverName,
        startKm: startKm,
        startTime: now,
        route: const [],
        usageType: UsageType.values.firstWhere(
          (type) => type.name == usageType,
          orElse: () => UsageType.other,
        ),
        purpose: purpose,
        attachments: const [],
        createdAt: now,
        updatedAt: now,
      );

      // Guardar el log
      await firestore.collection('vehicleLogs').doc(logId).set(logData.toFirestore());

      // Actualizar el estado del vehículo
      await firestore.collection('vehicles').doc(vehicleId).update({
        'status': VehicleStatus.inUse.name,
        'currentDriverId': driverId,
        'currentDriverName': driverName,
        'currentKm': startKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return logId;
    } catch (e) {
      throw ServerFailure('Error al iniciar uso de vehículo: ${e.toString()}');
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
      final now = DateTime.now();

      // Obtener el log actual
      final logDoc = await firestore.collection('vehicleLogs').doc(logId).get();
      if (!logDoc.exists) {
        throw const ServerFailure('Registro de uso no encontrado');
      }

      final logData = logDoc.data() as Map<String, dynamic>;
      final vehicleId = logData['vehicleId'] as String;

      // Actualizar el log
      await firestore.collection('vehicleLogs').doc(logId).update({
        'endKm': endKm,
        'endTime': now,
        'observations': observations,
        'attachments': attachments ?? [],
        'updatedAt': now,
      });

      // Actualizar el estado del vehículo
      await firestore.collection('vehicles').doc(vehicleId).update({
        'status': VehicleStatus.available.name,
        'currentDriverId': null,
        'currentDriverName': null,
        'currentKm': endKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al finalizar uso de vehículo: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVehicleLocation({
    required String logId,
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    try {
      final locationPoint = LocationPointModel(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        speed: speed,
      );

      await firestore.collection('vehicleLogs').doc(logId).update({
        'route': FieldValue.arrayUnion([locationPoint.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar ubicación: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleLogModel>> getVehicleLogs(String vehicleId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicleLogs')
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar historial del vehículo: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleLogModel>> getDriverLogs(String driverId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicleLogs')
          .where('driverId', isEqualTo: driverId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar historial del conductor: ${e.toString()}');
    }
  }

  @override
  Future<VehicleLogModel?> getCurrentVehicleUsage(String vehicleId) async {
    try {
      final querySnapshot = await firestore
          .collection('vehicleLogs')
          .where('vehicleId', isEqualTo: vehicleId)
          .where('endTime', isNull: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VehicleLogModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw ServerFailure('Error al obtener uso actual del vehículo: ${e.toString()}');
    }
  }

  @override
  Future<List<VehicleLogModel>> getActiveUsages(String muniId) async {
    try {
      // Primero obtener vehículos del municipio
      final vehiclesSnapshot = await firestore
          .collection('vehicles')
          .where('muniId', isEqualTo: muniId)
          .get();

      final vehicleIds = vehiclesSnapshot.docs.map((doc) => doc.id).toList();

      if (vehicleIds.isEmpty) {
        return [];
      }

      // Obtener usos activos
      final querySnapshot = await firestore
          .collection('vehicleLogs')
          .where('vehicleId', whereIn: vehicleIds.take(10).toList()) // Firestore limit
          .where('endTime', isNull: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar usos activos: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    try {
      await firestore.collection('vehicles').doc(vehicleId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar estado del vehículo: ${e.toString()}');
    }
  }

  @override
  Future<void> updateVehicleKm(String vehicleId, double km) async {
    try {
      await firestore.collection('vehicles').doc(vehicleId).update({
        'currentKm': km,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar kilometraje: ${e.toString()}');
    }
  }

  @override
  Future<void> scheduleMaintenance(String vehicleId, DateTime maintenanceDate) async {
    try {
      await firestore.collection('vehicles').doc(vehicleId).update({
        'nextMaintenance': maintenanceDate,
        'status': VehicleStatus.maintenance.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al programar mantenimiento: ${e.toString()}');
    }
  }

  @override
  Future<void> completeMaintenance(String vehicleId, String observations) async {
    try {
      final now = DateTime.now();
      
      await firestore.collection('vehicles').doc(vehicleId).update({
        'lastMaintenance': now,
        'nextMaintenance': now.add(const Duration(days: 90)), // 3 meses
        'status': VehicleStatus.available.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Crear registro de mantenimiento
      final maintenanceRecord = {
        'vehicleId': vehicleId,
        'date': now,
        'observations': observations,
        'type': 'scheduled',
        'createdAt': now,
      };

      await firestore.collection('maintenanceRecords').add(maintenanceRecord);
    } catch (e) {
      throw ServerFailure('Error al completar mantenimiento: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getVehicleStatistics(String muniId) async {
    try {
      // Obtener vehículos del municipio
      final vehiclesSnapshot = await firestore
          .collection('vehicles')
          .where('muniId', isEqualTo: muniId)
          .get();

      final totalVehicles = vehiclesSnapshot.docs.length;
      final statusCounts = <String, int>{};
      final typeCounts = <String, int>{};

      for (final doc in vehiclesSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final type = data['type'] as String;

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      // Obtener logs del último mes
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      final logsSnapshot = await firestore
          .collection('vehicleLogs')
          .where('startTime', isGreaterThan: oneMonthAgo)
          .get();

      double totalKm = 0;
      int totalTrips = 0;
      
      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        final startKm = (data['startKm'] ?? 0).toDouble();
        final endKm = (data['endKm'] ?? 0).toDouble();
        
        if (endKm > startKm) {
          totalKm += (endKm - startKm);
          totalTrips++;
        }
      }

      return {
        'totalVehicles': totalVehicles,
        'statusCounts': statusCounts,
        'typeCounts': typeCounts,
        'monthlyKm': totalKm,
        'monthlyTrips': totalTrips,
        'averageKmPerTrip': totalTrips > 0 ? totalKm / totalTrips : 0,
      };
    } catch (e) {
      throw ServerFailure('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDriverStatistics(String driverId) async {
    try {
      final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final logsSnapshot = await firestore
          .collection('vehicleLogs')
          .where('driverId', isEqualTo: driverId)
          .where('startTime', isGreaterThan: oneMonthAgo)
          .get();

      double totalKm = 0;
      int totalTrips = 0;
      Duration totalDuration = Duration.zero;
      
      for (final doc in logsSnapshot.docs) {
        final data = doc.data();
        final startKm = (data['startKm'] ?? 0).toDouble();
        final endKm = (data['endKm'] ?? 0).toDouble();
        final startTime = (data['startTime'] as Timestamp?)?.toDate();
        final endTime = (data['endTime'] as Timestamp?)?.toDate();
        
        if (endKm > startKm) {
          totalKm += (endKm - startKm);
          totalTrips++;
        }
        
        if (startTime != null && endTime != null) {
          totalDuration += endTime.difference(startTime);
        }
      }

      return {
        'totalKm': totalKm,
        'totalTrips': totalTrips,
        'totalHours': totalDuration.inHours,
        'averageKmPerTrip': totalTrips > 0 ? totalKm / totalTrips : 0,
        'averageHoursPerTrip': totalTrips > 0 ? totalDuration.inHours / totalTrips : 0,
      };
    } catch (e) {
      throw ServerFailure('Error al obtener estadísticas del conductor: ${e.toString()}');
    }
  }

  @override
  Stream<List<VehicleModel>> watchVehicles(String muniId) {
    return firestore
        .collection('vehicles')
        .where('muniId', isEqualTo: muniId)
        .orderBy('plate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<VehicleLogModel>> watchActiveUsages(String muniId) {
    return firestore
        .collection('vehicleLogs')
        .where('endTime', isNull: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final logs = snapshot.docs
              .map((doc) => VehicleLogModel.fromFirestore(doc))
              .toList();

          // Filtrar por municipio
          final filteredLogs = <VehicleLogModel>[];
          for (final log in logs) {
            try {
              final vehicleDoc = await firestore.collection('vehicles').doc(log.vehicleId).get();
              if (vehicleDoc.exists) {
                final vehicleData = vehicleDoc.data() as Map<String, dynamic>;
                if (vehicleData['muniId'] == muniId) {
                  filteredLogs.add(log);
                }
              }
            } catch (e) {
              // Ignorar errores para logs individuales
            }
          }

          return filteredLogs;
        });
  }

  @override
  Stream<VehicleLogModel?> watchVehicleUsage(String vehicleId) {
    return firestore
        .collection('vehicleLogs')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('endTime', isNull: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return VehicleLogModel.fromFirestore(snapshot.docs.first);
        });
  }
}