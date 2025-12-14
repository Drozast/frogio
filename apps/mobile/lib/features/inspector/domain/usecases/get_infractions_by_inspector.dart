// lib/features/inspector/domain/usecases/get_infractions_by_inspector.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/infraction_entity.dart';
import '../repositories/infraction_repository.dart';

class GetInfractionsByInspector implements UseCase<List<InfractionEntity>, String> {
  final InfractionRepository repository;

  GetInfractionsByInspector(this.repository);

  @override
  Future<Either<Failure, List<InfractionEntity>>> call(String inspectorId) {
    return repository.getInfractionsByInspector(inspectorId);
  }
}


