import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/infraction_entity.dart';
import '../../domain/usecases/create_infraction.dart';
import '../../domain/usecases/get_infractions_by_inspector.dart';
import '../../domain/usecases/update_infraction_status.dart';
import '../../domain/usecases/upload_infraction_image.dart';

part 'infraction_event.dart';
part 'infraction_state.dart';

class InfractionBloc extends Bloc<InfractionEvent, InfractionState> {
  final GetInfractionsByInspector getInfractionsByInspector;
  final CreateInfraction createInfraction;
  final UpdateInfractionStatus updateInfractionStatus;
  final UploadInfractionImage uploadInfractionImage;

  InfractionBloc({
    required this.getInfractionsByInspector,
    required this.createInfraction,
    required this.updateInfractionStatus,
    required this.uploadInfractionImage,
  }) : super(InfractionInitial()) {
    on<LoadInfractionsByInspector>(_onLoadInfractionsByInspector);
    on<CreateInfractionEvent>(_onCreateInfraction);
    on<UpdateInfractionStatusEvent>(_onUpdateInfractionStatus);
    on<UploadInfractionImageEvent>(_onUploadInfractionImage);
    on<SelectInfraction>(_onSelectInfraction);
    on<ClearSelectedInfraction>(_onClearSelectedInfraction);
  }

  Future<void> _onLoadInfractionsByInspector(
    LoadInfractionsByInspector event,
    Emitter<InfractionState> emit,
  ) async {
    emit(InfractionLoading());

    try {
      final result = await getInfractionsByInspector(event.inspectorId);

      result.fold(
        (failure) => emit(InfractionError(message: failure.message)),
        (infractions) => emit(InfractionsLoaded(infractions: infractions)),
      );
    } catch (e) {
      emit(InfractionError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onCreateInfraction(
    CreateInfractionEvent event,
    Emitter<InfractionState> emit,
  ) async {
    emit(InfractionLoading());

    try {
      final result = await createInfraction(
        CreateInfractionParams(
          title: event.infraction.title,
          description: event.infraction.description,
          ordinanceRef: event.infraction.ordinanceRef,
          location: event.infraction.location,
          offenderId: event.infraction.offenderId,
          offenderName: event.infraction.offenderName,
          offenderDocument: event.infraction.offenderDocument,
          inspectorId: event.infraction.inspectorId,
          evidence: const [], // Agregar evidencia si es necesario
        ),
      );

      result.fold(
        (failure) => emit(InfractionError(message: failure.message)),
        (infractionId) => emit(InfractionCreated(infraction: event.infraction)),
      );
    } catch (e) {
      emit(InfractionError(message: 'Error al crear infracción: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateInfractionStatus(
    UpdateInfractionStatusEvent event,
    Emitter<InfractionState> emit,
  ) async {
    emit(InfractionLoading());

    try {
      final result = await updateInfractionStatus(
        UpdateInfractionStatusParams(
          infractionId: event.infractionId,
          status: InfractionStatus.values.firstWhere(
            (status) => status.name == event.status,
            orElse: () => InfractionStatus.created,
          ),
        ),
      );

      result.fold(
        (failure) => emit(InfractionError(message: failure.message)),
        (_) => emit(InfractionStatusUpdated()),
      );
    } catch (e) {
      emit(InfractionError(message: 'Error al actualizar estado: ${e.toString()}'));
    }
  }

  Future<void> _onUploadInfractionImage(
    UploadInfractionImageEvent event,
    Emitter<InfractionState> emit,
  ) async {
    emit(InfractionImageUploading());

    try {
      final result = await uploadInfractionImage(
        UploadInfractionImageParams(
          images: [event.image],
          infractionId: event.infractionId,
        ),
      );

      result.fold(
        (failure) => emit(InfractionError(message: failure.message)),
        (imageUrls) => emit(InfractionImageUploaded(imageUrl: imageUrls.first)),
      );
    } catch (e) {
      emit(InfractionError(message: 'Error al subir imagen: ${e.toString()}'));
    }
  }

  void _onSelectInfraction(
    SelectInfraction event,
    Emitter<InfractionState> emit,
  ) {
    emit(InfractionSelected(infraction: event.infraction));
  }

  void _onClearSelectedInfraction(
    ClearSelectedInfraction event,
    Emitter<InfractionState> emit,
  ) {
    emit(InfractionInitial());
  }
}