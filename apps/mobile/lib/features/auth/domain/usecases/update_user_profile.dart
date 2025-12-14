// lib/features/auth/domain/usecases/update_user_profile.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateUserProfile implements UseCase<UserEntity, UpdateUserProfileParams> {
  final AuthRepository repository;

  UpdateUserProfile(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateUserProfileParams params) {
    return repository.updateUserProfile(
      userId: params.userId,
      name: params.name,
      phoneNumber: params.phoneNumber,
      address: params.address,
    );
  }
}

class UpdateUserProfileParams extends Equatable {
  final String userId;
  final String? name;
  final String? phoneNumber;
  final String? address;

  const UpdateUserProfileParams({
    required this.userId,
    this.name,
    this.phoneNumber,
    this.address,
  });

  @override
  List<Object?> get props => [userId, name, phoneNumber, address];
}