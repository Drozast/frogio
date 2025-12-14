part of 'infraction_bloc.dart';

abstract class InfractionEvent extends Equatable {
  const InfractionEvent();

  @override
  List<Object?> get props => [];
}

class LoadInfractionsByInspector extends InfractionEvent {
  final String inspectorId;

  const LoadInfractionsByInspector({required this.inspectorId});

  @override
  List<Object> get props => [inspectorId];
}

class CreateInfractionEvent extends InfractionEvent {
  final InfractionEntity infraction;

  const CreateInfractionEvent({required this.infraction});

  @override
  List<Object> get props => [infraction];
}

class UpdateInfractionStatusEvent extends InfractionEvent {
  final String infractionId;
  final String status;

  const UpdateInfractionStatusEvent({
    required this.infractionId,
    required this.status,
  });

  @override
  List<Object> get props => [infractionId, status];
}

class UploadInfractionImageEvent extends InfractionEvent {
  final String infractionId;
  final File image;

  const UploadInfractionImageEvent({
    required this.infractionId,
    required this.image,
  });

  @override
  List<Object> get props => [infractionId, image];
}

class SelectInfraction extends InfractionEvent {
  final InfractionEntity infraction;

  const SelectInfraction({required this.infraction});

  @override
  List<Object> get props => [infraction];
}

class ClearSelectedInfraction extends InfractionEvent {}