import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/municipal_statistics_model.dart';
import '../models/query_model.dart';
import '../models/user_model.dart';
import 'admin_remote_data_source.dart';

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  AdminRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<List<QueryModel>> getAllPendingQueries(String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('queries')
          .where('muniId', isEqualTo: muniId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QueryModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener consultas pendientes: $e');
    }
  }

  @override
  Future<void> answerQuery(
    String queryId,
    String response,
    String responderId, {
    required String adminId,
    List<String>? attachments,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'response': response,
        'responderId': responderId,
        'adminId': adminId,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      };

      // Agregar archivos adjuntos si existen
      if (attachments != null && attachments.isNotEmpty) {
        updateData['attachments'] = attachments;
      }

      await firestore.collection('queries').doc(queryId).update(updateData);
    } catch (e) {
      throw Exception('Error al responder consulta: $e');
    }
  }

  @override
  Future<MunicipalStatisticsModel> getMunicipalStatistics(String muniId) async {
    try {
      // Obtener estadísticas de reportes
      final reportsSnapshot = await firestore
          .collection('reports')
          .where('muniId', isEqualTo: muniId)
          .get();

      final totalReports = reportsSnapshot.docs.length;
      final resolvedReports = reportsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'resolved')
          .length;
      final pendingReports = reportsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;
      final inProgressReports = reportsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'in_progress')
          .length;

      // Obtener estadísticas de consultas
      final queriesSnapshot = await firestore
          .collection('queries')
          .where('muniId', isEqualTo: muniId)
          .get();

      final totalQueries = queriesSnapshot.docs.length;
      final answeredQueries = queriesSnapshot.docs
          .where((doc) => doc.data()['status'] == 'answered')
          .length;

      // Obtener estadísticas de infracciones
      final infractionsSnapshot = await firestore
          .collection('infractions')
          .where('muniId', isEqualTo: muniId)
          .get();

      final totalInfractions = infractionsSnapshot.docs.length;

      // Obtener estadísticas de usuarios activos
      final usersSnapshot = await firestore
          .collection('users')
          .where('muniId', isEqualTo: muniId)
          .get();

      final activeUsers = usersSnapshot.docs.length;
      final inspectors = usersSnapshot.docs
          .where((doc) => doc.data()['role'] == 'inspector')
          .length;

      return MunicipalStatisticsModel(
        totalReports: totalReports,
        resolvedReports: resolvedReports,
        pendingReports: pendingReports,
        inProgressReports: inProgressReports,
        totalQueries: totalQueries,
        answeredQueries: answeredQueries,
        totalInfractions: totalInfractions,
        activeUsers: activeUsers,
        inspectors: inspectors,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<List<UserModel>> getAllUsers(String muniId) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('muniId', isEqualTo: muniId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  @override
  Future<List<UserModel>> getUsersByRole({
    required String muniId,
    required String role,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection('users')
          .where('muniId', isEqualTo: muniId)
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: $e');
    }
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar rol de usuario: $e');
    }
  }

  @override
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar estado de usuario: $e');
    }
  }
}