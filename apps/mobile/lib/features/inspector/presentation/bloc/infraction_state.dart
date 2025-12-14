part of 'infraction_bloc.dart';

abstract class InfractionState extends Equatable {
  const InfractionState();

  @override
  List<Object?> get props => [];
}

class InfractionInitial extends InfractionState {}

class InfractionLoading extends InfractionState {}

class InfractionImageUploading extends InfractionState {}

class InfractionsLoaded extends InfractionState {
  final List<InfractionEntity> infractions;

  const InfractionsLoaded({required this.infractions});

  @override
  List<Object> get props => [infractions];
}

class InfractionCreated extends InfractionState {
  final InfractionEntity infraction;

  const InfractionCreated({required this.infraction});

  @override
  List<Object> get props => [infraction];
}

class InfractionStatusUpdated extends InfractionState {}

class InfractionImageUploaded extends InfractionState {
  final String imageUrl;

  const InfractionImageUploaded({required this.imageUrl});

  @override
  List<Object> get props => [imageUrl];
}

class InfractionSelected extends InfractionState {
  final InfractionEntity infraction;

  const InfractionSelected({required this.infraction});

  @override
  List<Object> get props => [infraction];
}

class InfractionError extends InfractionState {
  final String message;

  const InfractionError({required this.message});

  @override
  List<Object> get props => [message];
}