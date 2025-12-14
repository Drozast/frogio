// lib/features/citizen/presentation/bloc/report/enhanced_report_state.dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/enhanced_report_entity.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportCreating extends ReportState {}

class ReportAssigning extends ReportState {}

class ReportsLoaded extends ReportState {
  final List<ReportEntity> reports;
  final List<ReportEntity> filteredReports;
  final String currentFilter;
  final String searchQuery;

  const ReportsLoaded({
    required this.reports,
    List<ReportEntity>? filteredReports,
    this.currentFilter = 'Todas',
    this.searchQuery = '',
  }) : filteredReports = filteredReports ?? reports;

  @override
  List<Object> get props => [reports, filteredReports, currentFilter, searchQuery];

  ReportsLoaded copyWith({
    List<ReportEntity>? reports,
    List<ReportEntity>? filteredReports,
    String? currentFilter,
    String? searchQuery,
  }) {
    return ReportsLoaded(
      reports: reports ?? this.reports,
      filteredReports: filteredReports ?? this.filteredReports,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ReportsStreaming extends ReportState {
  final List<ReportEntity> reports;

  const ReportsStreaming({required this.reports});

  @override
  List<Object> get props => [reports];
}

class ReportLoaded extends ReportState {
  final ReportEntity report;

  const ReportLoaded({required this.report});

  @override
  List<Object> get props => [report];
}

class ReportCreated extends ReportState {
  final String reportId;

  const ReportCreated({required this.reportId});

  @override
  List<Object> get props => [reportId];
}

class ReportUpdated extends ReportState {
  final ReportEntity report;

  const ReportUpdated({required this.report});

  @override
  List<Object> get props => [report];
}

class ReportAssigned extends ReportState {
  final String reportId;
  final String assignedToId;

  const ReportAssigned({
    required this.reportId,
    required this.assignedToId,
  });

  @override
  List<Object> get props => [reportId, assignedToId];
}

class ReportResponseAdded extends ReportState {
  final String reportId;

  const ReportResponseAdded({required this.reportId});

  @override
  List<Object> get props => [reportId];
}

class ReportError extends ReportState {
  final String message;

  const ReportError({required this.message});

  @override
  List<Object> get props => [message];
}

class ReportValidationError extends ReportState {
  final Map<String, String> errors;

  const ReportValidationError({required this.errors});

  @override
  List<Object> get props => [errors];
}