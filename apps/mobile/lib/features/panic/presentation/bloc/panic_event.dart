import 'package:equatable/equatable.dart';

abstract class PanicEvent extends Equatable {
  const PanicEvent();

  @override
  List<Object?> get props => [];
}

class SendPanicAlertEvent extends PanicEvent {
  final double latitude;
  final double longitude;
  final String? address;
  final String? message;
  final String? contactPhone;

  const SendPanicAlertEvent({
    required this.latitude,
    required this.longitude,
    this.address,
    this.message,
    this.contactPhone,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, message, contactPhone];
}

class CancelPanicAlertEvent extends PanicEvent {
  final String alertId;

  const CancelPanicAlertEvent({required this.alertId});

  @override
  List<Object?> get props => [alertId];
}

class LoadActiveAlertEvent extends PanicEvent {
  const LoadActiveAlertEvent();
}

class ResetPanicStateEvent extends PanicEvent {
  const ResetPanicStateEvent();
}
