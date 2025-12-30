// lib/features/citizen/data/repositories/report_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ReportEntity>>> getReportsByUser(String userId) async {
    try {
      final reports = await remoteDataSource.getReportsByUser(userId);
      // ReportModel extends ReportEntity, so no conversion needed
      return Right(reports.cast<ReportEntity>());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReportEntity>> getReportById(String reportId) async {
    try {
      final report = await remoteDataSource.getReportById(reportId);
      // ReportModel extends ReportEntity, so no conversion needed
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createReport({
    required String title,
    required String description,
    required String category,
    required LocationData location,
    required String userId,
    required List<File> images,
  }) async {
    try {
      final reportId = await remoteDataSource.createReport(
        title: title,
        description: description,
        category: category,
        location: location,
        userId: userId,
        images: images,
      );
      return Right(reportId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateReportStatus(String reportId, String status, String? comment) async {
    try {
      // Necesitaríamos el ID del usuario que hace el cambio
      // Por ahora usaremos un ID genérico de administrador
      const adminId = 'admin_system';
      await remoteDataSource.updateReportStatus(reportId, status, comment, adminId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport(String reportId) async {
    try {
      await remoteDataSource.deleteReport(reportId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}