// lib/features/citizen/data/datasources/enhanced_report_remote_data_source_impl.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../models/enhanced_report_model.dart';
import 'enhanced_report_remote_data_source.dart';

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Uuid uuid;

  ReportRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    required this.uuid,
  });

  @override
  Future<List<ReportModel>> getReportsByUser(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('reports')
          .where('citizenId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar reportes: ${e.toString()}');
    }
  }

  @override
  Future<ReportModel> getReportById(String reportId) async {
    try {
      final docSnapshot = await firestore.collection('reports').doc(reportId).get();

      if (!docSnapshot.exists) {
        throw const ServerFailure('Reporte no encontrado');
      }

      return ReportModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw ServerFailure('Error al cargar reporte: ${e.toString()}');
    }
  }

  @override
  Future<String> createReport(CreateReportParams params) async {
    try {
      final reportId = uuid.v4();
      final now = DateTime.now();

      // Obtener municipio del usuario
      final userDoc = await firestore.collection('users').doc(params.userId).get();
      final userData = userDoc.data();
      final muniId = userData?['muniId'] ?? 'muni_default';

      // Subir archivos adjuntos si los hay
      List<MediaAttachment> uploadedAttachments = [];
      if (params.attachments.isNotEmpty) {
        uploadedAttachments = await _uploadAttachments(params.attachments, reportId);
      }

      // Crear historial inicial
      final initialHistory = StatusHistoryItemModel.fromEntity(
        StatusHistoryItem(
          timestamp: now,
          status: ReportStatus.submitted,
          comment: 'Reporte creado',
          userId: params.userId,
          userName: userData?['displayName'] ?? 'Usuario',
        ),
      );

      // Crear el reporte
      final report = ReportModel(
        id: reportId,
        title: params.title,
        description: params.description,
        category: params.category,
        references: params.references,
        location: params.location,
        citizenId: params.userId,
        muniId: muniId,
        status: ReportStatus.submitted,
        priority: params.priority,
        attachments: uploadedAttachments,
        createdAt: now,
        updatedAt: now,
        statusHistory: [initialHistory.toEntity()],
        responses: const [],
      );

      await firestore.collection('reports').doc(reportId).set(report.toFirestore());

      return reportId;
    } catch (e) {
      throw ServerFailure('Error al crear reporte: ${e.toString()}');
    }
  }

  @override
  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? comment,
    required String userId,
  }) async {
    try {
      final reportRef = firestore.collection('reports').doc(reportId);
      
      // Obtener datos del usuario
      final userDoc = await firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      // Crear nuevo item de historial
      final historyItem = StatusHistoryItemModel.fromEntity(
        StatusHistoryItem(
          timestamp: DateTime.now(),
          status: status,
          comment: comment ?? 'Estado actualizado',
          userId: userId,
          userName: userData?['displayName'] ?? 'Usuario',
        ),
      );

      // Actualizar reporte
      await reportRef.update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': FieldValue.arrayUnion([historyItem.toMap()]),
      });
    } catch (e) {
      throw ServerFailure('Error al actualizar estado: ${e.toString()}');
    }
  }

  @override
  Future<void> addResponse({
    required String reportId,
    required String responderId,
    required String responderName,
    required String message,
    List<File>? attachments,
    required bool isPublic,
  }) async {
    try {
      final responseId = uuid.v4();
      final now = DateTime.now();

      // Subir archivos adjuntos si los hay
      List<MediaAttachment> uploadedAttachments = [];
      if (attachments != null && attachments.isNotEmpty) {
        uploadedAttachments = await _uploadAttachments(attachments, '$reportId/responses/$responseId');
      }

      // Crear respuesta
      final response = ReportResponseModel.fromEntity(
        ReportResponse(
          id: responseId,
          responderId: responderId,
          responderName: responderName,
          message: message,
          attachments: uploadedAttachments,
          isPublic: isPublic,
          createdAt: now,
        ),
      );

      // Actualizar reporte
      await firestore.collection('reports').doc(reportId).update({
        'responses': FieldValue.arrayUnion([response.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerFailure('Error al agregar respuesta: ${e.toString()}');
    }
  }

  @override
  Future<List<ReportModel>> getReportsByStatus(
    ReportStatus status, {
    String? muniId,
    String? assignedTo,
  }) async {
    try {
      Query query = firestore
          .collection('reports')
          .where('status', isEqualTo: status.name);

      if (muniId != null) {
        query = query.where('muniId', isEqualTo: muniId);
      }

      if (assignedTo != null) {
        query = query.where('assignedToId', isEqualTo: assignedTo);
      }

      final querySnapshot = await query
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw ServerFailure('Error al cargar reportes por estado: ${e.toString()}');
    }
  }

  @override
  Future<void> assignReport({
    required String reportId,
    required String assignedToId,
    required String assignedById,
  }) async {
    try {
      // Obtener datos del inspector asignado
      final inspectorDoc = await firestore.collection('users').doc(assignedToId).get();
      final inspectorData = inspectorDoc.data();
      final inspectorName = inspectorData?['displayName'] ?? 'Inspector';

      await firestore.collection('reports').doc(reportId).update({
        'assignedToId': assignedToId,
        'assignedToName': inspectorName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Agregar entrada al historial
      await updateReportStatus(
        reportId: reportId,
        status: ReportStatus.inProgress,
        comment: 'Reporte asignado a $inspectorName',
        userId: assignedById,
      );
    } catch (e) {
      throw ServerFailure('Error al asignar reporte: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadAttachments(List<File> attachments, String reportId) async {
    try {
      final urls = <String>[];
      
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i';
        final storageRef = storage.ref().child('reports/$reportId/attachments/$fileName');
        
        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        urls.add(downloadUrl);
      }
      
      return urls;
    } catch (e) {
      throw ServerFailure('Error al subir archivos: ${e.toString()}');
    }
  }

  @override
  Stream<List<ReportModel>> watchReportsByUser(String userId) {
    return firestore
        .collection('reports')
        .where('citizenId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  @override
  Stream<List<ReportModel>> watchReportsByStatus(ReportStatus status, String muniId) {
    return firestore
        .collection('reports')
        .where('status', isEqualTo: status.name)
        .where('muniId', isEqualTo: muniId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromFirestore(doc))
            .toList());
  }

  // Métodos auxiliares privados
  
  Future<List<MediaAttachment>> _uploadAttachments(List<File> files, String path) async {
    final attachments = <MediaAttachment>[];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final attachmentId = uuid.v4();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i';
      final storageRef = storage.ref().child('reports/$path/$fileName');
      
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      final fileSize = await file.length();
      
      final attachment = MediaAttachment(
        id: attachmentId,
        url: downloadUrl,
        fileName: fileName,
        type: _getMediaTypeFromFile(file),
        fileSize: fileSize,
        uploadedAt: DateTime.now(),
      );
      
      attachments.add(attachment);
    }
    
    return attachments;
  }

  MediaType _getMediaTypeFromFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'mp4':
      case 'mov':
      case 'avi':
        return MediaType.video;
      default:
        return MediaType.image;
    }
  }
}