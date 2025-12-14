
// lib/features/inspector/domain/usecases/upload_infraction_image.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/infraction_repository.dart';

class UploadInfractionImage implements UseCase<List<String>, UploadInfractionImageParams> {
  final InfractionRepository repository;

  UploadInfractionImage(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(UploadInfractionImageParams params) {
    return repository.uploadInfractionImages(params.images, params.infractionId);
  }
}

class UploadInfractionImageParams extends Equatable {
  final List<File> images;
  final String infractionId;

  const UploadInfractionImageParams({
    required this.images,
    required this.infractionId,
  });

  @override
  List<Object> get props => [images, infractionId];
}