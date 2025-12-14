// lib/features/admin/domain/usecases/get_all_pending_queries.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/query_entity.dart';
import '../repositories/admin_repository.dart';

class GetAllPendingQueries implements UseCase<List<QueryEntity>, GetPendingQueriesParams> {
  final AdminRepository repository;

  GetAllPendingQueries(this.repository);

  @override
  Future<Either<Failure, List<QueryEntity>>> call(GetPendingQueriesParams params) async {
    try {
      if (params.muniId.isEmpty) {
        return const Left(ServerFailure('ID de municipalidad requerido'));
      }

      final result = await repository.getAllPendingQueries(params.muniId);
      
      return result.fold(
        (failure) => Left(failure),
        (queries) {
          // Filtrar por criterios adicionales si se especifican
          List<QueryEntity> filteredQueries = queries;
          
          if (params.priority != null) {
            filteredQueries = filteredQueries
                .where((query) => query.priority == params.priority)
                .toList();
          }
          
          if (params.category != null) {
            filteredQueries = filteredQueries
                .where((query) => query.category == params.category)
                .toList();
          }

          if (params.onlyUrgent) {
            filteredQueries = filteredQueries
                .where((query) => query.isUrgent)
                .toList();
          }

          if (params.onlyOverdue) {
            filteredQueries = filteredQueries
                .where((query) => query.isOverdue)
                .toList();
          }

          // Ordenar según criterio especificado
          switch (params.sortBy) {
            case QuerySortBy.newest:
              filteredQueries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              break;
            case QuerySortBy.oldest:
              filteredQueries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              break;
            case QuerySortBy.priority:
              filteredQueries.sort((a, b) => _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority)));
              break;
            case QuerySortBy.category:
              filteredQueries.sort((a, b) => a.category.displayName.compareTo(b.category.displayName));
              break;
          }

          // Aplicar límite si se especifica
          if (params.limit != null && params.limit! > 0) {
            filteredQueries = filteredQueries.take(params.limit!).toList();
          }

          return Right(filteredQueries);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Error al obtener consultas pendientes: ${e.toString()}'));
    }
  }

  int _getPriorityValue(QueryPriority priority) {
    switch (priority) {
      case QueryPriority.urgent:
        return 4;
      case QueryPriority.high:
        return 3;
      case QueryPriority.normal:
        return 2;
      case QueryPriority.low:
        return 1;
    }
  }
}

class GetPendingQueriesParams extends Equatable {
  final String muniId;
  final QueryPriority? priority;
  final QueryCategory? category;
  final bool onlyUrgent;
  final bool onlyOverdue;
  final QuerySortBy sortBy;
  final int? limit;

  const GetPendingQueriesParams({
    required this.muniId,
    this.priority,
    this.category,
    this.onlyUrgent = false,
    this.onlyOverdue = false,
    this.sortBy = QuerySortBy.newest,
    this.limit,
  });

  @override
  List<Object?> get props => [
    muniId,
    priority,
    category,
    onlyUrgent,
    onlyOverdue,
    sortBy,
    limit,
  ];
}

enum QuerySortBy {
  newest,
  oldest,
  priority,
  category,
}