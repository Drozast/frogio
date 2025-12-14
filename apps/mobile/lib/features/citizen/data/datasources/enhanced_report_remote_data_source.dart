// lib/features/citizen/data/datasources/enhanced_report_remote_data_source.dart
import 'dart:io';

import '../../domain/entities/enhanced_report_entity.dart';
import '../models/enhanced_report_model.dart';

abstract class ReportRemoteDataSource {
  /// Obtiene reportes por usuario
  Future<List<ReportModel>> getReportsByUser(String userId);
  
  /// Obtiene un reporte por ID
  Future<ReportModel> getReportById(String reportId);
  
  /// Crea un nuevo reporte
  Future<String> createReport(CreateReportParams params);
  
  /// Actualiza el estado de un reporte
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
  });
  
  /// Añade una respuesta a un reporte
  Future<void> addResponse({
    required String reportId,
    required String responderId,
    required String responderName,
    required String message,
    List<File>? attachments,
    required bool isPublic,
  });
  
  /// Obtiene reportes por estado
  Future<List<ReportModel>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
  });
  
  /// Asigna un reporte a un inspector
  Future<void> assignReport({
    required String reportId,
    required String assignedToId,
    required String assignedById,
  });
  
  /// Sube archivos adjuntos
  Future<List<String>> uploadAttachments(List<File> attachments, String reportId);
  
  /// Observa reportes por usuario en tiempo real
  Stream<List<ReportModel>> watchReportsByUser(String userId);
  
  /// Observa reportes por estado en tiempo real
  Stream<List<ReportModel>> watchReportsByStatus(ReportStatus status, String muniId);
}

// Clase auxiliar para parámetros de creación
class CreateReportParams {
  final String title;
  final String description;
  final String category;
  final String? references;
  final LocationData location;
  final String userId;
  final Priority priority;
  final List<File> attachments;

  const CreateReportParams({
    required this.title,
    required this.description,
    required this.category,
    this.references,
    required this.location,
    required this.userId,
    required this.priority,
    required this.attachments,
  });
}