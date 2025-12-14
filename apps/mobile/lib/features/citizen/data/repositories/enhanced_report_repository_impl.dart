// lib/features/citizen/data/repositories/enhanced_report_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../../domain/repositories/enhanced_report_repository.dart';
import '../datasources/enhanced_report_remote_data_source.dart' as datasource;

class ReportRepositoryImpl implements ReportRepository {
  final datasource.ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ReportEntity>>> getReportsByUser(String userId) async {
    try {
      final reports = await remoteDataSource.getReportsByUser(userId);
      return Right(reports);
    } catch (e) {
      return Left(ServerFailure('Error al obtener reportes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ReportEntity>> getReportById(String reportId) async {
    try {
      final report = await remoteDataSource.getReportById(reportId);
      return Right(report);
    } catch (e) {
      return Left(ServerFailure('Error al obtener reporte: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> createReport(CreateReportParams params) async {
    try {
      // Convertir del domain CreateReportParams al datasource CreateReportParams
      final datasourceParams = datasource.CreateReportParams(
        title: params.title,
        description: params.description,
        category: params.category,
        references: params.references,
        location: params.location,
        userId: params.userId,
        priority: params.priority,
        attachments: params.attachments,
      );
      
      final reportId = await remoteDataSource.createReport(datasourceParams);
      return Right(reportId);
    } catch (e) {
      return Left(ServerFailure('Error al crear reporte: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
  }) async {
    try {
      await remoteDataSource.updateReportStatus(
        reportId: reportId,
        status: status,
        comment: comment,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar estado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addResponse({
    required String reportId,
    required String responderId,
    required String responderName,
    required String message,
    List<File>? attachments,
    required bool isPublic,
  }) async {
    try {
      await remoteDataSource.addResponse(
        reportId: reportId,
        responderId: responderId,
        responderName: responderName,
        message: message,
        attachments: attachments,
        isPublic: isPublic,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar respuesta: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<ReportEntity>>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
  }) async {
    try {
      final reports = await remoteDataSource.getReportsByStatus(
        status,
        muniId: muniId,
        assignedTo: assignedTo,
      );
      return Right(reports);
    } catch (e) {
      return Left(ServerFailure('Error al obtener reportes por estado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> assignReport({
    required String reportId,
    required String assignedToId,
    required String assignedById,
  }) async {
    try {
      await remoteDataSource.assignReport(
        reportId: reportId,
        assignedToId: assignedToId,
        assignedById: assignedById,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al asignar reporte: ${e.toString()}'));
    }
  }

  @override
  Stream<List<ReportEntity>> watchReportsByUser(String userId) {
    return remoteDataSource.watchReportsByUser(userId);
  }

  @override
  Stream<List<ReportEntity>> watchReportsByStatus(ReportStatus status, String muniId) {
    return remoteDataSource.watchReportsByStatus(status, muniId);
  }
}