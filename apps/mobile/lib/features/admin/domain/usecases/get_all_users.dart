import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/admin_repository.dart';

class GetAllUsers implements UseCase<List<UserEntity>, String> {
  final AdminRepository repository;

  GetAllUsers(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(String muniId) async {
    return await repository.getAllUsers(muniId);
  }
}