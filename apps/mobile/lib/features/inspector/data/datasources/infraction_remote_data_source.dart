// lib/features/inspector/data/datasources/infraction_remote_data_source.dart
import 'dart:io';

import '../models/infraction_model.dart';

abstract class InfractionRemoteDataSource {
  /// Obtiene todas las infracciones del inspector
  Future<List<InfractionModel>> getInfractionsByInspector(String inspectorId);
  
  /// Obtiene una infracción por ID
  Future<InfractionModel> getInfractionById(String infractionId);
  
  /// Crea una nueva infracción
  Future<InfractionModel> createInfraction(InfractionModel infraction);
  
  /// Actualiza una infracción existente
  Future<InfractionModel> updateInfraction(InfractionModel infraction);
  
  /// Actualiza el estado de una infracción
  Future<void> updateInfractionStatus(String infractionId, String status, String? comment);
  
  /// Sube una imagen de evidencia
  Future<String> uploadEvidenceImage(String infractionId, File image);
  
  /// Sube la firma del infractor
  Future<String> uploadSignature(String infractionId, String signatureData);
  
  /// Elimina una infracción
  Future<void> deleteInfraction(String infractionId);
  
  /// Sube múltiples imágenes de evidencia
  Future<List<String>> uploadInfractionImages(List<File> images, String infractionId);
  
  /// Obtiene infracciones por estado
  Future<List<InfractionModel>> getInfractionsByStatus(String status, {String? muniId});
  
  /// Obtiene infracciones por ubicación
  Future<List<InfractionModel>> getInfractionsByLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? muniId,
  });
  
  /// Obtiene estadísticas de infracciones
  Future<Map<String, int>> getInfractionStatistics(String muniId);
  
  /// Observa infracciones por inspector en tiempo real
  Stream<List<InfractionModel>> watchInfractionsByInspector(String inspectorId);
}