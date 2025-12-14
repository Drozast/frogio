// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'dart:io';

import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> registerWithEmailAndPassword(String email, String password, String name);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> forgotPassword(String email);
  
  // Nuevos métodos para perfil
  Future<UserEntity> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? address,
  });
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<UserEntity> updateProfileImage(String userId, String imageUrl);
}