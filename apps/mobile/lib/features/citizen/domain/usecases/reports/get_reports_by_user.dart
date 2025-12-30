// lib/features/citizen/domain/usecases/reports/get_reports_by_user.dart
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/enhanced_report_entity.dart';
import '../../repositories/report_repository.dart';

class GetReportsByUser implements UseCase<List<ReportEntity>, String> {
  final ReportRepository repository;

  GetReportsByUser(this.repository);

  @override
  Future<Either<Failure, List<ReportEntity>>> call(String userId) {
    return repository.getReportsByUser(userId);
  }
}