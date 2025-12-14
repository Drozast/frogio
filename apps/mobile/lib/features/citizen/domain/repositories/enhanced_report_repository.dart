// lib/features/citizen/domain/repositories/enhanced_report_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/enhanced_report_entity.dart';

abstract class ReportRepository {
  /// Obtiene todos los reportes de un usuario
  Future<Either<Failure, List<ReportEntity>>> getReportsByUser(String userId);
  
  /// Obtiene un reporte específico por ID
  Future<Either<Failure, ReportEntity>> getReportById(String reportId);
  
  /// Crea un nuevo reporte
  Future<Either<Failure, String>> createReport(CreateReportParams params);
  
  /// Actualiza el estado de un reporte
  Future<Either<Failure, void>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
  });
  
  /// Añade una respuesta a un reporte
  Future<Either<Failure, void>> addResponse({
    required String reportId,
    required String responderId,
    required String responderName,
    required String message,
    List<File>? attachments,
    required bool isPublic,
  });
  
  /// Obtiene reportes filtrados por estado
  Future<Either<Failure, List<ReportEntity>>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
  });
  
  /// Asigna un reporte a un inspector
  Future<Either<Failure, void>> assignReport({
    required String reportId,
    required String assignedToId,
    required String assignedById,
  });
  
  /// Stream de reportes de un usuario en tiempo real
  Stream<List<ReportEntity>> watchReportsByUser(String userId);
  
  /// Stream de reportes por estado en tiempo real
  Stream<List<ReportEntity>> watchReportsByStatus(ReportStatus status, String muniId);
}

// Clase para parámetros de creación de reportes
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
    this.priority = Priority.medium,
    this.attachments = const [],
  });
}