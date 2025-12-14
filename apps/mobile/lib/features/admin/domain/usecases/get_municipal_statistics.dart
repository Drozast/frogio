// lib/features/admin/domain/usecases/get_municipal_statistics.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/municipal_statistics_entity.dart';
import '../repositories/admin_repository.dart';

class GetMunicipalStatistics implements UseCase<MunicipalStatisticsEntity, String> {
  final AdminRepository repository;

  GetMunicipalStatistics(this.repository);

  @override
  Future<Either<Failure, MunicipalStatisticsEntity>> call(String muniId) async {
    try {
      if (muniId.isEmpty) {
        return const Left(ServerFailure('ID de municipalidad requerido'));
      }

      return await repository.getMunicipalStatistics(muniId);
    } catch (e) {
      return Left(ServerFailure('Error al obtener estadísticas: ${e.toString()}'));
    }
  }
}