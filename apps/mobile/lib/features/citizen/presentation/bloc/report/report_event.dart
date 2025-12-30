// lib/features/citizen/presentation/bloc/report/report_event.dart
import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/enhanced_report_entity.dart';

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

class LoadReportDetailsEvent extends ReportEvent {
  final String reportId;
  
  const LoadReportDetailsEvent({required this.reportId});
  
  @override
  List<Object> get props => [reportId];
}

class CreateReportEvent extends ReportEvent {
  final String title;
  final String description;
  final String category;
  final LocationData location;
  final String userId;
  final List<File> images;
  
  const CreateReportEvent({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.userId,
    required this.images,
  });
  
  @override
  List<Object> get props => [title, description, category, location, userId, images];
}

class FilterReportsEvent extends ReportEvent {
  final String filter;
  
  const FilterReportsEvent({required this.filter});
  
  @override
  List<Object> get props => [filter];
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

class AddReportResponseEvent extends ReportEvent {
  final String reportId;
  final String responderId;
  final String responderName;
  final String message;
  final List<File>? attachments;
  final bool isPublic;
  
  const AddReportResponseEvent({
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

// Agregar al final del archivo:

class AssignReportEvent extends ReportEvent {
  final String reportId;
  final String inspectorId;
  final String? note;
  
  const AssignReportEvent({
    required this.reportId,
    required this.inspectorId,
    this.note,
  });
  
  @override
  List<Object?> get props => [reportId, inspectorId, note];
}