
// lib/features/inspector/domain/usecases/update_infraction_status.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/infraction_entity.dart';
import '../repositories/infraction_repository.dart';

class UpdateInfractionStatus implements UseCase<void, UpdateInfractionStatusParams> {
  final InfractionRepository repository;

  UpdateInfractionStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateInfractionStatusParams params) {
    return repository.updateInfractionStatus(params.infractionId, params.status, params.comment);
  }
}

class UpdateInfractionStatusParams extends Equatable {
  final String infractionId;
  final InfractionStatus status;
  final String? comment;

  const UpdateInfractionStatusParams({
    required this.infractionId,
    required this.status,
    this.comment,
  });

  @override
  List<Object?> get props => [infractionId, status, comment];
}
