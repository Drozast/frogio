import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/panic_alert_entity.dart';

abstract class PanicRepository {
  Future<Either<Failure, PanicAlertEntity>> createPanicAlert({
    required double latitude,
    required double longitude,
    String? address,
    String? message,
    String? contactPhone,
  });

  Future<Either<Failure, PanicAlertEntity>> cancelPanicAlert(String alertId);

  Future<Either<Failure, PanicAlertEntity?>> getActiveAlert();
}
