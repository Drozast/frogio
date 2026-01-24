// lib/features/inspector/domain/repositories/citation_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/citation_model.dart';
import '../entities/citation_entity.dart';

abstract class CitationRepository {
  Future<Either<Failure, List<CitationEntity>>> getCitations({
    CitationFilters? filters,
  });

  Future<Either<Failure, CitationEntity>> getCitationById(String id);

  Future<Either<Failure, CitationEntity>> createCitation(CreateCitationDto dto);

  Future<Either<Failure, CitationEntity>> updateCitation(
    String id,
    UpdateCitationDto dto,
  );

  Future<Either<Failure, void>> deleteCitation(String id);

  Future<Either<Failure, List<CitationEntity>>> getMyCitations();

  Future<Either<Failure, String>> generateCitationNumber();

  Future<Either<Failure, List<String>>> uploadPhotos(List<File> photos);
}
