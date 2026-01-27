import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_panic_alert.dart';
import '../../domain/usecases/get_active_alert.dart';
import '../../domain/usecases/send_panic_alert.dart';
import 'panic_event.dart';
import 'panic_state.dart';

class PanicBloc extends Bloc<PanicEvent, PanicState> {
  final SendPanicAlert sendPanicAlert;
  final CancelPanicAlert cancelPanicAlert;
  final GetActiveAlert getActiveAlert;

  PanicBloc({
    required this.sendPanicAlert,
    required this.cancelPanicAlert,
    required this.getActiveAlert,
  }) : super(const PanicInitial()) {
    on<SendPanicAlertEvent>(_onSendPanicAlert);
    on<CancelPanicAlertEvent>(_onCancelPanicAlert);
    on<LoadActiveAlertEvent>(_onLoadActiveAlert);
    on<ResetPanicStateEvent>(_onResetState);
  }

  Future<void> _onSendPanicAlert(
    SendPanicAlertEvent event,
    Emitter<PanicState> emit,
  ) async {
    emit(const PanicLoading());

    final result = await sendPanicAlert(
      SendPanicAlertParams(
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        message: event.message,
        contactPhone: event.contactPhone,
      ),
    );

    result.fold(
      (failure) => emit(PanicError(message: failure.message)),
      (alert) => emit(PanicAlertSent(alert: alert)),
    );
  }

  Future<void> _onCancelPanicAlert(
    CancelPanicAlertEvent event,
    Emitter<PanicState> emit,
  ) async {
    emit(const PanicLoading());

    final result = await cancelPanicAlert(event.alertId);

    result.fold(
      (failure) => emit(PanicError(message: failure.message)),
      (_) => emit(const PanicAlertCancelled()),
    );
  }

  Future<void> _onLoadActiveAlert(
    LoadActiveAlertEvent event,
    Emitter<PanicState> emit,
  ) async {
    final result = await getActiveAlert();

    result.fold(
      (_) {}, // Silenciar errores al cargar alerta activa
      (alert) {
        if (alert != null) {
          emit(PanicAlertActive(alert: alert));
        }
      },
    );
  }

  void _onResetState(
    ResetPanicStateEvent event,
    Emitter<PanicState> emit,
  ) {
    emit(const PanicInitial());
  }
}
