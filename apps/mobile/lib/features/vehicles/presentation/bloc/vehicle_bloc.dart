// lib/features/vehicles/presentation/bloc/vehicle_bloc.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';
import '../../domain/usecases/end_vehicle_usage.dart';
import '../../domain/usecases/get_vehicles.dart';
import '../../domain/usecases/start_vehicle_usage.dart';

// Events
abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadVehiclesEvent extends VehicleEvent {
  final String muniId;
  
  const LoadVehiclesEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class LoadAvailableVehiclesEvent extends VehicleEvent {
  final String muniId;
  
  const LoadAvailableVehiclesEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class LoadVehiclesByStatusEvent extends VehicleEvent {
  final VehicleStatus status;
  final String muniId;
  
  const LoadVehiclesByStatusEvent({
    required this.status,
    required this.muniId,
  });
  
  @override
  List<Object> get props => [status, muniId];
}

class StartVehicleUsageEvent extends VehicleEvent {
  final String vehicleId;
  final String driverId;
  final String driverName;
  final double startKm;
  final UsageType usageType;
  final String? purpose;
  
  const StartVehicleUsageEvent({
    required this.vehicleId,
    required this.driverId,
    required this.driverName,
    required this.startKm,
    required this.usageType,
    this.purpose,
  });
  
  @override
  List<Object?> get props => [
    vehicleId, driverId, driverName, startKm, usageType, purpose,
  ];
}

class EndVehicleUsageEvent extends VehicleEvent {
  final String logId;
  final double endKm;
  final String? observations;
  final List<String>? attachments;
  final List<LocationPoint>? route;
  final List<TripStop>? stops;

  const EndVehicleUsageEvent({
    required this.logId,
    required this.endKm,
    this.observations,
    this.attachments,
    this.route,
    this.stops,
  });

  @override
  List<Object?> get props => [logId, endKm, observations, attachments, route, stops];
}

class UpdateVehicleLocationEvent extends VehicleEvent {
  final String logId;
  final double latitude;
  final double longitude;
  final double? speed;
  
  const UpdateVehicleLocationEvent({
    required this.logId,
    required this.latitude,
    required this.longitude,
    this.speed,
  });
  
  @override
  List<Object?> get props => [logId, latitude, longitude, speed];
}

class LoadActiveUsagesEvent extends VehicleEvent {
  final String muniId;
  
  const LoadActiveUsagesEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class LoadVehicleStatisticsEvent extends VehicleEvent {
  final String muniId;
  
  const LoadVehicleStatisticsEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class FilterVehiclesEvent extends VehicleEvent {
  final VehicleStatus? status;
  final VehicleType? type;
  final String? searchQuery;
  
  const FilterVehiclesEvent({
    this.status,
    this.type,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [status, type, searchQuery];
}

class RefreshVehiclesEvent extends VehicleEvent {
  final String muniId;

  const RefreshVehiclesEvent({required this.muniId});

  @override
  List<Object> get props => [muniId];
}

class StartGpsTrackingEvent extends VehicleEvent {
  final String vehicleId;
  final String vehicleLogId;
  final String accessToken;
  final String apiUrl;

  const StartGpsTrackingEvent({
    required this.vehicleId,
    required this.vehicleLogId,
    required this.accessToken,
    required this.apiUrl,
  });

  @override
  List<Object> get props => [vehicleId, vehicleLogId, accessToken, apiUrl];
}

class StopGpsTrackingEvent extends VehicleEvent {}

class GpsPositionUpdatedEvent extends VehicleEvent {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? accuracy;

  const GpsPositionUpdatedEvent({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, speed, accuracy];
}

class StartWatchingVehiclesEvent extends VehicleEvent {
  final String muniId;
  
  const StartWatchingVehiclesEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class StopWatchingVehiclesEvent extends VehicleEvent {}

// States
abstract class VehicleState extends Equatable {
  const VehicleState();
  
  @override
  List<Object?> get props => [];
}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {
  final String? message;
  
  const VehicleLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class VehiclesLoaded extends VehicleState {
  final List<VehicleEntity> vehicles;
  final List<VehicleEntity> filteredVehicles;
  final VehicleStatus? currentStatusFilter;
  final VehicleType? currentTypeFilter;
  final String? searchQuery;
  final Map<String, int> statusCounts;
  final Map<String, int> typeCounts;
  
  const VehiclesLoaded({
    required this.vehicles,
    List<VehicleEntity>? filteredVehicles,
    this.currentStatusFilter,
    this.currentTypeFilter,
    this.searchQuery,
    required this.statusCounts,
    required this.typeCounts,
  }) : filteredVehicles = filteredVehicles ?? vehicles;
  
  @override
  List<Object?> get props => [
    vehicles, filteredVehicles, currentStatusFilter, currentTypeFilter,
    searchQuery, statusCounts, typeCounts,
  ];
  
  VehiclesLoaded copyWith({
    List<VehicleEntity>? vehicles,
    List<VehicleEntity>? filteredVehicles,
    VehicleStatus? currentStatusFilter,
    VehicleType? currentTypeFilter,
    String? searchQuery,
    Map<String, int>? statusCounts,
    Map<String, int>? typeCounts,
  }) {
    return VehiclesLoaded(
      vehicles: vehicles ?? this.vehicles,
      filteredVehicles: filteredVehicles ?? this.filteredVehicles,
      currentStatusFilter: currentStatusFilter ?? this.currentStatusFilter,
      currentTypeFilter: currentTypeFilter ?? this.currentTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      statusCounts: statusCounts ?? this.statusCounts,
      typeCounts: typeCounts ?? this.typeCounts,
    );
  }
}

class VehicleUsageStarting extends VehicleState {
  final String vehicleId;
  
  const VehicleUsageStarting({required this.vehicleId});
  
  @override
  List<Object> get props => [vehicleId];
}

class VehicleUsageStarted extends VehicleState {
  final String logId;
  final String vehicleId;
  final String message;
  
  const VehicleUsageStarted({
    required this.logId,
    required this.vehicleId,
    required this.message,
  });
  
  @override
  List<Object> get props => [logId, vehicleId, message];
}

class VehicleUsageEnding extends VehicleState {
  final String logId;
  
  const VehicleUsageEnding({required this.logId});
  
  @override
  List<Object> get props => [logId];
}

class VehicleUsageEnded extends VehicleState {
  final String logId;
  final String message;
  
  const VehicleUsageEnded({
    required this.logId,
    required this.message,
  });
  
  @override
  List<Object> get props => [logId, message];
}

class ActiveUsagesLoaded extends VehicleState {
  final List<VehicleLogEntity> activeUsages;
  final Map<String, VehicleEntity> vehiclesMap;
  
  const ActiveUsagesLoaded({
    required this.activeUsages,
    required this.vehiclesMap,
  });
  
  @override
  List<Object> get props => [activeUsages, vehiclesMap];
}

class VehicleStatisticsLoaded extends VehicleState {
  final Map<String, dynamic> statistics;
  final DateTime lastUpdated;
  
  const VehicleStatisticsLoaded({
    required this.statistics,
    required this.lastUpdated,
  });
  
  @override
  List<Object> get props => [statistics, lastUpdated];
}

class VehiclesStreaming extends VehicleState {
  final List<VehicleEntity> vehicles;
  final bool isListening;
  
  const VehiclesStreaming({
    required this.vehicles,
    this.isListening = true,
  });
  
  @override
  List<Object> get props => [vehicles, isListening];
}

class LocationUpdating extends VehicleState {
  final String logId;
  
  const LocationUpdating({required this.logId});
  
  @override
  List<Object> get props => [logId];
}

class LocationUpdated extends VehicleState {
  final String logId;
  final String message;
  
  const LocationUpdated({
    required this.logId,
    required this.message,
  });
  
  @override
  List<Object> get props => [logId, message];
}

class VehicleError extends VehicleState {
  final String message;
  final String? errorCode;
  final bool canRetry;

  const VehicleError({
    required this.message,
    this.errorCode,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, errorCode, canRetry];
}

class GpsTrackingActive extends VehicleState {
  final String vehicleId;
  final String vehicleLogId;
  final double? currentLatitude;
  final double? currentLongitude;
  final double? currentSpeed;
  final int pointsRecorded;
  final DateTime startedAt;

  const GpsTrackingActive({
    required this.vehicleId,
    required this.vehicleLogId,
    this.currentLatitude,
    this.currentLongitude,
    this.currentSpeed,
    this.pointsRecorded = 0,
    required this.startedAt,
  });

  @override
  List<Object?> get props => [
        vehicleId,
        vehicleLogId,
        currentLatitude,
        currentLongitude,
        currentSpeed,
        pointsRecorded,
        startedAt,
      ];

  GpsTrackingActive copyWith({
    double? currentLatitude,
    double? currentLongitude,
    double? currentSpeed,
    int? pointsRecorded,
  }) {
    return GpsTrackingActive(
      vehicleId: vehicleId,
      vehicleLogId: vehicleLogId,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      pointsRecorded: pointsRecorded ?? this.pointsRecorded,
      startedAt: startedAt,
    );
  }
}

class GpsTrackingStopped extends VehicleState {
  final String vehicleId;
  final int totalPointsRecorded;
  final Duration duration;

  const GpsTrackingStopped({
    required this.vehicleId,
    required this.totalPointsRecorded,
    required this.duration,
  });

  @override
  List<Object> get props => [vehicleId, totalPointsRecorded, duration];
}

// BLoC
class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetVehicles getVehicles;
  final StartVehicleUsage startVehicleUsage;
  final EndVehicleUsage endVehicleUsage;
  
  StreamSubscription<List<VehicleEntity>>? _vehiclesSubscription;

  VehicleBloc({
    required this.getVehicles,
    required this.startVehicleUsage,
    required this.endVehicleUsage,
  }) : super(VehicleInitial()) {
    on<LoadVehiclesEvent>(_onLoadVehicles);
    on<LoadAvailableVehiclesEvent>(_onLoadAvailableVehicles);
    on<LoadVehiclesByStatusEvent>(_onLoadVehiclesByStatus);
    on<StartVehicleUsageEvent>(_onStartVehicleUsage);
    on<EndVehicleUsageEvent>(_onEndVehicleUsage);
    on<UpdateVehicleLocationEvent>(_onUpdateVehicleLocation);
    on<LoadActiveUsagesEvent>(_onLoadActiveUsages);
    on<LoadVehicleStatisticsEvent>(_onLoadVehicleStatistics);
    on<FilterVehiclesEvent>(_onFilterVehicles);
    on<RefreshVehiclesEvent>(_onRefreshVehicles);
    on<StartWatchingVehiclesEvent>(_onStartWatchingVehicles);
    on<StopWatchingVehiclesEvent>(_onStopWatchingVehicles);
    on<StartGpsTrackingEvent>(_onStartGpsTracking);
    on<StopGpsTrackingEvent>(_onStopGpsTracking);
    on<GpsPositionUpdatedEvent>(_onGpsPositionUpdated);
  }

  @override
  Future<void> close() {
    _vehiclesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadVehicles(
    LoadVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    if (state is! VehiclesLoaded) {
      emit(const VehicleLoading(message: 'Cargando vehículos...'));
    }
    
    try {
      final result = await getVehicles(GetVehiclesParams(muniId: event.muniId));
      
      result.fold(
        (failure) => emit(VehicleError(message: failure.message)),
        (vehicles) {
          final statusCounts = _calculateStatusCounts(vehicles);
          final typeCounts = _calculateTypeCounts(vehicles);
          
          emit(VehiclesLoaded(
            vehicles: vehicles,
            statusCounts: statusCounts,
            typeCounts: typeCounts,
          ));
        },
      );
    } catch (e) {
      emit(VehicleError(
        message: 'Error inesperado: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadAvailableVehicles(
    LoadAvailableVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading(message: 'Cargando vehículos disponibles...'));
    
    // Para simplificar, usamos el método general y filtramos
    add(LoadVehiclesByStatusEvent(
      status: VehicleStatus.available,
      muniId: event.muniId,
    ));
  }

  Future<void> _onLoadVehiclesByStatus(
    LoadVehiclesByStatusEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading(message: 'Cargando vehículos...'));
    
    try {
      final result = await getVehicles(GetVehiclesParams(muniId: event.muniId));
      
      result.fold(
        (failure) => emit(VehicleError(message: failure.message)),
        (allVehicles) {
          final filteredVehicles = allVehicles
              .where((vehicle) => vehicle.status == event.status)
              .toList();
          
          final statusCounts = _calculateStatusCounts(allVehicles);
          final typeCounts = _calculateTypeCounts(allVehicles);
          
          emit(VehiclesLoaded(
            vehicles: allVehicles,
            filteredVehicles: filteredVehicles,
            currentStatusFilter: event.status,
            statusCounts: statusCounts,
            typeCounts: typeCounts,
          ));
        },
      );
    } catch (e) {
      emit(VehicleError(
        message: 'Error inesperado: ${e.toString()}',
      ));
    }
  }

  Future<void> _onStartVehicleUsage(
    StartVehicleUsageEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleUsageStarting(vehicleId: event.vehicleId));
    
    try {
      final result = await startVehicleUsage(
        StartVehicleUsageParams(
          vehicleId: event.vehicleId,
          driverId: event.driverId,
          driverName: event.driverName,
          startKm: event.startKm,
          usageType: event.usageType,
          purpose: event.purpose,
        ),
      );
      
      result.fold(
        (failure) => emit(VehicleError(message: failure.message)),
        (logId) => emit(VehicleUsageStarted(
          logId: logId,
          vehicleId: event.vehicleId,
          message: 'Uso de vehículo iniciado exitosamente',
        )),
      );
    } catch (e) {
      emit(VehicleError(
        message: 'Error al iniciar uso de vehículo: ${e.toString()}',
      ));
    }
  }

  Future<void> _onEndVehicleUsage(
    EndVehicleUsageEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleUsageEnding(logId: event.logId));

    try {
      final result = await endVehicleUsage(
        EndVehicleUsageParams(
          logId: event.logId,
          endKm: event.endKm,
          observations: event.observations,
          attachments: event.attachments,
          route: event.route,
          stops: event.stops,
        ),
      );

      result.fold(
        (failure) => emit(VehicleError(message: failure.message)),
        (_) => emit(VehicleUsageEnded(
          logId: event.logId,
          message: 'Bitácora finalizada exitosamente',
        )),
      );
    } catch (e) {
      emit(VehicleError(
        message: 'Error al finalizar bitácora: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateVehicleLocation(
    UpdateVehicleLocationEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(LocationUpdating(logId: event.logId));
    
    try {
      // Simular actualización de ubicación
      // En implementación real, usarías el repository
      await Future.delayed(const Duration(milliseconds: 500));
      
      emit(LocationUpdated(
        logId: event.logId,
        message: 'Ubicación actualizada',
      ));
    } catch (e) {
      emit(VehicleError(
        message: 'Error al actualizar ubicación: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadActiveUsages(
    LoadActiveUsagesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading(message: 'Cargando usos activos...'));
    
    try {
      // Simular carga de usos activos
      // En implementación real, usarías el repository
      await Future.delayed(const Duration(seconds: 1));
      
      emit(const ActiveUsagesLoaded(
        activeUsages: [],
        vehiclesMap: {},
      ));
    } catch (e) {
      emit(VehicleError(
        message: 'Error al cargar usos activos: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadVehicleStatistics(
    LoadVehicleStatisticsEvent event,
    Emitter<VehicleState> emit,
  ) async {
    emit(const VehicleLoading(message: 'Cargando estadísticas...'));
    
    try {
      // Simular estadísticas
      await Future.delayed(const Duration(seconds: 1));
      
      final mockStatistics = {
        'totalVehicles': 10,
        'availableVehicles': 7,
        'inUseVehicles': 2,
        'maintenanceVehicles': 1,
        'monthlyKm': 2500.0,
        'monthlyTrips': 45,
      };
      
      emit(VehicleStatisticsLoaded(
        statistics: mockStatistics,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(VehicleError(
        message: 'Error al cargar estadísticas: ${e.toString()}',
      ));
    }
  }

  void _onFilterVehicles(
    FilterVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) {
    if (state is VehiclesLoaded) {
      final currentState = state as VehiclesLoaded;
      
      List<VehicleEntity> filteredVehicles = currentState.vehicles;
      
      // Aplicar filtro por estado
      if (event.status != null) {
        filteredVehicles = filteredVehicles
            .where((vehicle) => vehicle.status == event.status)
            .toList();
      }
      
      // Aplicar filtro por tipo
      if (event.type != null) {
        filteredVehicles = filteredVehicles
            .where((vehicle) => vehicle.type == event.type)
            .toList();
      }
      
      // Aplicar filtro de búsqueda
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        filteredVehicles = filteredVehicles
            .where((vehicle) =>
                vehicle.plate.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
                vehicle.model.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
                vehicle.brand.toLowerCase().contains(event.searchQuery!.toLowerCase()))
            .toList();
      }
      
      emit(currentState.copyWith(
        filteredVehicles: filteredVehicles,
        currentStatusFilter: event.status,
        currentTypeFilter: event.type,
        searchQuery: event.searchQuery,
      ));
    }
  }

  Future<void> _onRefreshVehicles(
    RefreshVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    add(LoadVehiclesEvent(muniId: event.muniId));
  }

  Future<void> _onStartWatchingVehicles(
    StartWatchingVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    await _vehiclesSubscription?.cancel();
    
    // En implementación real, usarías el stream del repository
    // Por ahora simulamos con un timer
    emit(const VehiclesStreaming(vehicles: [], isListening: true));
  }

  Future<void> _onStopWatchingVehicles(
    StopWatchingVehiclesEvent event,
    Emitter<VehicleState> emit,
  ) async {
    await _vehiclesSubscription?.cancel();
    _vehiclesSubscription = null;
    
    if (state is VehiclesStreaming) {
      final currentState = state as VehiclesStreaming;
      emit(VehiclesLoaded(
        vehicles: currentState.vehicles,
        statusCounts: _calculateStatusCounts(currentState.vehicles),
        typeCounts: _calculateTypeCounts(currentState.vehicles),
      ));
    }
  }

  Map<String, int> _calculateStatusCounts(List<VehicleEntity> vehicles) {
    final counts = <String, int>{};
    
    for (final vehicle in vehicles) {
      final status = vehicle.status.name;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    
    return counts;
  }

  Map<String, int> _calculateTypeCounts(List<VehicleEntity> vehicles) {
    final counts = <String, int>{};

    for (final vehicle in vehicles) {
      final type = vehicle.type.name;
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return counts;
  }

  // GPS Tracking handlers
  DateTime? _gpsTrackingStartTime;
  int _gpsPointsRecorded = 0;

  Future<void> _onStartGpsTracking(
    StartGpsTrackingEvent event,
    Emitter<VehicleState> emit,
  ) async {
    _gpsTrackingStartTime = DateTime.now();
    _gpsPointsRecorded = 0;

    emit(GpsTrackingActive(
      vehicleId: event.vehicleId,
      vehicleLogId: event.vehicleLogId,
      startedAt: _gpsTrackingStartTime!,
    ));
  }

  Future<void> _onStopGpsTracking(
    StopGpsTrackingEvent event,
    Emitter<VehicleState> emit,
  ) async {
    if (state is GpsTrackingActive) {
      final currentState = state as GpsTrackingActive;
      final duration = DateTime.now().difference(_gpsTrackingStartTime!);

      emit(GpsTrackingStopped(
        vehicleId: currentState.vehicleId,
        totalPointsRecorded: _gpsPointsRecorded,
        duration: duration,
      ));

      _gpsTrackingStartTime = null;
      _gpsPointsRecorded = 0;
    }
  }

  void _onGpsPositionUpdated(
    GpsPositionUpdatedEvent event,
    Emitter<VehicleState> emit,
  ) {
    if (state is GpsTrackingActive) {
      final currentState = state as GpsTrackingActive;
      _gpsPointsRecorded++;

      emit(currentState.copyWith(
        currentLatitude: event.latitude,
        currentLongitude: event.longitude,
        currentSpeed: event.speed,
        pointsRecorded: _gpsPointsRecorded,
      ));
    }
  }
}