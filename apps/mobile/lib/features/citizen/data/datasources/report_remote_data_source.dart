// lib/features/citizen/data/datasources/report_remote_data_source.dart
import 'dart:io';

import '../../domain/entities/enhanced_report_entity.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<List<ReportModel>> getReportsByUser(String userId);
  Future<ReportModel> getReportById(String reportId);
  Future<String> createReport({
    required String title,
    required String description,
    required String category,
    required LocationData location,
    required String userId,
    required List<File> images,
  });
  Future<void> updateReportStatus(String reportId, String status, String? comment, String userId);
  Future<void> deleteReport(String reportId);
  Future<List<String>> uploadReportImages(List<File> images, String reportId);
}