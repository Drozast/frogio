// lib/features/auth/domain/repositories/auth_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(String email, String password);
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword(String email, String password, String name);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> forgotPassword(String email);
  
  // Nuevos métodos para perfil
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? address,
  });
  Future<Either<Failure, String>> uploadProfileImage(String userId, File imageFile);
  Future<Either<Failure, UserEntity>> updateProfileImage(String userId, String imageUrl);
}