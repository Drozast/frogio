import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frogio_santa_juana/features/admin/domain/entities/municipal_statistics_entity.dart';
import 'package:frogio_santa_juana/features/admin/presentation/bloc/statistics/statistics_bloc.dart';
import 'package:frogio_santa_juana/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:frogio_santa_juana/features/auth/domain/entities/user_entity.dart';

class MockStatisticsBloc extends MockBloc<StatisticsEvent, StatisticsState>
    implements StatisticsBloc {}

class FakeStatisticsEvent extends Fake implements StatisticsEvent {}

class FakeStatisticsState extends Fake implements StatisticsState {}

void main() {
  late MockStatisticsBloc mockStatisticsBloc;
  late UserEntity testUser;

  setUpAll(() {
    registerFallbackValue(FakeStatisticsEvent());
    registerFallbackValue(FakeStatisticsState());
  });

  setUp(() {
    mockStatisticsBloc = MockStatisticsBloc();
    testUser = UserEntity(
      id: 'test-admin-id',
      email: 'admin@test.cl',
      name: 'Admin Test',
      role: 'admin',
      muniId: 'santa_juana',
      phoneNumber: '+56912345678',
      createdAt: DateTime.now(),
    );
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
      reportsByCategory: {},
      reportsByMonth: {},
      citizenSatisfactionRate: 4.2,
    ),
    infractions: const InfractionsStatistics(
      totalInfractions: 80,
      confirmedInfractions: 60,
      appealedInfractions: 10,
      cancelledInfractions: 10,
      totalFinesAmount: 5000000.0,
      collectedAmount: 3500000.0,
      infractionsByType: {},
      infractionsByInspector: {},
      averageProcessingTimeHours: 72.0,
    ),
    users: const UsersStatistics(
      totalUsers: 500,
      citizenUsers: 480,
      inspectorUsers: 15,
      adminUsers: 5,
      activeUsers: 450,
      inactiveUsers: 50,
      userRegistrationsByMonth: {},
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

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<StatisticsBloc>.value(
        value: mockStatisticsBloc,
        child: AdminDashboardScreen(user: testUser),
      ),
    );
  }

  group('AdminDashboardScreen Widget Tests', () {
    testWidgets('should display loading indicator when state is StatisticsLoading',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state)
          .thenReturn(const StatisticsLoading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display statistics when state is StatisticsLoaded',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Check for key metrics cards
      expect(find.text('Denuncias'), findsOneWidget);
      expect(find.text('100'), findsOneWidget); // Total reports
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('20'), findsOneWidget); // Pending reports
      expect(find.text('Citaciones'), findsOneWidget);
      expect(find.text('80'), findsOneWidget); // Total citations
      expect(find.text('Usuarios'), findsOneWidget);
      expect(find.text('500'), findsOneWidget); // Active users
    });

    testWidgets('should display user greeting with correct name',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsInitial());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Admin Test'), findsOneWidget);
      expect(find.text('Administrador Municipal'), findsOneWidget);
    });

    testWidgets('should display operational overview section',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Resumen Operacional'), findsOneWidget);
      expect(find.text('Denuncias Resueltas'), findsOneWidget);
    });

    testWidgets('should dispatch LoadMunicipalStatisticsEvent on init',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsInitial());

      await tester.pumpWidget(buildTestWidget());
      // Use pump with duration instead of pumpAndSettle due to animations
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockStatisticsBloc.add(
            const LoadMunicipalStatisticsEvent(muniId: 'santa_juana'),
          )).called(1);
    });

    testWidgets('should have refresh button that dispatches RefreshStatisticsEvent',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Find and tap the refresh button in the app bar
      final refreshButton = find.byIcon(Icons.refresh_rounded).first;
      await tester.tap(refreshButton);
      await tester.pump();

      verify(() => mockStatisticsBloc.add(
            const RefreshStatisticsEvent(muniId: 'santa_juana'),
          )).called(1);
    });

    testWidgets('should display quick actions section',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Acciones Rapidas'), findsOneWidget);
    });

    testWidgets('should display recent activity section',
        (WidgetTester tester) async {
      when(() => mockStatisticsBloc.state).thenReturn(StatisticsLoaded(
        statistics: testStatistics,
        lastUpdated: DateTime.now(),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Actividad Reciente'), findsOneWidget);
    });
  });
}
