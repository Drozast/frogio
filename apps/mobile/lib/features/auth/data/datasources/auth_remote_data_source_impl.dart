// lib/features/auth/data/datasources/auth_remote_data_source_impl.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

//import '../../../../core/utils/image_helper.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.storage,
  });

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user == null) {
        throw Exception('Usuario no encontrado');
      }
      
      final userData = await _getUserData(result.user!.uid);
      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> registerWithEmailAndPassword(String email, String password, String name) async {
    try {
      final result = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user == null) {
        throw Exception('Fallo al crear usuario');
      }
      
      // Crear documento de usuario en Firestore
      final userData = {
        'email': email,
        'name': name,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await firestore.collection('users').doc(result.user!.uid).set(userData);
      
      return UserModel(
        id: result.user!.uid,
        email: email,
        name: name,
        role: 'citizen',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    
    if (user == null) {
      return null;
    }
    
    return _getUserData(user.uid);
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;

      await firestore.collection('users').doc(userId).update(updateData);
      
      return _getUserData(userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Para web, subir imagen sin compresión para evitar errores
      // La compresión se puede agregar después si es necesaria
      
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = storage.ref().child('users/$userId/profile/$fileName');
      
      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfileImage(String userId, String imageUrl) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return _getUserData(userId);
    } catch (e) {
      throw Exception('Error al actualizar imagen de perfil: ${e.toString()}');
    }
  }

  Future<UserModel> _getUserData(String userId) async {
    try {
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('Datos de usuario no encontrados');
      }
      
      return UserModel.fromFirebase(docSnapshot.data()!, userId);
    } catch (e) {
      throw Exception('Error al obtener datos de usuario: ${e.toString()}');
    }
  }

  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Usuario no encontrado');
      case 'wrong-password':
        return Exception('Contraseña incorrecta');
      case 'email-already-in-use':
        return Exception('El correo ya está en uso');
      case 'weak-password':
        return Exception('La contraseña es demasiado débil');
      case 'invalid-email':
        return Exception('Correo electrónico inválido');
      default:
        return Exception('Error de autenticación: ${e.message}');
    }
  }
}