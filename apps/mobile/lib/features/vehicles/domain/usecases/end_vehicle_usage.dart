import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/vehicle_repository.dart';

class EndVehicleUsage extends UseCase<void, EndVehicleUsageParams> {
  final VehicleRepository repository;

  EndVehicleUsage({required this.repository});

  @override
  Future<Either<Failure, void>> call(EndVehicleUsageParams params) async {
    return await repository.endVehicleUsage(
      logId: params.logId,
      endKm: params.endKm,
      observations: params.observations,
      attachments: params.attachments,
    );
  }
}

class EndVehicleUsageParams extends Equatable {
  final String logId;
  final double endKm;
  final String? observations;
  final List<String>? attachments;

  const EndVehicleUsageParams({
    required this.logId,
    required this.endKm,
    this.observations,
    this.attachments,
  });

  @override
  List<Object?> get props => [logId, endKm, observations, attachments];
}