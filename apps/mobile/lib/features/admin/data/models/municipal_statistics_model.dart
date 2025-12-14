import 'package:equatable/equatable.dart';

import '../../domain/entities/municipal_statistics_entity.dart';

class MunicipalStatisticsModel extends Equatable {
  final int totalReports;
  final int resolvedReports;
  final int pendingReports;
  final int inProgressReports;
  final int totalQueries;
  final int answeredQueries;
  final int totalInfractions;
  final int activeUsers;
  final int inspectors;
  final DateTime lastUpdated;

  const MunicipalStatisticsModel({
    required this.totalReports,
    required this.resolvedReports,
    required this.pendingReports,
    required this.inProgressReports,
    required this.totalQueries,
    required this.answeredQueries,
    required this.totalInfractions,
    required this.activeUsers,
    required this.inspectors,
    required this.lastUpdated,
  });

  factory MunicipalStatisticsModel.fromJson(Map<String, dynamic> json) {
    return MunicipalStatisticsModel(
      totalReports: json['totalReports'] ?? 0,
      resolvedReports: json['resolvedReports'] ?? 0,
      pendingReports: json['pendingReports'] ?? 0,
      inProgressReports: json['inProgressReports'] ?? 0,
      totalQueries: json['totalQueries'] ?? 0,
      answeredQueries: json['answeredQueries'] ?? 0,
      totalInfractions: json['totalInfractions'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      inspectors: json['inspectors'] ?? 0,
      lastUpdated: (json['lastUpdated'] as dynamic).toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'resolvedReports': resolvedReports,
      'pendingReports': pendingReports,
      'inProgressReports': inProgressReports,
      'totalQueries': totalQueries,
      'answeredQueries': answeredQueries,
      'totalInfractions': totalInfractions,
      'activeUsers': activeUsers,
      'inspectors': inspectors,
      'lastUpdated': lastUpdated,
    };
  }

  // Métodos auxiliares para crear objetos de estadísticas con todos los parámetros requeridos
  ReportsStatistics _createReportsStatistics() {
    return ReportsStatistics(
      totalReports: totalReports,
      resolvedReports: resolvedReports,
      pendingReports: pendingReports,
      inProgressReports: inProgressReports,
      rejectedReports: 0, // Valor por defecto
      averageResolutionTimeHours: 24.0, // Valor por defecto
      reportsByCategory: const {}, // Mapa vacío
      reportsByMonth: const {}, // Mapa vacío
      citizenSatisfactionRate: 0.0, // Valor por defecto
    );
  }

  InfractionsStatistics _createInfractionsStatistics() {
    return InfractionsStatistics(
      totalInfractions: totalInfractions,
      confirmedInfractions: totalInfractions,
      appealedInfractions: 0, // Valor por defecto
      cancelledInfractions: 0, // Valor por defecto
      totalFinesAmount: 0.0, // Valor por defecto
      collectedAmount: 0.0, // Valor por defecto
      infractionsByType: const {}, // Mapa vacío
      infractionsByInspector: const {}, // Mapa vacío
      averageProcessingTimeHours: 72.0, // Valor por defecto
    );
  }

  UsersStatistics _createUsersStatistics() {
    return UsersStatistics(
      totalUsers: activeUsers,
      citizenUsers: activeUsers - inspectors, // Calculado
      inspectorUsers: inspectors,
      adminUsers: 0, // Valor por defecto
      activeUsers: activeUsers,
      inactiveUsers: 0, // Valor por defecto
      userRegistrationsByMonth: const {}, // Mapa vacío
      averageUserEngagement: 0.0, // Valor por defecto
    );
  }

  VehiclesStatistics _createVehiclesStatistics() {
    return const VehiclesStatistics(
      totalVehicles: 0, // Valor por defecto
      activeVehicles: 0, // Valor por defecto
      inMaintenanceVehicles: 0, // Valor por defecto
      totalKilometers: 0.0, // Valor por defecto
      averageKmPerVehicle: 0.0, // Valor por defecto
      usageByVehicle: {}, // Mapa vacío
      maintenanceCosts: 0.0, // Valor por defecto
      fuelCosts: 0.0, // Valor por defecto
    );
  }

  PerformanceMetrics _createPerformanceMetrics() {
    // Calcular métricas de rendimiento basadas en los datos disponibles
    double resolutionRateCalc = totalReports > 0 ? (resolvedReports / totalReports) * 100 : 0.0;
    double responseRateCalc = totalQueries > 0 ? (answeredQueries / totalQueries) * 100 : 0.0;
    
    return PerformanceMetrics(
      overallEfficiencyScore: (resolutionRateCalc + responseRateCalc) / 2, // Promedio
      responseTimeScore: responseRateCalc,
      resolutionQualityScore: resolutionRateCalc,
      citizenSatisfactionScore: 80.0, // Valor por defecto
      inspectorProductivityScore: inspectors > 0 ? totalInfractions / inspectors : 0.0,
      monthlyPerformance: const {}, // Mapa vacío
      recommendations: const [], // Lista vacía
    );
  }

  MunicipalStatisticsEntity toEntity() {
    return MunicipalStatisticsEntity(
      totalReports: totalReports,
      resolvedReports: resolvedReports,
      pendingReports: pendingReports,
      inProgressReports: inProgressReports,
      totalQueries: totalQueries,
      answeredQueries: answeredQueries,
      totalInfractions: totalInfractions,
      activeUsers: activeUsers,
      inspectors: inspectors,
      lastUpdated: lastUpdated,
      muniId: '', // Valor por defecto - ajustar según necesidad
      generatedAt: lastUpdated, // Usar lastUpdated como generatedAt
      reports: _createReportsStatistics(),
      infractions: _createInfractionsStatistics(),
      users: _createUsersStatistics(),
      vehicles: _createVehiclesStatistics(),
      performance: _createPerformanceMetrics(),
    );
  }

  @override
  List<Object> get props => [
        totalReports,
        resolvedReports,
        pendingReports,
        inProgressReports,
        totalQueries,
        answeredQueries,
        totalInfractions,
        activeUsers,
        inspectors,
        lastUpdated,
      ];
}