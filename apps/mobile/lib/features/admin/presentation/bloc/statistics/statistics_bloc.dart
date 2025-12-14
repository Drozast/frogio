// lib/features/admin/presentation/bloc/statistics/statistics_bloc.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/municipal_statistics_entity.dart';
import '../../../domain/usecases/get_municipal_statistics.dart';

// Events
abstract class StatisticsEvent extends Equatable {
  const StatisticsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadMunicipalStatisticsEvent extends StatisticsEvent {
  final String muniId;
  
  const LoadMunicipalStatisticsEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class RefreshStatisticsEvent extends StatisticsEvent {
  final String muniId;
  
  const RefreshStatisticsEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class FilterStatisticsByDateEvent extends StatisticsEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  const FilterStatisticsByDateEvent({
    required this.startDate,
    required this.endDate,
  });
  
  @override
  List<Object> get props => [startDate, endDate];
}

class ExportStatisticsEvent extends StatisticsEvent {
  final String muniId;
  final StatisticsExportType exportType;
  final DateTime? startDate;
  final DateTime? endDate;
  
  const ExportStatisticsEvent({
    required this.muniId,
    required this.exportType,
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [muniId, exportType, startDate, endDate];
}

class ResetStatisticsEvent extends StatisticsEvent {}

// States
abstract class StatisticsState extends Equatable {
  const StatisticsState();
  
  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {
  final String? message;
  
  const StatisticsLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class StatisticsLoaded extends StatisticsState {
  final MunicipalStatisticsEntity statistics;
  final DateTime lastUpdated;
  final bool isRefreshing;
  
  const StatisticsLoaded({
    required this.statistics,
    required this.lastUpdated,
    this.isRefreshing = false,
  });
  
  @override
  List<Object> get props => [statistics, lastUpdated, isRefreshing];
  
  StatisticsLoaded copyWith({
    MunicipalStatisticsEntity? statistics,
    DateTime? lastUpdated,
    bool? isRefreshing,
  }) {
    return StatisticsLoaded(
      statistics: statistics ?? this.statistics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class StatisticsError extends StatisticsState {
  final String message;
  final bool canRetry;
  
  const StatisticsError({
    required this.message,
    this.canRetry = true,
  });
  
  @override
  List<Object> get props => [message, canRetry];
}

class StatisticsExporting extends StatisticsState {
  final double progress;
  final String currentTask;
  
  const StatisticsExporting({
    required this.progress,
    required this.currentTask,
  });
  
  @override
  List<Object> get props => [progress, currentTask];
}

class StatisticsExported extends StatisticsState {
  final String filePath;
  final String fileName;
  final StatisticsExportType exportType;
  
  const StatisticsExported({
    required this.filePath,
    required this.fileName,
    required this.exportType,
  });
  
  @override
  List<Object> get props => [filePath, fileName, exportType];
}

// BLoC
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final GetMunicipalStatistics getMunicipalStatistics;
  
  StatisticsBloc({
    required this.getMunicipalStatistics,
  }) : super(StatisticsInitial()) {
    on<LoadMunicipalStatisticsEvent>(_onLoadMunicipalStatistics);
    on<RefreshStatisticsEvent>(_onRefreshStatistics);
    on<FilterStatisticsByDateEvent>(_onFilterStatisticsByDate);
    on<ExportStatisticsEvent>(_onExportStatistics);
    on<ResetStatisticsEvent>(_onResetStatistics);
  }

  Future<void> _onLoadMunicipalStatistics(
    LoadMunicipalStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    if (state is! StatisticsLoaded) {
      emit(const StatisticsLoading(message: 'Cargando estadísticas...'));
    }
    
    try {
      final result = await getMunicipalStatistics(event.muniId);
      
      result.fold(
        (failure) => emit(StatisticsError(message: failure.message)),
        (statistics) => emit(StatisticsLoaded(
          statistics: statistics,
          lastUpdated: DateTime.now(),
        )),
      );
    } catch (e) {
      emit(StatisticsError(
        message: 'Error inesperado: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshStatistics(
    RefreshStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const StatisticsLoading(message: 'Actualizando estadísticas...'));
    }
    
    try {
      final result = await getMunicipalStatistics(event.muniId);
      
      result.fold(
        (failure) => emit(StatisticsError(message: failure.message)),
        (statistics) => emit(StatisticsLoaded(
          statistics: statistics,
          lastUpdated: DateTime.now(),
          isRefreshing: false,
        )),
      );
    } catch (e) {
      emit(StatisticsError(
        message: 'Error al actualizar: ${e.toString()}',
      ));
    }
  }

  Future<void> _onFilterStatisticsByDate(
    FilterStatisticsByDateEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    // TODO: Implementar filtrado por fecha en el repository/use case
    // Por ahora solo recargar las estadísticas
    if (state is StatisticsLoaded) {
      final currentState = state as StatisticsLoaded;
      emit(currentState.copyWith(isRefreshing: true));
      
      // Simular filtrado
      await Future.delayed(const Duration(seconds: 1));
      
      emit(currentState.copyWith(
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  Future<void> _onExportStatistics(
    ExportStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(const StatisticsExporting(
      progress: 0.0,
      currentTask: 'Preparando exportación...',
    ));
    
    try {
      // Simular proceso de exportación
      emit(const StatisticsExporting(
        progress: 0.2,
        currentTask: 'Recopilando datos...',
      ));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const StatisticsExporting(
        progress: 0.5,
        currentTask: 'Generando archivo...',
      ));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(const StatisticsExporting(
        progress: 0.8,
        currentTask: 'Finalizando...',
      ));
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // TODO: Implementar exportación real con el repository
      final fileName = _generateFileName(event.exportType, event.startDate, event.endDate);
      
      emit(StatisticsExported(
        filePath: '/downloads/$fileName',
        fileName: fileName,
        exportType: event.exportType,
      ));
      
      // Volver al estado cargado después de unos segundos
      await Future.delayed(const Duration(seconds: 2));
      if (state is StatisticsLoaded) {
        // Mantener el estado actual
      } else {
        add(LoadMunicipalStatisticsEvent(muniId: event.muniId));
      }
      
    } catch (e) {
      emit(StatisticsError(
        message: 'Error al exportar: ${e.toString()}',
      ));
    }
  }

  void _onResetStatistics(
    ResetStatisticsEvent event,
    Emitter<StatisticsState> emit,
  ) {
    emit(StatisticsInitial());
  }

  String _generateFileName(
    StatisticsExportType exportType,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    String typeStr;
    switch (exportType) {
      case StatisticsExportType.reports:
        typeStr = 'reportes';
        break;
      case StatisticsExportType.infractions:
        typeStr = 'infracciones';
        break;
      case StatisticsExportType.users:
        typeStr = 'usuarios';
        break;
      case StatisticsExportType.vehicles:
        typeStr = 'vehiculos';
        break;
      case StatisticsExportType.complete:
        typeStr = 'estadisticas_completas';
        break;
    }
    
    String dateRange = '';
    if (startDate != null && endDate != null) {
      final startStr = '${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
      final endStr = '${endDate.year}${endDate.month.toString().padLeft(2, '0')}${endDate.day.toString().padLeft(2, '0')}';
      dateRange = '_${startStr}_$endStr';
    }
    
    return '${typeStr}_$dateStr$dateRange.csv';
  }
}

enum StatisticsExportType {
  reports,
  infractions,
  users,
  vehicles,
  complete,
}