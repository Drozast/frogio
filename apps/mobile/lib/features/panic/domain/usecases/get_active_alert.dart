import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/panic_alert_entity.dart';
import '../repositories/panic_repository.dart';

class GetActiveAlert {
  final PanicRepository repository;

  GetActiveAlert(this.repository);

  Future<Either<Failure, PanicAlertEntity?>> call() {
    return repository.getActiveAlert();
  }
}
