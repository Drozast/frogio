import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/panic_alert_entity.dart';
import '../repositories/panic_repository.dart';

class CancelPanicAlert {
  final PanicRepository repository;

  CancelPanicAlert(this.repository);

  Future<Either<Failure, PanicAlertEntity>> call(String alertId) {
    return repository.cancelPanicAlert(alertId);
  }
}
