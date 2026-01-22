import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/panic_alert_entity.dart';
import '../repositories/panic_repository.dart';

class SendPanicAlert {
  final PanicRepository repository;

  SendPanicAlert(this.repository);

  Future<Either<Failure, PanicAlertEntity>> call(SendPanicAlertParams params) {
    return repository.createPanicAlert(
      latitude: params.latitude,
      longitude: params.longitude,
      address: params.address,
      message: params.message,
      contactPhone: params.contactPhone,
    );
  }
}

class SendPanicAlertParams {
  final double latitude;
  final double longitude;
  final String? address;
  final String? message;
  final String? contactPhone;

  SendPanicAlertParams({
    required this.latitude,
    required this.longitude,
    this.address,
    this.message,
    this.contactPhone,
  });
}
