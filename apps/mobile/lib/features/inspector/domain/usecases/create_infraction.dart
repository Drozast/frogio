// lib/features/inspector/domain/usecases/create_infraction.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/infraction_entity.dart';
import '../repositories/infraction_repository.dart';

class CreateInfraction implements UseCase<String, CreateInfractionParams> {
  final InfractionRepository repository;

  CreateInfraction(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateInfractionParams params) {
    return repository.createInfraction(
      title: params.title,
      description: params.description,
      ordinanceRef: params.ordinanceRef,
      location: params.location,
      offenderId: params.offenderId,
      offenderName: params.offenderName,
      offenderDocument: params.offenderDocument,
      inspectorId: params.inspectorId,
      evidence: params.evidence,
    );
  }
}

class CreateInfractionParams extends Equatable {
  final String title;
  final String description;
  final String ordinanceRef;
  final LocationData location;
  final String offenderId;
  final String offenderName;
  final String offenderDocument;
  final String inspectorId;
  final List<File> evidence;

  const CreateInfractionParams({
    required this.title,
    required this.description,
    required this.ordinanceRef,
    required this.location,
    required this.offenderId,
    required this.offenderName,
    required this.offenderDocument,
    required this.inspectorId,
    required this.evidence,
  });

  @override
  List<Object?> get props => [title, description, ordinanceRef, location, offenderId, offenderName, offenderDocument, inspectorId, evidence];
}