// lib/features/citizen/presentation/bloc/report/report_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../domain/entities/report_entity.dart';
import '../../../domain/usecases/reports/create_report.dart';
import '../../../domain/usecases/reports/get_report_by_id.dart';
import '../../../domain/usecases/reports/get_reports_by_user.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetReportsByUser getReportsByUser;
  final GetReportById getReportById;
  final CreateReport createReport;

  ReportBloc({
    required this.getReportsByUser,
    required this.getReportById,
    required this.createReport, required Object addReportResponse,
  }) : super(ReportInitial()) {
    on<LoadReportsEvent>(_onLoadReports);
    on<LoadReportDetailsEvent>(_onLoadReportDetails);
    on<CreateReportEvent>(_onCreateReport);
    on<FilterReportsEvent>(_onFilterReports);
    on<UpdateReportStatusEvent>(_onUpdateReportStatus);
    on<AddReportResponseEvent>(_onAddReportResponse);
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

  Future<void> _onLoadReportDetails(
    LoadReportDetailsEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    
    final result = await getReportById(event.reportId);
    
    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (report) => emit(ReportDetailLoaded(report: report)),
    );
  }

  Future<void> _onCreateReport(
    CreateReportEvent event,
    Emitter<ReportState> emit,
  ) async {
    emit(SubmittingReport());
    
    // Obtener ubicación actual si no se proporciona
    LocationData location = event.location;
    if (location.latitude == 0 && location.longitude == 0) {
      try {
        final position = await _getCurrentPosition();
        location = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          address: event.location.address,
        );
      } catch (e) {
        emit(ReportError(message: 'Error al obtener ubicación: $e'));
        return;
      }
    }
    
    final params = CreateReportParams(
      title: event.title,
      description: event.description,
      category: event.category,
      location: location,
      userId: event.userId,
      images: event.images,
    );
    
    final result = await createReport(params);
    
    result.fold(
      (failure) => emit(ReportError(message: failure.message)),
      (reportId) => emit(ReportCreated(reportId: reportId)),
    );
  }

  void _onFilterReports(
    FilterReportsEvent event,
    Emitter<ReportState> emit,
  ) {
    final currentState = state;
    
    if (currentState is ReportsLoaded) {
      final filteredReports = event.filter == 'Todas'
          ? currentState.reports
          : currentState.reports.where((report) => report.status == event.filter).toList();
      
      emit(ReportsLoaded(
        reports: currentState.reports, 
        filteredReports: filteredReports,
        currentFilter: event.filter,
      ));
    }
  }

  Future<void> _onUpdateReportStatus(
    UpdateReportStatusEvent event,
    Emitter<ReportState> emit,
  ) async {
    try {
      // Simular actualización de estado en Firebase
      await Future.delayed(const Duration(seconds: 1));
      
      // En implementación real:
      // await reportRepository.updateReportStatus(
      //   reportId: event.reportId,
      //   status: event.status,
      //   comment: event.comment,
      //   userId: event.userId,
      // );
      
      // Crear nuevo item de historial
      
      // Recargar detalles del reporte
      add(LoadReportDetailsEvent(reportId: event.reportId));
      
    } catch (e) {
      emit(ReportError(message: 'Error al actualizar estado: ${e.toString()}'));
    }
  }

  Future<void> _onAddReportResponse(
    AddReportResponseEvent event,
    Emitter<ReportState> emit,
  ) async {
    try {
      // Simular agregar respuesta
      await Future.delayed(const Duration(seconds: 1));
      
      // En implementación real:
      // await reportRepository.addReportResponse(
      //   reportId: event.reportId,
      //   responderId: event.responderId,
      //   responderName: event.responderName,
      //   message: event.message,
      //   attachments: event.attachments,
      //   isPublic: event.isPublic,
      // );
      
      // Recargar detalles del reporte
      add(LoadReportDetailsEvent(reportId: event.reportId));
      
    } catch (e) {
      emit(ReportError(message: 'Error al agregar respuesta: ${e.toString()}'));
    }
  }

  // Método auxiliar para obtener ubicación actual
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicios de ubicación desactivados');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }
}