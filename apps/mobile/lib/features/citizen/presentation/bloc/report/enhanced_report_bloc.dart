// lib/features/citizen/presentation/bloc/report/enhanced_report_bloc.dart
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/enhanced_report_entity.dart';
import '../../../domain/usecases/reports/enhanced_report_use_cases.dart';
import 'enhanced_report_event.dart';
import 'enhanced_report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final CreateEnhancedReport createReport;
  final GetEnhancedReportsByUser getReportsByUser;
  final GetEnhancedReportById getReportById;
  final UpdateReportStatus updateReportStatus;
  final AddReportResponse addReportResponse;
  final GetReportsByStatus getReportsByStatus;
  final AssignReport assignReport;
  final WatchReportsByUser watchReportsByUser;
  final WatchReportsByStatus watchReportsByStatus;

  StreamSubscription<List<ReportEntity>>? _reportsSubscription;

  ReportBloc({
    required this.createReport,
    required this.getReportsByUser,
    required this.getReportById,
    required this.updateReportStatus,
    required this.addReportResponse,
    required this.getReportsByStatus,
    required this.assignReport,
    required this.watchReportsByUser,
    required this.watchReportsByStatus,
  }) : super(ReportInitial()) {
    on<LoadReportsEvent>(_onLoadReports);
    on<StartWatchingUserReportsEvent>(_onStartWatchingUserReports);
    on<StopWatchingReportsEvent>(_onStopWatchingReports);
    on<CreateReportEvent>(_onCreateReport);
    on<GetReportByIdEvent>(_onGetReportById);
    on<UpdateReportStatusEvent>(_onUpdateReportStatus);
    on<AssignReportEvent>(_onAssignReport);
    on<FilterReportsEvent>(_onFilterReports);
    on<SearchReportsEvent>(_onSearchReports);
    on<AddReportResponseEvent>(_onAddReportResponse);
    on<GetReportsByStatusEvent>(_onGetReportsByStatus);
    on<_ReportsUpdatedEvent>((event, emit) => _onReportsUpdated(event.reports));
  }

  Future<void> _onLoadReports(
    LoadReportsEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());

    final result = await getReportsByUser(event.userId);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (reports) => emit(ReportsLoaded(reports: reports)),
    );
  }

  Future<void> _onStartWatchingUserReports(
    StartWatchingUserReportsEvent event,
    Emitter<ReportState> emit,
  ) async {
    await _reportsSubscription?.cancel();

    final result = await watchReportsByUser(event.userId);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (stream) {
        _reportsSubscription = stream.listen(
          (reports) => add(_ReportsUpdatedEvent(reports: reports)),
        );
      },
    );
  }

  void _onStopWatchingReports(
    StopWatchingReportsEvent event,
    Emitter<ReportState> emit,
  ) {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
  }

  Future<void> _onCreateReport(
    CreateReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportCreating());

    // Validaciones
    final validationErrors = _validateReportParams(event.params);
    if (validationErrors.isNotEmpty) {
      emit(ReportValidationError(errors: validationErrors));
      return;
    }

    final result = await createReport(event.params);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (reportId) => emit(ReportCreated(reportId: reportId)),
    );
  }

  Future<void> _onGetReportById(
    GetReportByIdEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());

    final result = await getReportById(event.reportId);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (report) => emit(ReportLoaded(report: report)),
    );
  }

  Future<void> _onUpdateReportStatus(
    UpdateReportStatusEvent event,
    Emitter<ReportState> emit,
  ) async {
    final params = UpdateReportStatusParams(
      reportId: event.reportId,
      status: _stringToReportStatus(event.status),
      comment: event.comment,
      userId: event.userId,
    );

    final result = await updateReportStatus(params);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (_) {
        // Recargar el reporte después de actualizar
        add(GetReportByIdEvent(reportId: event.reportId));
      },
    );
  }

  Future<void> _onAssignReport(
    AssignReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportAssigning());

    final params = AssignReportParams(
      reportId: event.reportId,
      assignedToId: event.assignedToId,
      assignedById: event.assignedById,
    );

    final result = await assignReport(params);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (_) => emit(ReportAssigned(
        reportId: event.reportId,
        assignedToId: event.assignedToId,
      )),
    );
  }

  void _onFilterReports(
    FilterReportsEvent event,
    Emitter<ReportState> emit,
  ) {
    if (state is ReportsLoaded) {
      final currentState = state as ReportsLoaded;
      
      List<ReportEntity> filteredReports;
      
      if (event.filter == 'Todas') {
        filteredReports = currentState.reports;
      } else {
        filteredReports = currentState.reports
            .where((report) => report.status.displayName == event.filter)
            .toList();
      }

      emit(currentState.copyWith(
        filteredReports: filteredReports,
        currentFilter: event.filter,
      ));
    }
  }

  void _onSearchReports(
    SearchReportsEvent event,
    Emitter<ReportState> emit,
  ) {
    if (state is ReportsLoaded) {
      final currentState = state as ReportsLoaded;
      
      List<ReportEntity> filteredReports;
      
      if (event.query.isEmpty) {
        filteredReports = currentState.reports;
      } else {
        filteredReports = currentState.reports
            .where((report) =>
                report.title.toLowerCase().contains(event.query.toLowerCase()) ||
                report.description.toLowerCase().contains(event.query.toLowerCase()) ||
                report.category.toLowerCase().contains(event.query.toLowerCase()))
            .toList();
      }

      emit(currentState.copyWith(
        filteredReports: filteredReports,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onAddReportResponse(
    AddReportResponseEvent event,
    Emitter<ReportState> emit,
  ) async {
    final params = AddReportResponseParams(
      reportId: event.reportId,
      responderId: event.responderId,
      responderName: event.responderName,
      message: event.message,
      isPublic: event.isPublic,
    );

    final result = await addReportResponse(params);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (_) => emit(ReportResponseAdded(reportId: event.reportId)),
    );
  }

  Future<void> _onGetReportsByStatus(
    GetReportsByStatusEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());

    final params = GetReportsByStatusParams(
      status: _stringToReportStatus(event.status),
      muniId: event.muniId,
      assignedTo: event.assignedTo,
    );

    final result = await getReportsByStatus(params);

    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (reports) => emit(ReportsLoaded(reports: reports)),
    );
  }

  // Manejo interno de actualizaciones de stream
  void _onReportsUpdated(List<ReportEntity> reports) {
    if (state is ReportsLoaded) {
      final currentState = state as ReportsLoaded;
      
      // Aplicar filtros actuales a los nuevos datos
      List<ReportEntity> filteredReports = reports;
      
      if (currentState.currentFilter != 'Todas') {
        filteredReports = reports
            .where((report) => report.status.displayName == currentState.currentFilter)
            .toList();
      }
      
      if (currentState.searchQuery.isNotEmpty) {
        filteredReports = filteredReports
            .where((report) =>
                report.title.toLowerCase().contains(currentState.searchQuery.toLowerCase()) ||
                report.description.toLowerCase().contains(currentState.searchQuery.toLowerCase()) ||
                report.category.toLowerCase().contains(currentState.searchQuery.toLowerCase()))
            .toList();
      }
      
      emit(ReportsStreaming(reports: filteredReports));
    } else {
      emit(ReportsStreaming(reports: reports));
    }
  }

  // Métodos auxiliares
  Map<String, String> _validateReportParams(CreateEnhancedReportParams params) {
    final errors = <String, String>{};

    if (params.title.trim().isEmpty) {
      errors['title'] = 'El título es requerido';
    } else if (params.title.trim().length < 5) {
      errors['title'] = 'El título debe tener al menos 5 caracteres';
    }

    if (params.description.trim().isEmpty) {
      errors['description'] = 'La descripción es requerida';
    } else if (params.description.trim().length < 20) {
      errors['description'] = 'La descripción debe tener al menos 20 caracteres';
    }

    if (params.category.trim().isEmpty) {
      errors['category'] = 'La categoría es requerida';
    }

    if (params.userId.trim().isEmpty) {
      errors['userId'] = 'El ID de usuario es requerido';
    }

    return errors;
  }

  ReportStatus _stringToReportStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
      case 'borrador':
        return ReportStatus.draft;
      case 'submitted':
      case 'enviada':
        return ReportStatus.submitted;
      case 'reviewing':
      case 'en revisión':
        return ReportStatus.reviewing;
      case 'inprogress':
      case 'in_progress':
      case 'en proceso':
        return ReportStatus.inProgress;
      case 'resolved':
      case 'resuelta':
        return ReportStatus.resolved;
      case 'rejected':
      case 'rechazada':
        return ReportStatus.rejected;
      case 'archived':
      case 'archivada':
        return ReportStatus.archived;
      default:
        return ReportStatus.draft;
    }
  }

  @override
  Future<void> close() {
    _reportsSubscription?.cancel();
    return super.close();
  }
}

// Evento interno para manejar actualizaciones del stream
class _ReportsUpdatedEvent extends ReportEvent {
  final List<ReportEntity> reports;

  const _ReportsUpdatedEvent({required this.reports});

  @override
  List<Object> get props => [reports];
}