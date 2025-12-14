// lib/features/admin/presentation/bloc/user_management/user_management_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/activate_user.dart';
import '../../../domain/usecases/deactivate_user.dart';
import '../../../domain/usecases/get_all_users.dart';
import '../../../domain/usecases/update_user_role.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final GetAllUsers getAllUsers;
  final UpdateUserRole updateUserRole;
  final ActivateUser activateUser;
  final DeactivateUser deactivateUser;

  UserManagementBloc({
    required this.getAllUsers,
    required this.updateUserRole,
    required this.activateUser,
    required this.deactivateUser,
  }) : super(UserManagementInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
    on<FilterUsersEvent>(_onFilterUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<ActivateUserEvent>(_onActivateUser);
    on<DeactivateUserEvent>(_onDeactivateUser);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    
    final result = await getAllUsers(event.muniId);
    
    result.fold(
      (failure) => emit(UserManagementError(message: failure.message)),
      (users) => emit(UsersLoaded(
        users: users,
        filteredUsers: users,
      )),
    );
  }

  Future<void> _onUpdateUserRole(
    UpdateUserRoleEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final result = await updateUserRole(UpdateUserRoleParams(
        userId: event.userId,
        newRole: event.newRole,
        adminId: event.adminId,
      ));
      
      result.fold(
        (failure) => emit(UserManagementError(message: failure.message)),
        (_) {
          // Recargar usuarios después de actualizar
          if (state is UsersLoaded) {
            final currentState = state as UsersLoaded;
            final muniId = _getMuniIdFromCurrentState(currentState);
            if (muniId != null) {
              add(LoadUsersEvent(muniId: muniId));
            }
          }
        },
      );
    } catch (e) {
      emit(UserManagementError(message: 'Error al actualizar rol: ${e.toString()}'));
    }
  }

  void _onFilterUsers(
    FilterUsersEvent event,
    Emitter<UserManagementState> emit,
  ) {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      final filteredUsers = event.filter == 'Todos'
          ? currentState.users
          : currentState.users.where((user) => user.role == event.filter).toList();
      
      emit(UsersLoaded(
        users: currentState.users,
        filteredUsers: filteredUsers,
        currentFilter: event.filter,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  void _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserManagementState> emit,
  ) {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      final filteredUsers = event.query.isEmpty
          ? currentState.users
          : currentState.users.where((user) =>
              user.displayName.toLowerCase().contains(event.query.toLowerCase()) ||
              user.email.toLowerCase().contains(event.query.toLowerCase())
            ).toList();
      
      emit(UsersLoaded(
        users: currentState.users,
        filteredUsers: filteredUsers,
        currentFilter: currentState.currentFilter,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onActivateUser(
    ActivateUserEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final result = await activateUser(event.userId);
      
      result.fold(
        (failure) => emit(UserManagementError(message: failure.message)),
        (_) {
          // Recargar usuarios después de activar
          if (state is UsersLoaded) {
            final currentState = state as UsersLoaded;
            final muniId = _getMuniIdFromCurrentState(currentState);
            if (muniId != null) {
              add(LoadUsersEvent(muniId: muniId));
            }
          }
        },
      );
    } catch (e) {
      emit(UserManagementError(message: 'Error al activar usuario: ${e.toString()}'));
    }
  }

  Future<void> _onDeactivateUser(
    DeactivateUserEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final result = await deactivateUser(event.userId);
      
      result.fold(
        (failure) => emit(UserManagementError(message: failure.message)),
        (_) {
          // Recargar usuarios después de desactivar
          if (state is UsersLoaded) {
            final currentState = state as UsersLoaded;
            final muniId = _getMuniIdFromCurrentState(currentState);
            if (muniId != null) {
              add(LoadUsersEvent(muniId: muniId));
            }
          }
        },
      );
    } catch (e) {
      emit(UserManagementError(message: 'Error al desactivar usuario: ${e.toString()}'));
    }
  }

  // Método auxiliar para obtener muniId del estado actual
  String? _getMuniIdFromCurrentState(UsersLoaded state) {
    if (state.users.isNotEmpty) {
      return state.users.first.muniId;
    }
    return null;
  }
}