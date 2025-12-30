// lib/features/citizen/domain/usecases/reports/get_report_by_id.dart
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/enhanced_report_entity.dart';
import '../../repositories/report_repository.dart';

class GetReportById implements UseCase<ReportEntity, String> {
  final ReportRepository repository;

  GetReportById(this.repository);

  @override
  Future<Either<Failure, ReportEntity>> call(String reportId) {
    return repository.getReportById(reportId);
  }
}