import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../entities/vehicle_entity.dart';

class GetVehicles extends UseCase<List<VehicleEntity>, GetVehiclesParams> {
  final VehicleRepository repository;

  GetVehicles(this.repository);

  @override
  Future<Either<Failure, List<VehicleEntity>>> call(GetVehiclesParams params) async {
    return await repository.getVehicles(params.muniId);
  }
}

class GetVehiclesParams extends Equatable {
  final String muniId;

  const GetVehiclesParams({required this.muniId});

  @override
  List<Object> get props => [muniId];
}