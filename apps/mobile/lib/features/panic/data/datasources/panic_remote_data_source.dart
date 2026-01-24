import '../../domain/entities/panic_alert_entity.dart';

abstract class PanicRemoteDataSource {
  Future<PanicAlertEntity> createPanicAlert({
    required double latitude,
    required double longitude,
    String? address,
    String? message,
    String? contactPhone,
  });

  Future<PanicAlertEntity> cancelPanicAlert(String alertId);

  Future<PanicAlertEntity?> getActiveAlert();

  Future<int> getTodayPanicCount();
}
