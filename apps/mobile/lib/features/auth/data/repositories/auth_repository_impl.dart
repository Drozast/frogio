// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  AuthRepositoryImpl({required this.remoteDataSource});
  
  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword(String email, String password) async {
    try {
      final user = await remoteDataSource.signInWithEmailAndPassword(email, password);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      final user = await remoteDataSource.registerWithEmailAndPassword(email, password, name);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final user = await remoteDataSource.updateUserProfile(
        userId: userId,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(String userId, File imageFile) async {
    try {
      final imageUrl = await remoteDataSource.uploadProfileImage(userId, imageFile);
      return Right(imageUrl);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfileImage(String userId, String imageUrl) async {
    try {
      final user = await remoteDataSource.updateProfileImage(userId, imageUrl);
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }
}