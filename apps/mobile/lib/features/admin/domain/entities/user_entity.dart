import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? muniId;
  final String? muniName;
  final bool isActive;
  final bool isEmailVerified;
  final String? phoneNumber;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final UserPermissions permissions;
  final UserStatistics statistics;
  final List<String> assignedAreas;
  final Map<String, dynamic>? preferences;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.firstName,
    this.lastName,
    required this.role,
    this.muniId,
    this.muniName,
    required this.isActive,
    required this.isEmailVerified,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.permissions,
    required this.statistics,
    required this.assignedAreas,
    this.preferences,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    firstName,
    lastName,
    role,
    muniId,
    muniName,
    isActive,
    isEmailVerified,
    phoneNumber,
    address,
    profileImageUrl,
    createdAt,
    updatedAt,
    lastLoginAt,
    permissions,
    statistics,
    assignedAreas,
    preferences,
  ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? role,
    String? muniId,
    String? muniName,
    bool? isActive,
    bool? isEmailVerified,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserPermissions? permissions,
    UserStatistics? statistics,
    List<String>? assignedAreas,
    Map<String, dynamic>? preferences,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      muniId: muniId ?? this.muniId,
      muniName: muniName ?? this.muniName,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
      statistics: statistics ?? this.statistics,
      assignedAreas: assignedAreas ?? this.assignedAreas,
      preferences: preferences ?? this.preferences,
    );
  }

  // Métodos útiles
  bool get isCitizen => role == 'citizen';
  bool get isInspector => role == 'inspector';
  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'superAdmin';
  
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName;
  }
  
  bool get hasRecentActivity {
    if (lastLoginAt == null) return false;
    return DateTime.now().difference(lastLoginAt!).inDays <= 7;
  }
  
  String get roleDisplayName {
    switch (role) {
      case 'citizen':
        return 'Ciudadano';
      case 'inspector':
        return 'Inspector';
      case 'admin':
        return 'Administrador';
      case 'superAdmin':
        return 'Super Administrador';
      default:
        return role;
    }
  }
}

class UserPermissions extends Equatable {
  final bool canManageUsers;
  final bool canManageReports;
  final bool canManageInfractions;
  final bool canManageVehicles;
  final bool canViewStatistics;
  final bool canExportData;
  final bool canManageSettings;
  final bool canAssignTasks;
  final bool canApproveActions;
  final List<String> allowedModules;

  const UserPermissions({
    required this.canManageUsers,
    required this.canManageReports,
    required this.canManageInfractions,
    required this.canManageVehicles,
    required this.canViewStatistics,
    required this.canExportData,
    required this.canManageSettings,
    required this.canAssignTasks,
    required this.canApproveActions,
    required this.allowedModules,
  });

  factory UserPermissions.fromRole(String role) {
    switch (role) {
      case 'citizen':
        return const UserPermissions(
          canManageUsers: false,
          canManageReports: false,
          canManageInfractions: false,
          canManageVehicles: false,
          canViewStatistics: false,
          canExportData: false,
          canManageSettings: false,
          canAssignTasks: false,
          canApproveActions: false,
          allowedModules: ['reports', 'queries'],
        );
      case 'inspector':
        return const UserPermissions(
          canManageUsers: false,
          canManageReports: true,
          canManageInfractions: true,
          canManageVehicles: true,
          canViewStatistics: true,
          canExportData: false,
          canManageSettings: false,
          canAssignTasks: false,
          canApproveActions: false,
          allowedModules: ['reports', 'infractions', 'vehicles', 'statistics'],
        );
      case 'admin':
        return const UserPermissions(
          canManageUsers: true,
          canManageReports: true,
          canManageInfractions: true,
          canManageVehicles: true,
          canViewStatistics: true,
          canExportData: true,
          canManageSettings: true,
          canAssignTasks: true,
          canApproveActions: true,
          allowedModules: ['reports', 'infractions', 'vehicles', 'statistics', 'users', 'settings'],
        );
      case 'superAdmin':
        return const UserPermissions(
          canManageUsers: true,
          canManageReports: true,
          canManageInfractions: true,
          canManageVehicles: true,
          canViewStatistics: true,
          canExportData: true,
          canManageSettings: true,
          canAssignTasks: true,
          canApproveActions: true,
          allowedModules: ['all'],
        );
      default:
        return const UserPermissions(
          canManageUsers: false,
          canManageReports: false,
          canManageInfractions: false,
          canManageVehicles: false,
          canViewStatistics: false,
          canExportData: false,
          canManageSettings: false,
          canAssignTasks: false,
          canApproveActions: false,
          allowedModules: [],
        );
    }
  }

  @override
  List<Object> get props => [
    canManageUsers,
    canManageReports,
    canManageInfractions,
    canManageVehicles,
    canViewStatistics,
    canExportData,
    canManageSettings,
    canAssignTasks,
    canApproveActions,
    allowedModules,
  ];
}

class UserStatistics extends Equatable {
  final int totalReportsCreated;
  final int totalInfractionsIssued;
  final int totalQueriesAnswered;
  final double averageResponseTimeHours;
  final int tasksCompleted;
  final double performanceScore;
  final DateTime? lastActivityDate;
  final Map<String, int> monthlyActivity;

  const UserStatistics({
    required this.totalReportsCreated,
    required this.totalInfractionsIssued,
    required this.totalQueriesAnswered,
    required this.averageResponseTimeHours,
    required this.tasksCompleted,
    required this.performanceScore,
    this.lastActivityDate,
    required this.monthlyActivity,
  });

  factory UserStatistics.empty() {
    return const UserStatistics(
      totalReportsCreated: 0,
      totalInfractionsIssued: 0,
      totalQueriesAnswered: 0,
      averageResponseTimeHours: 0,
      tasksCompleted: 0,
      performanceScore: 0,
      monthlyActivity: {},
    );
  }

  @override
  List<Object?> get props => [
    totalReportsCreated,
    totalInfractionsIssued,
    totalQueriesAnswered,
    averageResponseTimeHours,
    tasksCompleted,
    performanceScore,
    lastActivityDate,
    monthlyActivity,
  ];
}