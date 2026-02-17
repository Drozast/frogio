import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frogio_santa_juana/core/error/failures.dart';
import 'package:frogio_santa_juana/features/admin/domain/entities/municipal_statistics_entity.dart';
import 'package:frogio_santa_juana/features/admin/domain/usecases/get_municipal_statistics.dart';
import 'package:frogio_santa_juana/features/admin/presentation/bloc/statistics/statistics_bloc.dart';

class MockGetMunicipalStatistics extends Mock implements GetMunicipalStatistics {}

void main() {
  late StatisticsBloc statisticsBloc;
  late MockGetMunicipalStatistics mockGetMunicipalStatistics;

  setUp(() {
    mockGetMunicipalStatistics = MockGetMunicipalStatistics();
    statisticsBloc = StatisticsBloc(
      getMunicipalStatistics: mockGetMunicipalStatistics,
    );
  });

  tearDown(() {
    statisticsBloc.close();
  });

  final testStatistics = MunicipalStatisticsEntity(
    muniId: 'santa_juana',
    generatedAt: DateTime.now(),
    reports: const ReportsStatistics(
      totalReports: 100,
      pendingReports: 20,
      inProgressReports: 30,
      resolvedReports: 45,
      rejectedReports: 5,
      averageResolutionTimeHours: 48.0,
      reportsByCategory: {'infraestructura': 50, 'seguridad': 30, 'otros': 20},
      reportsByMonth: {'2025-01': 30, '2025-02': 35, '2025-03': 35},
      citizenSatisfactionRate: 4.2,
    ),
    infractions: const InfractionsStatistics(
      totalInfractions: 80,
      confirmedInfractions: 60,
      appealedInfractions: 10,
      cancelledInfractions: 10,
      totalFinesAmount: 5000000.0,
      collectedAmount: 3500000.0,
      infractionsByType: {'estacionamiento': 40, 'velocidad': 25, 'otros': 15},
      infractionsByInspector: {'inspector1': 30, 'inspector2': 50},
      averageProcessingTimeHours: 72.0,
    ),
    users: const UsersStatistics(
      totalUsers: 500,
      citizenUsers: 480,
      inspectorUsers: 15,
      adminUsers: 5,
      activeUsers: 450,
      inactiveUsers: 50,
      userRegistrationsByMonth: {'2025-01': 20, '2025-02': 30},
      averageUserEngagement: 3.5,
    ),
    vehicles: const VehiclesStatistics(
      totalVehicles: 10,
      activeVehicles: 8,
      inMaintenanceVehicles: 2,
      totalKilometers: 15000.0,
      averageKmPerVehicle: 1500.0,
      usageByVehicle: {},
      maintenanceCosts: 500000.0,
      fuelCosts: 300000.0,
    ),
    performance: const PerformanceMetrics(
      overallEfficiencyScore: 85.0,
      responseTimeScore: 80.0,
      resolutionQualityScore: 90.0,
      citizenSatisfactionScore: 84.0,
      inspectorProductivityScore: 88.0,
      monthlyPerformance: {},
      recommendations: [],
    ),
    totalReports: 100,
    resolvedReports: 45,
    pendingReports: 20,
    inProgressReports: 30,
    totalQueries: 0,
    answeredQueries: 0,
    totalInfractions: 80,
    activeUsers: 450,
    inspectors: 15,
    lastUpdated: DateTime.now(),
  );

  group('StatisticsBloc', () {
    test('initial state is StatisticsInitial', () {
      expect(statisticsBloc.state, isA<StatisticsInitial>());
    });

    blocTest<StatisticsBloc, StatisticsState>(
      'emits [StatisticsLoading, StatisticsLoaded] when LoadMunicipalStatisticsEvent is added and succeeds',
      build: () {
        when(() => mockGetMunicipalStatistics(any()))
            .thenAnswer((_) async => Right(testStatistics));
        return statisticsBloc;
      },
      act: (bloc) => bloc.add(const LoadMunicipalStatisticsEvent(muniId: 'santa_juana')),
      expect: () => [
        isA<StatisticsLoading>(),
        isA<StatisticsLoaded>().having(
          (s) => s.statistics.reports.totalReports,
          'totalReports',
          100,
        ),
      ],
      verify: (_) {
        verify(() => mockGetMunicipalStatistics('santa_juana')).called(1);
      },
    );

    blocTest<StatisticsBloc, StatisticsState>(
      'emits [StatisticsLoading, StatisticsError] when LoadMunicipalStatisticsEvent fails',
      build: () {
        when(() => mockGetMunicipalStatistics(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Error de servidor')));
        return statisticsBloc;
      },
      act: (bloc) => bloc.add(const LoadMunicipalStatisticsEvent(muniId: 'santa_juana')),
      expect: () => [
        isA<StatisticsLoading>(),
        isA<StatisticsError>().having(
          (s) => s.message,
          'message',
          'Error de servidor',
        ),
      ],
    );

    blocTest<StatisticsBloc, StatisticsState>(
      'emits [StatisticsLoaded with isRefreshing, StatisticsLoaded] when RefreshStatisticsEvent is added after initial load',
      build: () {
        when(() => mockGetMunicipalStatistics(any()))
            .thenAnswer((_) async => Right(testStatistics));
        return statisticsBloc;
      },
      seed: () => StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(const RefreshStatisticsEvent(muniId: 'santa_juana')),
      expect: () => [
        isA<StatisticsLoaded>().having((s) => s.isRefreshing, 'isRefreshing', true),
        isA<StatisticsLoaded>().having((s) => s.isRefreshing, 'isRefreshing', false),
      ],
    );

    blocTest<StatisticsBloc, StatisticsState>(
      'emits StatisticsInitial when ResetStatisticsEvent is added',
      build: () => statisticsBloc,
      seed: () => StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) => bloc.add(ResetStatisticsEvent()),
      expect: () => [isA<StatisticsInitial>()],
    );
  });

  group('StatisticsLoaded', () {
    test('copyWith creates new instance with updated values', () {
      final original = StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime(2025, 1, 1),
        isRefreshing: false,
      );

      final updated = original.copyWith(isRefreshing: true);

      expect(updated.isRefreshing, true);
      expect(updated.statistics, original.statistics);
      expect(updated.lastUpdated, original.lastUpdated);
    });

    test('props returns correct list', () {
      final state = StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime(2025, 1, 1),
        isRefreshing: false,
      );

      expect(state.props, [testStatistics, DateTime(2025, 1, 1), false]);
    });
  });
}
