// lib/features/citizen/presentation/bloc/report/report_state.dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/enhanced_report_entity.dart';

abstract class ReportState extends Equatable {
  const ReportState();
  
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportsLoaded extends ReportState {
  final List<ReportEntity> reports;
  final List<ReportEntity> filteredReports;
  final String currentFilter;
  
  const ReportsLoaded({
    required this.reports,
    List<ReportEntity>? filteredReports,
    this.currentFilter = 'Todas',
  }) : filteredReports = filteredReports ?? reports;
  
  @override
  List<Object> get props => [reports, filteredReports, currentFilter];
}

class ReportDetailLoaded extends ReportState {
  final ReportEntity report;
  
  const ReportDetailLoaded({required this.report});
  
  @override
  List<Object> get props => [report];
}

class SubmittingReport extends ReportState {}

class ReportCreated extends ReportState {
  final String reportId;
  
  const ReportCreated({required this.reportId});
  
  @override
  List<Object> get props => [reportId];
}

class ReportError extends ReportState {
  final String message;
  
  const ReportError({required this.message});
  
  @override
  List<Object> get props => [message];
}