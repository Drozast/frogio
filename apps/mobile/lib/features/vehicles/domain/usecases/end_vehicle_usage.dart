import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../entities/vehicle_log_entity.dart';

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
      route: params.route,
      stops: params.stops,
    );
  }
}

class EndVehicleUsageParams extends Equatable {
  final String logId;
  final double endKm;
  final String? observations;
  final List<String>? attachments;
  final List<LocationPoint>? route;
  final List<TripStop>? stops;

  const EndVehicleUsageParams({
    required this.logId,
    required this.endKm,
    this.observations,
    this.attachments,
    this.route,
    this.stops,
  });

  @override
  List<Object?> get props => [logId, endKm, observations, attachments, route, stops];
}