// lib/features/admin/presentation/bloc/user_management/user_management_state.dart
import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_entity.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();
  
  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UsersLoaded extends UserManagementState {
  final List<UserEntity> users;
  final List<UserEntity> filteredUsers;
  final String currentFilter;
  final String searchQuery;
  
  const UsersLoaded({
    required this.users,
    List<UserEntity>? filteredUsers,
    this.currentFilter = 'Todos',
    this.searchQuery = '',
  }) : filteredUsers = filteredUsers ?? users;
  
  @override
  List<Object> get props => [users, filteredUsers, currentFilter, searchQuery];
}

class UserManagementError extends UserManagementState {
  final String message;
  
  const UserManagementError({required this.message});
  
  @override
  List<Object> get props => [message];
}