// lib/features/admin/domain/repositories/admin_repository.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/municipal_statistics_entity.dart';
import '../entities/query_entity.dart';
import '../entities/user_entity.dart';

abstract class AdminRepository {
  // Gestión de consultas
  Future<Either<Failure, List<QueryEntity>>> getAllPendingQueries(String muniId);
  Future<Either<Failure, void>> answerQuery({
    required String queryId,
    required String adminId,
    required String response,
    List<String>? attachments,
  });
  Future<Either<Failure, List<QueryEntity>>> getQueriesByStatus({
    required String muniId,
    required String status,
  });
  
  // Gestión de usuarios
  Future<Either<Failure, List<UserEntity>>> getAllUsers(String muniId);
  Future<Either<Failure, List<UserEntity>>> getUsersByRole({
    required String muniId,
    required String role,
  });
  Future<Either<Failure, void>> updateUserRole({
    required String userId,
    required String newRole,
    required String adminId,
  });
  Future<Either<Failure, void>> activateUser(String userId);
  Future<Either<Failure, void>> deactivateUser(String userId);
  
  // Estadísticas municipales
  Future<Either<Failure, MunicipalStatisticsEntity>> getMunicipalStatistics(String muniId);
  Future<Either<Failure, Map<String, dynamic>>> getReportsStatistics({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, Map<String, dynamic>>> getInfractionsStatistics({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Gestión de reportes
  Future<Either<Failure, void>> assignReportToInspector({
    required String reportId,
    required String inspectorId,
    required String adminId,
  });
  Future<Either<Failure, void>> updateReportPriority({
    required String reportId,
    required String priority,
    required String adminId,
  });
  
  // Gestión de configuraciones
  Future<Either<Failure, void>> updateMunicipalSettings({
    required String muniId,
    required Map<String, dynamic> settings,
  });
  Future<Either<Failure, Map<String, dynamic>>> getMunicipalSettings(String muniId);
  
  // Exportación de datos
  Future<Either<Failure, String>> exportReportsToCSV({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, String>> exportInfractionsToCSV({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  });
}