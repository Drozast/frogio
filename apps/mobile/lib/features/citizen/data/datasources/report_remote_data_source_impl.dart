// lib/features/citizen/data/datasources/report_remote_data_source_impl.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

import '../../../../core/error/failures.dart';
import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';
import 'report_remote_data_source.dart';

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  ReportRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('reports')
          .where('citizenId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar reportes: ${e.toString()}');
    }
  }

  @override
  Future<ReportModel> getReportById(String reportId) async {
    try {
      final docSnapshot = await firestore.collection('reports').doc(reportId).get();

      if (!docSnapshot.exists) {
        throw const ServerFailure('Reporte no encontrado');
      }

      return ReportModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw ServerFailure('Error al cargar reporte: ${e.toString()}');
    }
  }

  @override
  Future<String> createReport({
    required String title,
    required String description,
    required String category,
    required LocationData location,
    required String userId,
    required List<File> images,
  }) async {
    try {
      // Obtener municipio del usuario
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final muniId = userData?['muniId'] ?? 'muni_default';

      // Crear documento inicial
      final reportRef = firestore.collection('reports').doc();
      
      // Historial inicial
      final historyLog = [
        {
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'Enviada',
          'userId': userId,
        }
      ];

      // Datos iniciales
      final reportData = {
        'title': title,
        'description': description,
        'category': category,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': location.address,
        },
        'citizenId': userId,
        'muniId': muniId,
        'status': 'Pendiente',
        'images': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'historyLog': historyLog,
      };

      // Guardar documento
      await reportRef.set(reportData);

      // Subir imágenes si hay
      if (images.isNotEmpty) {
        final imageUrls = await uploadReportImages(images, reportRef.id);
        
        // Actualizar documento con URLs de imágenes
        await reportRef.update({'images': imageUrls});
      }

      return reportRef.id;
    } catch (e) {
      throw ServerFailure('Error al crear reporte: ${e.toString()}');
    }
  }

  @override
  Future<void> updateReportStatus(String reportId, String status, String? comment, String userId) async {
    try {
      final reportRef = firestore.collection('reports').doc(reportId);
      
      // Crear nuevo elemento de historial
      final historyItem = {
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
        'userId': userId,
      };
      
      if (comment != null) {
        historyItem['comment'] = comment;
      }

      // Actualizar reporte
      await reportRef.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'historyLog': FieldValue.arrayUnion([historyItem]),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar estado: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteReport(String reportId) async {
    try {
      // Eliminar documento
      await firestore.collection('reports').doc(reportId).delete();
      
      // Intentar eliminar imágenes asociadas
      try {
        final storageRef = storage.ref().child('reports/$reportId');
        final listResult = await storageRef.listAll();
        
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        // Ignorar errores al eliminar imágenes
        if (kDebugMode) {
          print('Error al eliminar imágenes: ${e.toString()}');
        }
      }
    } catch (e) {
      throw ServerFailure('Error al eliminar reporte: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadReportImages(List<File> images, String reportId) async {
    try {
      final imageUrls = <String>[];
      
      for (var i = 0; i < images.length; i++) {
        // Comprimir imagen
        final File compressedFile = await _compressImage(images[i], 70);
        
        // Generar nombre único
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(compressedFile.path)}';
        final storageRef = storage.ref().child('reports/$reportId/$fileName');
        
        // Subir archivo
        final uploadTask = await storageRef.putFile(compressedFile);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw ServerFailure('Error al subir imágenes: ${e.toString()}');
    }
  }

  // Método auxiliar para comprimir imágenes
  Future<File> _compressImage(File file, int quality) async {
    final dir = path.dirname(file.path);
    final ext = path.extension(file.path);
    final fileName = path.basenameWithoutExtension(file.path);
    final targetPath = path.join(dir, '${fileName}_compressed$ext');
    
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
    );
    
    return File(result!.path);
  }
}