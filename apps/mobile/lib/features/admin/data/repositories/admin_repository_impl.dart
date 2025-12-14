// lib/features/admin/data/repositories/admin_repository_impl.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/municipal_statistics_entity.dart';
import '../../domain/entities/query_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<QueryEntity>>> getAllPendingQueries(String muniId) async {
    try {
      final queries = await remoteDataSource.getAllPendingQueries(muniId);
      return Right(queries.map((query) => query.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Error al obtener consultas pendientes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> answerQuery({
    required String queryId,
    required String adminId,
    required String response,
    List<String>? attachments,
  }) async {
    try {
      await remoteDataSource.answerQuery(
        queryId,
        response,
        adminId, // Usar adminId como responderId
        adminId: adminId,
        attachments: attachments,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al responder consulta: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<QueryEntity>>> getQueriesByStatus({
    required String muniId,
    required String status,
  }) async {
    try {
      // Como no existe getQueriesByStatus, obtenemos todas las pendientes
      // y filtramos por status si es necesario
      final queries = await remoteDataSource.getAllPendingQueries(muniId);
      final filteredQueries = queries
          .where((query) => query.status == status)
          .map((query) => query.toEntity())
          .toList();
      return Right(filteredQueries);
    } catch (e) {
      return Left(ServerFailure('Error al obtener consultas por estado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers(String muniId) async {
    try {
      final users = await remoteDataSource.getAllUsers(muniId);
      return Right(users.map((user) => user.toEntity()).cast<UserEntity>().toList());
    } catch (e) {
      return Left(ServerFailure('Error al obtener usuarios: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersByRole({
    required String muniId,
    required String role,
  }) async {
    try {
      final users = await remoteDataSource.getUsersByRole(
        muniId: muniId,
        role: role,
      );
      return Right(users.map((user) => user.toEntity()).cast<UserEntity>().toList());
    } catch (e) {
      return Left(ServerFailure('Error al obtener usuarios por rol: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRole({
    required String userId,
    required String newRole,
    required String adminId,
  }) async {
    try {
      await remoteDataSource.updateUserRole(userId, newRole);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar rol de usuario: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> activateUser(String userId) async {
    try {
      await remoteDataSource.updateUserStatus(userId, true);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al activar usuario: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateUser(String userId) async {
    try {
      await remoteDataSource.updateUserStatus(userId, false);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al desactivar usuario: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MunicipalStatisticsEntity>> getMunicipalStatistics(String muniId) async {
    try {
      final statistics = await remoteDataSource.getMunicipalStatistics(muniId);
      return Right(statistics.toEntity());
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas municipales: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getReportsStatistics({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Como no existe este método específico, obtenemos las estadísticas generales
      // y extraemos la información de reportes
      final statistics = await remoteDataSource.getMunicipalStatistics(muniId);
      
      final reportsStats = {
        'totalReports': statistics.totalReports,
        'resolvedReports': statistics.resolvedReports,
        'pendingReports': statistics.pendingReports,
        'inProgressReports': statistics.inProgressReports,
        'lastUpdated': statistics.lastUpdated.toIso8601String(),
      };
      
      return Right(reportsStats);
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas de reportes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getInfractionsStatistics({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Como no existe este método específico, obtenemos las estadísticas generales
      // y extraemos la información de infracciones
      final statistics = await remoteDataSource.getMunicipalStatistics(muniId);
      
      final infractionsStats = {
        'totalInfractions': statistics.totalInfractions,
        'lastUpdated': statistics.lastUpdated.toIso8601String(),
      };
      
      return Right(infractionsStats);
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas de infracciones: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> assignReportToInspector({
    required String reportId,
    required String inspectorId,
    required String adminId,
  }) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos un placeholder
      throw UnimplementedError('assignReportToInspector no implementado aún');
    } catch (e) {
      return Left(ServerFailure('Error al asignar reporte: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateReportPriority({
    required String reportId,
    required String priority,
    required String adminId,
  }) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos un placeholder
      throw UnimplementedError('updateReportPriority no implementado aún');
    } catch (e) {
      return Left(ServerFailure('Error al actualizar prioridad del reporte: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMunicipalSettings({
    required String muniId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos un placeholder
      throw UnimplementedError('updateMunicipalSettings no implementado aún');
    } catch (e) {
      return Left(ServerFailure('Error al actualizar configuración municipal: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMunicipalSettings(String muniId) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos configuración por defecto
      final defaultSettings = {
        'muniId': muniId,
        'allowCitizenReports': true,
        'requireReportApproval': false,
        'maxReportsPerDay': 10,
        'workingHours': {
          'start': '08:00',
          'end': '17:00',
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      return Right(defaultSettings);
    } catch (e) {
      return Left(ServerFailure('Error al obtener configuración municipal: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportReportsToCSV({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos un CSV básico
      const csvHeader = 'ID,Título,Estado,Fecha Creación\n';
      final csvData = 'sample_id,Reporte de ejemplo,pending,${DateTime.now().toIso8601String()}\n';
      
      return Right(csvHeader + csvData);
    } catch (e) {
      return Left(ServerFailure('Error al exportar reportes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportInfractionsToCSV({
    required String muniId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Este método no está implementado en el data source aún
      // Por ahora retornamos un CSV básico
      const csvHeader = 'ID,Tipo,Monto,Fecha\n';
      final csvData = 'sample_id,Estacionamiento,50000,${DateTime.now().toIso8601String()}\n';
      
      return Right(csvHeader + csvData);
    } catch (e) {
      return Left(ServerFailure('Error al exportar infracciones: ${e.toString()}'));
    }
  }
}