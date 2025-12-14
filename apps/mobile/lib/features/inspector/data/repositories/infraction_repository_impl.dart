// lib/features/inspector/data/repositories/infraction_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/infraction_entity.dart';
import '../../domain/repositories/infraction_repository.dart';
import '../datasources/infraction_remote_data_source.dart';
import '../models/infraction_model.dart';

class InfractionRepositoryImpl implements InfractionRepository {
  final InfractionRemoteDataSource remoteDataSource;

  InfractionRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<InfractionEntity>>> getInfractionsByInspector(
      String inspectorId) async {
    try {
      final infractions = await remoteDataSource.getInfractionsByInspector(inspectorId);
      return Right(infractions.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Error al obtener infracciones del inspector: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InfractionEntity>> getInfractionById(String infractionId) async {
    try {
      final infraction = await remoteDataSource.getInfractionById(infractionId);
      return Right(infraction.toEntity());
    } catch (e) {
      return Left(ServerFailure('Error al obtener infracción: ${e.toString()}'));
    }
  }

  @override
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
  }) async {
    try {
      // Crear el modelo de infracción
      final model = InfractionModel(
        id: '', // Se generará en el data source
        title: title,
        description: description,
        ordinanceRef: ordinanceRef,
        location: LocationDataModel.fromEntity(location).toMap(),
        offenderId: offenderId,
        offenderName: offenderName,
        offenderDocument: offenderDocument,
        inspectorId: inspectorId,
        muniId: '', // Debería venir del contexto del usuario
        evidence: const [], // Se subirán después
        signatures: const [],
        status: InfractionStatus.created.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        historyLog: const [],
      );

      final createdInfraction = await remoteDataSource.createInfraction(model);
      
      // Subir imágenes de evidencia si las hay
      if (evidence.isNotEmpty) {
        await remoteDataSource.uploadInfractionImages(evidence, createdInfraction.id);
      }
      
      return Right(createdInfraction.id);
    } catch (e) {
      return Left(ServerFailure('Error al crear infracción: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateInfractionStatus(
      String infractionId, InfractionStatus status, String? comment) async {
    try {
      await remoteDataSource.updateInfractionStatus(infractionId, status.name, comment);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar estado de infracción: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadInfractionImages(
      List<File> images, String infractionId) async {
    try {
      final urls = await remoteDataSource.uploadInfractionImages(images, infractionId);
      return Right(urls);
    } catch (e) {
      return Left(ServerFailure('Error al subir imágenes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addSignature(
      String infractionId, String signatureUrl) async {
    try {
      await remoteDataSource.uploadSignature(infractionId, signatureUrl);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar firma: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInfraction(String infractionId) async {
    try {
      await remoteDataSource.deleteInfraction(infractionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar infracción: ${e.toString()}'));
    }
  }
}

// Clase auxiliar para manejar LocationData
class LocationDataModel extends LocationData {
  const LocationDataModel({
    required super.latitude,
    required super.longitude,
    super.address,
    required super.city,
    required super.region,
    required super.country,
  });

  factory LocationDataModel.fromEntity(LocationData entity) {
    return LocationDataModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      address: entity.address,
      city: entity.city,
      region: entity.region,
      country: entity.country,
    );
  }

  factory LocationDataModel.fromMap(Map<String, dynamic> map) {
    return LocationDataModel(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      address: map['address'],
      city: map['city'] ?? '',
      region: map['region'] ?? '',
      country: map['country'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'region': region,
      'country': country,
    };
  }
}