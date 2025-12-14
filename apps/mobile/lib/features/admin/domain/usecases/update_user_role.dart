import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class UpdateUserRole implements UseCase<void, UpdateUserRoleParams> {
  final AdminRepository repository;

  UpdateUserRole(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserRoleParams params) async {
    return await repository.updateUserRole(
      userId: params.userId,
      newRole: params.newRole,
      adminId: params.adminId,
    );
  }
}

class UpdateUserRoleParams extends Equatable {
  final String userId;
  final String newRole;
  final String adminId;

  const UpdateUserRoleParams({
    required this.userId,
    required this.newRole,
    required this.adminId,
  });

  @override
  List<Object> get props => [userId, newRole, adminId];
}