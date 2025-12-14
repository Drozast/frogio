// lib/features/inspector/domain/repositories/infraction_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/infraction_entity.dart';

abstract class InfractionRepository {
  Future<Either<Failure, List<InfractionEntity>>> getInfractionsByInspector(String inspectorId);
  Future<Either<Failure, InfractionEntity>> getInfractionById(String infractionId);
  Future<Either<Failure, String>> createInfraction({
    required String title,
    required String description,
    required String ordinanceRef,
    required LocationData location,
    required String offenderId,
    required String offenderName,
    required String offenderDocument,
    required String inspectorId,
    required List<File> evidence,
  });
  Future<Either<Failure, void>> updateInfractionStatus(String infractionId, InfractionStatus status, String? comment);
  Future<Either<Failure, void>> deleteInfraction(String infractionId);
  Future<Either<Failure, List<String>>> uploadInfractionImages(List<File> images, String infractionId);
  Future<Either<Failure, void>> addSignature(String infractionId, String signatureUrl);
}