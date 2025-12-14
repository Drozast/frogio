// lib/features/citizen/domain/usecases/reports/enhanced_report_use_cases.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/enhanced_report_entity.dart';
import '../../repositories/enhanced_report_repository.dart';

// CREATE REPORT
class CreateEnhancedReport implements UseCase<String, CreateEnhancedReportParams> {
  final ReportRepository repository;
  CreateEnhancedReport(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateEnhancedReportParams params) {
    return repository.createReport(CreateReportParams(
      title: params.title,
      description: params.description,
      category: params.category,
      references: params.references,
      location: params.location,
      userId: params.userId,
      priority: params.priority,
      attachments: params.attachments,
    ));
  }
}

class CreateEnhancedReportParams extends Equatable {
  final String title;
  final String description;
  final String category;
  final String? references;
  final LocationData location;
  final String userId;
  final Priority priority;
  final List<File> attachments;

  const CreateEnhancedReportParams({
    required this.title,
    required this.description,
    required this.category,
    this.references,
    required this.location,
    required this.userId,
    this.priority = Priority.medium,
    this.attachments = const [],
  });

  @override
  List<Object?> get props => [title, description, category, references, location, userId, priority, attachments];
}

// GET REPORTS BY USER
class GetEnhancedReportsByUser implements UseCase<List<ReportEntity>, String> {
  final ReportRepository repository;
  GetEnhancedReportsByUser(this.repository);

  @override
  Future<Either<Failure, List<ReportEntity>>> call(String userId) {
    return repository.getReportsByUser(userId);
  }
}

// GET REPORT BY ID
class GetEnhancedReportById implements UseCase<ReportEntity, String> {
  final ReportRepository repository;
  GetEnhancedReportById(this.repository);

  @override
  Future<Either<Failure, ReportEntity>> call(String reportId) {
    return repository.getReportById(reportId);
  }
}

// UPDATE REPORT STATUS
class UpdateReportStatus implements UseCase<void, UpdateReportStatusParams> {
  final ReportRepository repository;
  UpdateReportStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateReportStatusParams params) {
    return repository.updateReportStatus(
      reportId: params.reportId,
      status: params.status,
      comment: params.comment,
      userId: params.userId,
    );
  }
}

class UpdateReportStatusParams extends Equatable {
  final String reportId;
  final ReportStatus status;
  final String? comment;
  final String userId;

  const UpdateReportStatusParams({
    required this.reportId,
    required this.status,
    this.comment,
    required this.userId,
  });

  @override
  List<Object?> get props => [reportId, status, comment, userId];
}

// ADD REPORT RESPONSE
class AddReportResponse implements UseCase<void, AddReportResponseParams> {
  final ReportRepository repository;
  AddReportResponse(this.repository);

  @override
  Future<Either<Failure, void>> call(AddReportResponseParams params) {
    return repository.addResponse(
      reportId: params.reportId,
      responderId: params.responderId,
      responderName: params.responderName,
      message: params.message,
      attachments: params.attachments,
      isPublic: params.isPublic,
    );
  }
}

class AddReportResponseParams extends Equatable {
  final String reportId;
  final String responderId;
  final String responderName;
  final String message;
  final List<File>? attachments;
  final bool isPublic;

  const AddReportResponseParams({
    required this.reportId,
    required this.responderId,
    required this.responderName,
    required this.message,
    this.attachments,
    this.isPublic = true,
  });

  @override
  List<Object?> get props => [reportId, responderId, responderName, message, attachments, isPublic];
}

// GET REPORTS BY STATUS
class GetReportsByStatus implements UseCase<List<ReportEntity>, GetReportsByStatusParams> {
  final ReportRepository repository;
  GetReportsByStatus(this.repository);

  @override
  Future<Either<Failure, List<ReportEntity>>> call(GetReportsByStatusParams params) {
    return repository.getReportsByStatus(
      params.status,
      muniId: params.muniId,
      assignedTo: params.assignedTo,
    );
  }
}

class GetReportsByStatusParams extends Equatable {
  final ReportStatus status;
  final String? muniId;
  final String? assignedTo;

  const GetReportsByStatusParams({
    required this.status,
    this.muniId,
    this.assignedTo,
  });

  @override
  List<Object?> get props => [status, muniId, assignedTo];
}

// ASSIGN REPORT
class AssignReport implements UseCase<void, AssignReportParams> {
  final ReportRepository repository;
  AssignReport(this.repository);

  @override
  Future<Either<Failure, void>> call(AssignReportParams params) {
    return repository.assignReport(
      reportId: params.reportId,
      assignedToId: params.assignedToId,
      assignedById: params.assignedById,
    );
  }
}

class AssignReportParams extends Equatable {
  final String reportId;
  final String assignedToId;
  final String assignedById;

  const AssignReportParams({
    required this.reportId,
    required this.assignedToId,
    required this.assignedById,
  });

  @override
  List<Object> get props => [reportId, assignedToId, assignedById];
}

// WATCH REPORTS BY USER (Stream)
class WatchReportsByUser implements UseCase<Stream<List<ReportEntity>>, String> {
  final ReportRepository repository;
  WatchReportsByUser(this.repository);

  @override
  Future<Either<Failure, Stream<List<ReportEntity>>>> call(String userId) async {
    try {
      final stream = repository.watchReportsByUser(userId);
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// WATCH REPORTS BY STATUS (Stream)
class WatchReportsByStatus implements UseCase<Stream<List<ReportEntity>>, WatchReportsByStatusParams> {
  final ReportRepository repository;
  WatchReportsByStatus(this.repository);

  @override
  Future<Either<Failure, Stream<List<ReportEntity>>>> call(WatchReportsByStatusParams params) async {
    try {
      final stream = repository.watchReportsByStatus(params.status, params.muniId);
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class WatchReportsByStatusParams extends Equatable {
  final ReportStatus status;
  final String muniId;

  const WatchReportsByStatusParams({
    required this.status,
    required this.muniId,
  });

  @override
  List<Object> get props => [status, muniId];
}