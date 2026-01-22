import 'package:equatable/equatable.dart';

import '../../domain/entities/panic_alert_entity.dart';

abstract class PanicState extends Equatable {
  const PanicState();

  @override
  List<Object?> get props => [];
}

class PanicInitial extends PanicState {
  const PanicInitial();
}

class PanicLoading extends PanicState {
  const PanicLoading();
}

class PanicAlertSent extends PanicState {
  final PanicAlertEntity alert;

  const PanicAlertSent({required this.alert});

  @override
  List<Object?> get props => [alert];
}

class PanicAlertActive extends PanicState {
  final PanicAlertEntity alert;

  const PanicAlertActive({required this.alert});

  @override
  List<Object?> get props => [alert];
}

class PanicAlertCancelled extends PanicState {
  const PanicAlertCancelled();
}

class PanicError extends PanicState {
  final String message;

  const PanicError({required this.message});

  @override
  List<Object?> get props => [message];
}
