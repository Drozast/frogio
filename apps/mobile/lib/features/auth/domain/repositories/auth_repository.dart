// lib/features/auth/domain/repositories/auth_repository.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/family_member_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(String email, String password);
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword(String email, String password, String name, String rut);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> forgotPassword(String email);

  // Métodos para perfil completo
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? rut,
    String? phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    String? referenceNotes,
    List<FamilyMemberEntity>? familyMembers,
  });
  Future<Either<Failure, String>> uploadProfileImage(String userId, File imageFile);
  Future<Either<Failure, UserEntity>> updateProfileImage(String userId, String imageUrl);
}