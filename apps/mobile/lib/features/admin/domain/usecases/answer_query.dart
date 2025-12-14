// lib/features/admin/domain/usecases/answer_query.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class AnswerQuery implements UseCase<void, AnswerQueryParams> {
  final AdminRepository repository;

  AnswerQuery(this.repository);

  @override
  Future<Either<Failure, void>> call(AnswerQueryParams params) async {
    try {
      // Validaciones
      final validationResult = _validateParams(params);
      if (validationResult != null) {
        return Left(ServerFailure(validationResult));
      }

      return await repository.answerQuery(
        queryId: params.queryId,
        adminId: params.adminId,
        response: params.response,
        attachments: params.attachments,
      );
    } catch (e) {
      return Left(ServerFailure('Error al responder consulta: ${e.toString()}'));
    }
  }

  String? _validateParams(AnswerQueryParams params) {
    if (params.queryId.isEmpty) {
      return 'ID de consulta requerido';
    }

    if (params.adminId.isEmpty) {
      return 'ID de administrador requerido';
    }

    if (params.response.trim().isEmpty) {
      return 'La respuesta no puede estar vacía';
    }

    if (params.response.trim().length < 10) {
      return 'La respuesta debe tener al menos 10 caracteres';
    }

    if (params.response.length > 2000) {
      return 'La respuesta no puede exceder 2000 caracteres';
    }

    if (params.attachments != null && params.attachments!.length > 5) {
      return 'No se pueden adjuntar más de 5 archivos';
    }

    return null;
  }
}

class AnswerQueryParams extends Equatable {
  final String queryId;
  final String adminId;
  final String response;
  final List<String>? attachments;
  final bool sendNotification;
  final bool closeQuery;
  final String? internalNotes;

  const AnswerQueryParams({
    required this.queryId,
    required this.adminId,
    required this.response,
    this.attachments,
    this.sendNotification = true,
    this.closeQuery = false,
    this.internalNotes,
  });

  @override
  List<Object?> get props => [
    queryId,
    adminId,
    response,
    attachments,
    sendNotification,
    closeQuery,
    internalNotes,
  ];
}