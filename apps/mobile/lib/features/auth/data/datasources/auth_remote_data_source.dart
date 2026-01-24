// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'dart:io';

import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> registerWithEmailAndPassword(String email, String password, String name, String rut);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> forgotPassword(String email);

  // Métodos para perfil completo
  Future<UserEntity> updateUserProfile({
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
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<UserEntity> updateProfileImage(String userId, String imageUrl);

  /// Obtener URL fresca para un archivo dado su fileId
  Future<String?> getFileUrl(String fileId);
}