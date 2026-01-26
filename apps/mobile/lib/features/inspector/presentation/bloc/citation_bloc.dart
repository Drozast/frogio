// lib/features/inspector/presentation/bloc/citation_bloc.dart
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/citation_model.dart';
import '../../domain/entities/citation_entity.dart';
import '../../domain/repositories/citation_repository.dart';

// Orden disponible para citaciones
enum CitationSortField { date, number, status }

// Events
abstract class CitationEvent extends Equatable {
  const CitationEvent();

  @override
  List<Object?> get props => [];
}

class LoadCitationsEvent extends CitationEvent {
  final CitationFilters? filters;

  const LoadCitationsEvent({this.filters});

  @override
  List<Object?> get props => [filters];
}

class LoadMyCitationsEvent extends CitationEvent {}

class LoadCitationByIdEvent extends CitationEvent {
  final String id;

  const LoadCitationByIdEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class CreateCitationEvent extends CitationEvent {
  final CreateCitationDto dto;
  final List<File>? photos;

  const CreateCitationEvent({required this.dto, this.photos});

  @override
  List<Object?> get props => [dto, photos];
}

class UpdateCitationEvent extends CitationEvent {
  final String id;
  final UpdateCitationDto dto;

  const UpdateCitationEvent({required this.id, required this.dto});

  @override
  List<Object> get props => [id, dto];
}

class DeleteCitationEvent extends CitationEvent {
  final String id;

  const DeleteCitationEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class GenerateCitationNumberEvent extends CitationEvent {}

class FilterCitationsEvent extends CitationEvent {
  final CitationStatus? status;
  final CitationType? citationType;
  final TargetType? targetType;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? sortByDateDesc;
  final CitationSortField? sortField;

  const FilterCitationsEvent({
    this.status,
    this.citationType,
    this.targetType,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.sortByDateDesc,
    this.sortField,
  });

  @override
  List<Object?> get props => [status, citationType, targetType, searchQuery, startDate, endDate, sortByDateDesc, sortField];
}

class RefreshCitationsEvent extends CitationEvent {}

class UpdateCitationStatusEvent extends CitationEvent {
  final String citationId;
  final CitationStatus status;
  final String? notes;

  const UpdateCitationStatusEvent({required this.citationId, required this.status, this.notes});

  @override
  List<Object?> get props => [citationId, status, notes];
}

// States
abstract class CitationState extends Equatable {
  const CitationState();

  @override
  List<Object?> get props => [];
}

class CitationInitial extends CitationState {}

class CitationLoading extends CitationState {
  final String? message;

  const CitationLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class CitationsLoaded extends CitationState {
  final List<CitationEntity> citations;
  final List<CitationEntity> filteredCitations;
  final CitationStatus? currentStatusFilter;
  final CitationType? currentTypeFilter;
  final TargetType? currentTargetFilter;
  final String? searchQuery;
  final Map<CitationStatus, int> statusCounts;

  const CitationsLoaded({
    required this.citations,
    List<CitationEntity>? filteredCitations,
    this.currentStatusFilter,
    this.currentTypeFilter,
    this.currentTargetFilter,
    this.searchQuery,
    required this.statusCounts,
  }) : filteredCitations = filteredCitations ?? citations;

  @override
  List<Object?> get props => [
        citations,
        filteredCitations,
        currentStatusFilter,
        currentTypeFilter,
        currentTargetFilter,
        searchQuery,
        statusCounts,
      ];

  CitationsLoaded copyWith({
    List<CitationEntity>? citations,
    List<CitationEntity>? filteredCitations,
    CitationStatus? currentStatusFilter,
    CitationType? currentTypeFilter,
    TargetType? currentTargetFilter,
    String? searchQuery,
    Map<CitationStatus, int>? statusCounts,
  }) {
    return CitationsLoaded(
      citations: citations ?? this.citations,
      filteredCitations: filteredCitations ?? this.filteredCitations,
      currentStatusFilter: currentStatusFilter ?? this.currentStatusFilter,
      currentTypeFilter: currentTypeFilter ?? this.currentTypeFilter,
      currentTargetFilter: currentTargetFilter ?? this.currentTargetFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      statusCounts: statusCounts ?? this.statusCounts,
    );
  }
}

class CitationDetailLoaded extends CitationState {
  final CitationEntity citation;

  const CitationDetailLoaded({required this.citation});

  @override
  List<Object> get props => [citation];
}

class CitationCreating extends CitationState {}

class CitationCreated extends CitationState {
  final CitationEntity citation;
  final String message;

  const CitationCreated({required this.citation, required this.message});

  @override
  List<Object> get props => [citation, message];
}

class CitationUpdating extends CitationState {
  final String id;

  const CitationUpdating({required this.id});

  @override
  List<Object> get props => [id];
}

class CitationUpdated extends CitationState {
  final CitationEntity citation;
  final String message;

  const CitationUpdated({required this.citation, required this.message});

  @override
  List<Object> get props => [citation, message];
}

class CitationDeleting extends CitationState {
  final String id;

  const CitationDeleting({required this.id});

  @override
  List<Object> get props => [id];
}

class CitationDeleted extends CitationState {
  final String id;
  final String message;

  const CitationDeleted({required this.id, required this.message});

  @override
  List<Object> get props => [id, message];
}

class CitationNumberGenerated extends CitationState {
  final String citationNumber;

  const CitationNumberGenerated({required this.citationNumber});

  @override
  List<Object> get props => [citationNumber];
}

class CitationError extends CitationState {
  final String message;
  final String? errorCode;
  final bool canRetry;

  const CitationError({
    required this.message,
    this.errorCode,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, errorCode, canRetry];
}

// BLoC
class CitationBloc extends Bloc<CitationEvent, CitationState> {
  final CitationRepository repository;

  CitationBloc({required this.repository}) : super(CitationInitial()) {
    on<LoadCitationsEvent>(_onLoadCitations);
    on<LoadMyCitationsEvent>(_onLoadMyCitations);
    on<LoadCitationByIdEvent>(_onLoadCitationById);
    on<CreateCitationEvent>(_onCreateCitation);
    on<UpdateCitationEvent>(_onUpdateCitation);
    on<DeleteCitationEvent>(_onDeleteCitation);
    on<GenerateCitationNumberEvent>(_onGenerateCitationNumber);
    on<FilterCitationsEvent>(_onFilterCitations);
    on<RefreshCitationsEvent>(_onRefreshCitations);
    on<UpdateCitationStatusEvent>(_onUpdateCitationStatus);
  }

  Future<void> _onLoadCitations(
    LoadCitationsEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(const CitationLoading(message: 'Cargando citaciones...'));

    final result = await repository.getCitations(filters: event.filters);

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (citations) {
        final statusCounts = _calculateStatusCounts(citations);
        emit(CitationsLoaded(
          citations: citations,
          statusCounts: statusCounts,
        ));
      },
    );
  }

  Future<void> _onLoadMyCitations(
    LoadMyCitationsEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(const CitationLoading(message: 'Cargando mis citaciones...'));

    final result = await repository.getMyCitations();

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (citations) {
        final statusCounts = _calculateStatusCounts(citations);
        emit(CitationsLoaded(
          citations: citations,
          statusCounts: statusCounts,
        ));
      },
    );
  }

  Future<void> _onLoadCitationById(
    LoadCitationByIdEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(const CitationLoading(message: 'Cargando citación...'));

    final result = await repository.getCitationById(event.id);

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (citation) => emit(CitationDetailLoaded(citation: citation)),
    );
  }

  Future<void> _onCreateCitation(
    CreateCitationEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(CitationCreating());

    try {
      // Upload photos first if any
      List<String>? photoUrls;
      if (event.photos != null && event.photos!.isNotEmpty) {
        final uploadResult = await repository.uploadPhotos(event.photos!);
        uploadResult.fold(
          (failure) {
            emit(CitationError(message: 'Error al subir fotos: ${failure.message}'));
            return;
          },
          (urls) => photoUrls = urls,
        );

        // If upload failed, the error state was already emitted
        if (state is CitationError) return;
      }

      // Create citation with photo URLs
      final dtoWithPhotos = CreateCitationDto(
        citationType: event.dto.citationType,
        targetType: event.dto.targetType,
        targetName: event.dto.targetName,
        targetRut: event.dto.targetRut,
        targetAddress: event.dto.targetAddress,
        targetPhone: event.dto.targetPhone,
        targetPlate: event.dto.targetPlate,
        locationAddress: event.dto.locationAddress,
        latitude: event.dto.latitude,
        longitude: event.dto.longitude,
        citationNumber: event.dto.citationNumber,
        reason: event.dto.reason,
        notes: event.dto.notes,
        photos: photoUrls,
      );

      final result = await repository.createCitation(dtoWithPhotos);

      result.fold(
        (failure) => emit(CitationError(message: failure.message)),
        (citation) => emit(CitationCreated(
          citation: citation,
          message: 'Citación creada exitosamente',
        )),
      );
    } catch (e) {
      emit(CitationError(message: 'Error inesperado: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCitation(
    UpdateCitationEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(CitationUpdating(id: event.id));

    final result = await repository.updateCitation(event.id, event.dto);

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (citation) {
        emit(CitationUpdated(
          citation: citation,
          message: 'Citación actualizada exitosamente',
        ));
        // No recargar aquí - la pantalla de detalle volverá y la lista se recargará
      },
    );
  }

  Future<void> _onDeleteCitation(
    DeleteCitationEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(CitationDeleting(id: event.id));

    final result = await repository.deleteCitation(event.id);

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (_) => emit(CitationDeleted(
        id: event.id,
        message: 'Citación eliminada exitosamente',
      )),
    );
  }

  Future<void> _onGenerateCitationNumber(
    GenerateCitationNumberEvent event,
    Emitter<CitationState> emit,
  ) async {
    final result = await repository.generateCitationNumber();

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (number) => emit(CitationNumberGenerated(citationNumber: number)),
    );
  }

  void _onFilterCitations(
    FilterCitationsEvent event,
    Emitter<CitationState> emit,
  ) {
    if (state is CitationsLoaded) {
      final currentState = state as CitationsLoaded;

      List<CitationEntity> filteredCitations = currentState.citations;

      // Aplicar filtro por estado
      if (event.status != null) {
        filteredCitations = filteredCitations
            .where((citation) => citation.status == event.status)
            .toList();
      }

      // Aplicar filtro por tipo de citación
      if (event.citationType != null) {
        filteredCitations = filteredCitations
            .where((citation) => citation.citationType == event.citationType)
            .toList();
      }

      // Aplicar filtro por tipo de objetivo
      if (event.targetType != null) {
        filteredCitations = filteredCitations
            .where((citation) => citation.targetType == event.targetType)
            .toList();
      }

      // Aplicar filtro de búsqueda
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filteredCitations = filteredCitations.where((citation) {
          return citation.citationNumber.toLowerCase().contains(query) ||
              (citation.targetName?.toLowerCase().contains(query) ?? false) ||
              (citation.targetRut?.toLowerCase().contains(query) ?? false) ||
              (citation.targetPlate?.toLowerCase().contains(query) ?? false) ||
              citation.reason.toLowerCase().contains(query);
        }).toList();
      }

      // Aplicar filtro por rango de fechas (createdAt)
      if (event.startDate != null || event.endDate != null) {
        final start = event.startDate != null
            ? DateTime(event.startDate!.year, event.startDate!.month, event.startDate!.day)
            : null;
        final end = event.endDate != null
            ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day, 23, 59, 59, 999)
            : null;

        filteredCitations = filteredCitations.where((citation) {
          final created = citation.createdAt;
          final afterStart = start == null || !created.isBefore(start);
          final beforeEnd = end == null || !created.isAfter(end);
          return afterStart && beforeEnd;
        }).toList();
      }

      // Ordenar por campo
      final sortDesc = event.sortByDateDesc ?? true;
      final sortField = event.sortField ?? CitationSortField.date;

      int statusIndex(CitationStatus s) {
        switch (s) {
          case CitationStatus.pendiente:
            return 0;
          case CitationStatus.notificado:
            return 1;
          case CitationStatus.asistio:
            return 2;
          case CitationStatus.noAsistio:
            return 3;
          case CitationStatus.cancelado:
            return 4;
        }
      }

      int numberKey(CitationEntity c) {
        final match = RegExp(r'\d+').firstMatch(c.citationNumber);
        if (match != null) {
          return int.tryParse(match.group(0)!) ?? 0;
        }
        // fallback: hash of lowercase
        return c.citationNumber.toLowerCase().hashCode;
      }

      switch (sortField) {
        case CitationSortField.date:
          filteredCitations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case CitationSortField.number:
          filteredCitations.sort((a, b) => numberKey(a).compareTo(numberKey(b)));
          break;
        case CitationSortField.status:
          filteredCitations.sort((a, b) => statusIndex(a.status).compareTo(statusIndex(b.status)));
          break;
      }
      if (sortDesc) {
        filteredCitations = filteredCitations.reversed.toList();
      }

      emit(currentState.copyWith(
        filteredCitations: filteredCitations,
        currentStatusFilter: event.status,
        currentTypeFilter: event.citationType,
        currentTargetFilter: event.targetType,
        searchQuery: event.searchQuery,
      ));
    }
  }

  Future<void> _onRefreshCitations(
    RefreshCitationsEvent event,
    Emitter<CitationState> emit,
  ) async {
    add(LoadMyCitationsEvent());
  }

  Future<void> _onUpdateCitationStatus(
    UpdateCitationStatusEvent event,
    Emitter<CitationState> emit,
  ) async {
    emit(CitationUpdating(id: event.citationId));

    final dto = UpdateCitationDto(status: event.status, notes: event.notes);
    final result = await repository.updateCitation(event.citationId, dto);

    result.fold(
      (failure) => emit(CitationError(message: failure.message)),
      (citation) {
        emit(CitationUpdated(
          citation: citation,
          message: 'Estado actualizado a: ${event.status.displayName}',
        ));
        // Recargar la lista
        add(LoadMyCitationsEvent());
      },
    );
  }

  Map<CitationStatus, int> _calculateStatusCounts(List<CitationEntity> citations) {
    final counts = <CitationStatus, int>{};

    for (final citation in citations) {
      counts[citation.status] = (counts[citation.status] ?? 0) + 1;
    }

    return counts;
  }
}
