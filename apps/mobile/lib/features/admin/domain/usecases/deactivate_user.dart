import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/admin_repository.dart';

class DeactivateUser implements UseCase<void, String> {
  final AdminRepository repository;

  DeactivateUser(this.repository);

  @override
  Future<Either<Failure, void>> call(String userId) async {
    return await repository.deactivateUser(userId);
  }
}