// lib/features/admin/presentation/bloc/user_management/user_management_event.dart
import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends UserManagementEvent {
  final String muniId;
  
  const LoadUsersEvent({required this.muniId});
  
  @override
  List<Object> get props => [muniId];
}

class UpdateUserRoleEvent extends UserManagementEvent {
  final String userId;
  final String newRole;
  final String adminId;
  
  const UpdateUserRoleEvent({
    required this.userId,
    required this.newRole,
    required this.adminId,
  });
  
  @override
  List<Object> get props => [userId, newRole, adminId];
}

class FilterUsersEvent extends UserManagementEvent {
  final String filter;
  
  const FilterUsersEvent({required this.filter});
  
  @override
  List<Object> get props => [filter];
}

class SearchUsersEvent extends UserManagementEvent {
  final String query;
  
  const SearchUsersEvent({required this.query});
  
  @override
  List<Object> get props => [query];
}

class ActivateUserEvent extends UserManagementEvent {
  final String userId;
  
  const ActivateUserEvent({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class DeactivateUserEvent extends UserManagementEvent {
  final String userId;
  
  const DeactivateUserEvent({required this.userId});
  
  @override
  List<Object> get props => [userId];
}