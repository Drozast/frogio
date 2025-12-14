// lib/features/auth/domain/usecases/upload_profile_image.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UploadProfileImage implements UseCase<UserEntity, UploadProfileImageParams> {
  final AuthRepository repository;

  UploadProfileImage(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UploadProfileImageParams params) async {
    try {
      // Subir imagen
      final imageUrlResult = await repository.uploadProfileImage(params.userId, params.imageFile);
      
      return imageUrlResult.fold(
        (failure) => Left(failure),
        (imageUrl) async {
          // Actualizar perfil con nueva URL
          final updateResult = await repository.updateProfileImage(params.userId, imageUrl);
          return updateResult;
        },
      );
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}

class UploadProfileImageParams extends Equatable {
  final String userId;
  final File imageFile;

  const UploadProfileImageParams({
    required this.userId,
    required this.imageFile,
  });

  @override
  List<Object> get props => [userId, imageFile];
}