// lib/features/citizen/domain/repositories/report_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/enhanced_report_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, List<ReportEntity>>> getReportsByUser(String userId);
  Future<Either<Failure, ReportEntity>> getReportById(String reportId);
  Future<Either<Failure, String>> createReport({
    required String title,
    required String description,
    required String category,
    required LocationData location,
    required String userId,
    required List<File> images,
  });
  Future<Either<Failure, void>> updateReportStatus(String reportId, String status, String? comment);
  Future<Either<Failure, void>> deleteReport(String reportId);
}