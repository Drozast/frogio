// lib/features/admin/domain/entities/municipal_statistics_entity.dart
import 'package:equatable/equatable.dart';

class MunicipalStatisticsEntity extends Equatable {
  final String muniId;
  final DateTime generatedAt;
  final ReportsStatistics reports;
  final InfractionsStatistics infractions;
  final UsersStatistics users;
  final VehiclesStatistics vehicles;
  final PerformanceMetrics performance;

  const MunicipalStatisticsEntity({
    required this.muniId,
    required this.generatedAt,
    required this.reports,
    required this.infractions,
    required this.users,
    required this.vehicles,
    required this.performance, required int totalReports, required int resolvedReports, required int pendingReports, required int inProgressReports, required int totalQueries, required int answeredQueries, required int totalInfractions, required int activeUsers, required int inspectors, required DateTime lastUpdated,
  });

  @override
  List<Object> get props => [
    muniId,
    generatedAt,
    reports,
    infractions,
    users,
    vehicles,
    performance,
  ];
}

class ReportsStatistics extends Equatable {
  final int totalReports;
  final int pendingReports;
  final int inProgressReports;
  final int resolvedReports;
  final int rejectedReports;
  final double averageResolutionTimeHours;
  final Map<String, int> reportsByCategory;
  final Map<String, int> reportsByMonth;
  final double citizenSatisfactionRate;

  const ReportsStatistics({
    required this.totalReports,
    required this.pendingReports,
    required this.inProgressReports,
    required this.resolvedReports,
    required this.rejectedReports,
    required this.averageResolutionTimeHours,
    required this.reportsByCategory,
    required this.reportsByMonth,
    required this.citizenSatisfactionRate,
  });

  double get resolutionRate => 
      totalReports > 0 ? (resolvedReports / totalReports) * 100 : 0;

  @override
  List<Object> get props => [
    totalReports,
    pendingReports,
    inProgressReports,
    resolvedReports,
    rejectedReports,
    averageResolutionTimeHours,
    reportsByCategory,
    reportsByMonth,
    citizenSatisfactionRate,
  ];
}

class InfractionsStatistics extends Equatable {
  final int totalInfractions;
  final int confirmedInfractions;
  final int appealedInfractions;
  final int cancelledInfractions;
  final double totalFinesAmount;
  final double collectedAmount;
  final Map<String, int> infractionsByType;
  final Map<String, int> infractionsByInspector;
  final double averageProcessingTimeHours;

  const InfractionsStatistics({
    required this.totalInfractions,
    required this.confirmedInfractions,
    required this.appealedInfractions,
    required this.cancelledInfractions,
    required this.totalFinesAmount,
    required this.collectedAmount,
    required this.infractionsByType,
    required this.infractionsByInspector,
    required this.averageProcessingTimeHours,
  });

  double get collectionRate => 
      totalFinesAmount > 0 ? (collectedAmount / totalFinesAmount) * 100 : 0;

  double get confirmationRate => 
      totalInfractions > 0 ? (confirmedInfractions / totalInfractions) * 100 : 0;

  @override
  List<Object> get props => [
    totalInfractions,
    confirmedInfractions,
    appealedInfractions,
    cancelledInfractions,
    totalFinesAmount,
    collectedAmount,
    infractionsByType,
    infractionsByInspector,
    averageProcessingTimeHours,
  ];
}

class UsersStatistics extends Equatable {
  final int totalUsers;
  final int citizenUsers;
  final int inspectorUsers;
  final int adminUsers;
  final int activeUsers;
  final int inactiveUsers;
  final Map<String, int> userRegistrationsByMonth;
  final double averageUserEngagement;

  const UsersStatistics({
    required this.totalUsers,
    required this.citizenUsers,
    required this.inspectorUsers,
    required this.adminUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.userRegistrationsByMonth,
    required this.averageUserEngagement,
  });

  double get activeUsersRate => 
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;

  @override
  List<Object> get props => [
    totalUsers,
    citizenUsers,
    inspectorUsers,
    adminUsers,
    activeUsers,
    inactiveUsers,
    userRegistrationsByMonth,
    averageUserEngagement,
  ];

  static empty() {}
}

class VehiclesStatistics extends Equatable {
  final int totalVehicles;
  final int activeVehicles;
  final int inMaintenanceVehicles;
  final double totalKilometers;
  final double averageKmPerVehicle;
  final Map<String, int> usageByVehicle;
  final double maintenanceCosts;
  final double fuelCosts;

  const VehiclesStatistics({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.inMaintenanceVehicles,
    required this.totalKilometers,
    required this.averageKmPerVehicle,
    required this.usageByVehicle,
    required this.maintenanceCosts,
    required this.fuelCosts,
  });

  double get vehicleUtilizationRate => 
      totalVehicles > 0 ? (activeVehicles / totalVehicles) * 100 : 0;

  @override
  List<Object> get props => [
    totalVehicles,
    activeVehicles,
    inMaintenanceVehicles,
    totalKilometers,
    averageKmPerVehicle,
    usageByVehicle,
    maintenanceCosts,
    fuelCosts,
  ];
}

class PerformanceMetrics extends Equatable {
  final double overallEfficiencyScore;
  final double responseTimeScore;
  final double resolutionQualityScore;
  final double citizenSatisfactionScore;
  final double inspectorProductivityScore;
  final Map<String, double> monthlyPerformance;
  final List<String> recommendations;

  const PerformanceMetrics({
    required this.overallEfficiencyScore,
    required this.responseTimeScore,
    required this.resolutionQualityScore,
    required this.citizenSatisfactionScore,
    required this.inspectorProductivityScore,
    required this.monthlyPerformance,
    required this.recommendations,
  });

  String get performanceGrade {
    if (overallEfficiencyScore >= 90) return 'Excelente';
    if (overallEfficiencyScore >= 80) return 'Muy Bueno';
    if (overallEfficiencyScore >= 70) return 'Bueno';
    if (overallEfficiencyScore >= 60) return 'Regular';
    return 'Necesita Mejoras';
  }

  @override
  List<Object> get props => [
    overallEfficiencyScore,
    responseTimeScore,
    resolutionQualityScore,
    citizenSatisfactionScore,
    inspectorProductivityScore,
    monthlyPerformance,
    recommendations,
  ];
}