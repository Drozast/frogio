import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/panic_alert_entity.dart';
import '../../domain/repositories/panic_repository.dart';
import '../datasources/panic_remote_data_source.dart';

class PanicRepositoryImpl implements PanicRepository {
  final PanicRemoteDataSource remoteDataSource;

  PanicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, PanicAlertEntity>> createPanicAlert({
    required double latitude,
    required double longitude,
    String? address,
    String? message,
    String? contactPhone,
  }) async {
    try {
      final alert = await remoteDataSource.createPanicAlert(
        latitude: latitude,
        longitude: longitude,
        address: address,
        message: message,
        contactPhone: contactPhone,
      );
      return Right(alert);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PanicAlertEntity>> cancelPanicAlert(String alertId) async {
    try {
      final alert = await remoteDataSource.cancelPanicAlert(alertId);
      return Right(alert);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PanicAlertEntity?>> getActiveAlert() async {
    try {
      final alert = await remoteDataSource.getActiveAlert();
      return Right(alert);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
