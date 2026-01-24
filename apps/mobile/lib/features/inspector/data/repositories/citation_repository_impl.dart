// lib/features/inspector/data/repositories/citation_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/citation_entity.dart';
import '../../domain/repositories/citation_repository.dart';
import '../datasources/citation_remote_data_source.dart';
import '../models/citation_model.dart';

class CitationRepositoryImpl implements CitationRepository {
  final CitationRemoteDataSource remoteDataSource;

  CitationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CitationEntity>>> getCitations({
    CitationFilters? filters,
  }) async {
    try {
      final citations = await remoteDataSource.getCitations(filters: filters);
      return Right(citations.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitationEntity>> getCitationById(String id) async {
    try {
      final citation = await remoteDataSource.getCitationById(id);
      return Right(citation.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitationEntity>> createCitation(CreateCitationDto dto) async {
    try {
      final citation = await remoteDataSource.createCitation(dto);
      return Right(citation.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CitationEntity>> updateCitation(
    String id,
    UpdateCitationDto dto,
  ) async {
    try {
      final citation = await remoteDataSource.updateCitation(id, dto);
      return Right(citation.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCitation(String id) async {
    try {
      await remoteDataSource.deleteCitation(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CitationEntity>>> getMyCitations() async {
    try {
      final citations = await remoteDataSource.getMyCitations();
      return Right(citations.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateCitationNumber() async {
    try {
      final number = await remoteDataSource.generateCitationNumber();
      return Right(number);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadPhotos(List<File> photos) async {
    try {
      final urls = await remoteDataSource.uploadPhotos(photos);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
