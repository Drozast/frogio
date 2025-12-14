// lib/features/citizen/presentation/bloc/report/enhanced_report_event.dart
import 'package:equatable/equatable.dart';

import '../../../domain/usecases/reports/enhanced_report_use_cases.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportsEvent extends ReportEvent {
  final String userId;

  const LoadReportsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class StartWatchingUserReportsEvent extends ReportEvent {
  final String userId;

  const StartWatchingUserReportsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class StopWatchingReportsEvent extends ReportEvent {}

class CreateReportEvent extends ReportEvent {
  final CreateEnhancedReportParams params;

  const CreateReportEvent({required this.params});

  @override
  List<Object> get props => [params];
}

class GetReportByIdEvent extends ReportEvent {
  final String reportId;

  const GetReportByIdEvent({required this.reportId});

  @override
  List<Object> get props => [reportId];
}

class UpdateReportStatusEvent extends ReportEvent {
  final String reportId;
  final String status;
  final String? comment;
  final String userId;

  const UpdateReportStatusEvent({
    required this.reportId,
    required this.status,
    this.comment,
    required this.userId,
  });

  @override
  List<Object?> get props => [reportId, status, comment, userId];
}

class AssignReportEvent extends ReportEvent {
  final String reportId;
  final String assignedToId;
  final String assignedById;
  final String? note;

  const AssignReportEvent({
    required this.reportId,
    required this.assignedToId,
    required this.assignedById,
    this.note,
  });

  @override
  List<Object?> get props => [reportId, assignedToId, assignedById, note];
}

class FilterReportsEvent extends ReportEvent {
  final String filter;

  const FilterReportsEvent({required this.filter});

  @override
  List<Object> get props => [filter];
}

class SearchReportsEvent extends ReportEvent {
  final String query;

  const SearchReportsEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class AddReportResponseEvent extends ReportEvent {
  final String reportId;
  final String responderId;
  final String responderName;
  final String message;
  final bool isPublic;

  const AddReportResponseEvent({
    required this.reportId,
    required this.responderId,
    required this.responderName,
    required this.message,
    this.isPublic = true,
  });

  @override
  List<Object> get props => [reportId, responderId, responderName, message, isPublic];
}

class GetReportsByStatusEvent extends ReportEvent {
  final String status;
  final String? muniId;
  final String? assignedTo;

  const GetReportsByStatusEvent({
    required this.status,
    this.muniId,
    this.assignedTo,
  });

  @override
  List<Object?> get props => [status, muniId, assignedTo];
}