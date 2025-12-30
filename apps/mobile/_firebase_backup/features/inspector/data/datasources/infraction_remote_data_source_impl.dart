// lib/features/inspector/data/datasources/infraction_remote_data_source_impl.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/infraction_entity.dart';
import '../models/infraction_model.dart';
import 'infraction_remote_data_source.dart';

class InfractionRemoteDataSourceImpl implements InfractionRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Uuid uuid;

  InfractionRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    required this.uuid,
  });

  @override
  Future<List<InfractionModel>> getInfractionsByInspector(String inspectorId) async {
    try {
      final querySnapshot = await firestore
          .collection('infractions')
          .where('inspectorId', isEqualTo: inspectorId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InfractionModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar infracciones: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> getInfractionById(String infractionId) async {
    try {
      final docSnapshot = await firestore.collection('infractions').doc(infractionId).get();

      if (!docSnapshot.exists) {
        throw const ServerFailure('Infracción no encontrada');
      }

      return InfractionModel.fromJson({
        ...docSnapshot.data()!,
        'id': docSnapshot.id,
      });
    } catch (e) {
      throw ServerFailure('Error al cargar infracción: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> createInfraction(InfractionModel infraction) async {
    try {
      final infractionId = uuid.v4();
      final now = DateTime.now();
      
      final infractionData = infraction.copyWith(
        id: infractionId,
        createdAt: now,
        updatedAt: now,
        historyLog: [
          {
            'timestamp': now,
            'status': infraction.status,
            'comment': 'Infracción creada',
            'userId': infraction.inspectorId,
            'userName': 'Inspector',
          }
        ],
      );

      await firestore.collection('infractions').doc(infractionId).set(infractionData.toJson());

      return infractionData;
    } catch (e) {
      throw ServerFailure('Error al crear infracción: ${e.toString()}');
    }
  }

  @override
  Future<InfractionModel> updateInfraction(InfractionModel infraction) async {
    try {
      final updatedInfraction = infraction.copyWith(
        updatedAt: DateTime.now(),
      );

      await firestore
          .collection('infractions')
          .doc(infraction.id)
          .update(updatedInfraction.toJson());

      return updatedInfraction;
    } catch (e) {
      throw ServerFailure('Error al actualizar infracción: ${e.toString()}');
    }
  }

  @override
  Future<void> updateInfractionStatus(String infractionId, String status, String? comment) async {
    try {
      // Obtener infracción actual para el historial
      final infractionDoc = await firestore.collection('infractions').doc(infractionId).get();
      final infractionData = infractionDoc.data();
      
      if (infractionData == null) {
        throw const ServerFailure('Infracción no encontrada');
      }

      // Crear nuevo item de historial
      final historyItem = {
        'timestamp': DateTime.now(),
        'status': status,
        'comment': comment ?? 'Estado actualizado',
        'userId': infractionData['inspectorId'],
        'userName': 'Inspector',
      };

      // Actualizar infracción
      await firestore.collection('infractions').doc(infractionId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'historyLog': FieldValue.arrayUnion([historyItem]),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar estado: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadEvidenceImage(String infractionId, File image) async {
    try {
      final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final storagePath = 'infractions/$infractionId/evidence/$fileName';
      
      // Comprimir imagen solo si no estamos en web
      File imageToUpload = image;
      if (!kIsWeb) {
        try {
          imageToUpload = await _compressImage(image);
        } catch (e) {
          // Si falla la compresión, usar la original
          imageToUpload = image;
        }
      }
      
      // Subir archivo
      final storageRef = storage.ref().child(storagePath);
      final uploadTask = await storageRef.putFile(imageToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw ServerFailure('Error al subir imagen de evidencia: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadSignature(String infractionId, String signatureData) async {
    try {
      final fileName = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = 'infractions/$infractionId/signatures/$fileName';
      
      // Convertir datos de firma a bytes (asumiendo que es base64)
      final bytes = base64Decode(signatureData);
      
      // Subir archivo
      final storageRef = storage.ref().child(storagePath);
      final uploadTask = await storageRef.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw ServerFailure('Error al subir firma: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteInfraction(String infractionId) async {
    try {
      // Eliminar archivos de storage
      try {
        final storageRef = storage.ref().child('infractions/$infractionId');
        final listResult = await storageRef.listAll();
        
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error al eliminar archivos: ${e.toString()}');
        }
      }

      // Eliminar documento
      await firestore.collection('infractions').doc(infractionId).delete();
    } catch (e) {
      throw ServerFailure('Error al eliminar infracción: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadInfractionImages(List<File> images, String infractionId) async {
    try {
      final List<String> urls = [];
      
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = 'evidence_${i}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
        final storagePath = 'infractions/$infractionId/evidence/$fileName';
        
        // Comprimir imagen solo si no estamos en web
        File imageToUpload = file;
        if (!kIsWeb) {
          try {
            imageToUpload = await _compressImage(file);
          } catch (e) {
            // Si falla la compresión, usar la original
            imageToUpload = file;
          }
        }
        
        // Subir archivo
        final storageRef = storage.ref().child(storagePath);
        final uploadTask = await storageRef.putFile(imageToUpload);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        urls.add(downloadUrl);
      }
      
      return urls;
    } catch (e) {
      throw ServerFailure('Error al subir imágenes: ${e.toString()}');
    }
  }

  @override
  Future<List<InfractionModel>> getInfractionsByStatus(String status, {String? muniId}) async {
    try {
      Query query = firestore
          .collection('infractions')
          .where('status', isEqualTo: status);
      
      if (muniId != null) {
        query = query.where('muniId', isEqualTo: muniId);
      }
      
      final querySnapshot = await query
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InfractionModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar infracciones por estado: ${e.toString()}');
    }
  }

  @override
  Future<List<InfractionModel>> getInfractionsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? muniId,
  }) async {
    try {
      Query query = firestore.collection('infractions');
      
      if (muniId != null) {
        query = query.where('muniId', isEqualTo: muniId);
      }
      
      final querySnapshot = await query.get();
      
      // Filtrar por distancia usando la fórmula de Haversine
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as Map<String, dynamic>?;
        
        if (location == null) return false;
        
        final lat = (location['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (location['longitude'] as num?)?.toDouble() ?? 0.0;
        
        final distance = _calculateDistance(latitude, longitude, lat, lng);
        return distance <= radiusKm;
      }).toList();

      return filteredDocs
          .map((doc) => InfractionModel.fromJson({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar infracciones por ubicación: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, int>> getInfractionStatistics(String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('infractions')
          .where('muniId', isEqualTo: muniId)
          .get();
      
      final Map<String, int> statistics = {};
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'unknown';
        statistics[status] = (statistics[status] ?? 0) + 1;
      }
      
      return statistics;
    } catch (e) {
      throw ServerFailure('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  @override
  Stream<List<InfractionModel>> watchInfractionsByInspector(String inspectorId) {
    return firestore
        .collection('infractions')
        .where('inspectorId', isEqualTo: inspectorId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InfractionModel.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  // Métodos auxiliares privados

  Future<File> _compressImage(File file) async {
    // Solo comprimir si no estamos en web
    if (kIsWeb) {
      return file;
    }

    try {
      final dir = path.dirname(file.path);
      final ext = path.extension(file.path);
      final fileName = path.basenameWithoutExtension(file.path);
      final targetPath = path.join(dir, '${fileName}_compressed$ext');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      return file; // Return original if compression fails
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Fórmula de Haversine simplificada
    const double earthRadius = 6371; // Radio de la Tierra en km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() * _degreesToRadians(lat2).cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

// Extension para operaciones matemáticas
extension DoubleExtensions on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double sqrt() => math.sqrt(this);
  double asin() => math.asin(this);
}

// Clase auxiliar para manejo de datos de ubicación
class LocationDataModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String city;
  final String region;
  final String country;

  const LocationDataModel({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.city,
    required this.region,
    required this.country,
  });

  factory LocationDataModel.fromEntity(LocationData entity) {
    return LocationDataModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      city: entity.city,
      region: entity.region,
      country: entity.country,
    );
  }

  factory LocationDataModel.fromMap(Map<String, dynamic> map) {
    return LocationDataModel(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: map['address'],
      city: map['city'] ?? '',
      region: map['region'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'region': region,
      'country': country,
    };
  }

  LocationData toEntity() {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      region: region,
      country: country,
    );
  }
}