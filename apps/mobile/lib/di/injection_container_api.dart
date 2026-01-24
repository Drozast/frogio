/// Container de inyeccion de dependencias para REST API.
///
/// Usa Dio para HTTP y SharedPreferences para almacenamiento local.
library;

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

// Core
import '../core/config/api_config.dart';
import '../core/services/session_timeout_service.dart';
import '../core/network/auth_http_client.dart';

// Auth Feature
import '../features/auth/data/datasources/auth_api_data_source.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/sign_in_user.dart';
import '../features/auth/domain/usecases/register_user.dart';
import '../features/auth/domain/usecases/sign_out_user.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/update_user_profile.dart';
import '../features/auth/domain/usecases/upload_profile_image.dart';
import '../features/auth/domain/usecases/forgot_password.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/profile/profile_bloc.dart';

// Citizen Reports Feature
import '../features/citizen/data/datasources/enhanced_report_api_data_source.dart';
import '../features/citizen/data/datasources/enhanced_report_remote_data_source.dart' as enhanced_ds;
import '../features/citizen/data/repositories/enhanced_report_repository_impl.dart';
import '../features/citizen/domain/repositories/enhanced_report_repository.dart' as enhanced_repo;
import '../features/citizen/domain/usecases/reports/enhanced_report_use_cases.dart';
import '../features/citizen/presentation/bloc/report/enhanced_report_bloc.dart';

// Inspector Infractions Feature
import '../features/inspector/data/datasources/infraction_api_data_source.dart';
import '../features/inspector/data/datasources/infraction_remote_data_source.dart';
import '../features/inspector/data/repositories/infraction_repository_impl.dart';
import '../features/inspector/domain/repositories/infraction_repository.dart';
import '../features/inspector/domain/usecases/create_infraction.dart';
import '../features/inspector/domain/usecases/get_infractions_by_inspector.dart';
import '../features/inspector/domain/usecases/update_infraction_status.dart';
import '../features/inspector/domain/usecases/upload_infraction_image.dart';

// Inspector Citations Feature
import '../features/inspector/data/datasources/citation_api_data_source.dart';
import '../features/inspector/data/datasources/citation_remote_data_source.dart';
import '../features/inspector/data/repositories/citation_repository_impl.dart';
import '../features/inspector/domain/repositories/citation_repository.dart';
import '../features/inspector/presentation/bloc/citation_bloc.dart';

// Vehicles Feature
import '../features/vehicles/data/datasources/vehicle_api_data_source.dart';
import '../features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import '../features/vehicles/data/repositories/vehicle_repository_impl.dart';
import '../features/vehicles/data/repositories/vehicle_repository.dart';
import '../features/vehicles/domain/usecases/get_vehicles.dart';
import '../features/vehicles/domain/usecases/start_vehicle_usage.dart';
import '../features/vehicles/domain/usecases/end_vehicle_usage.dart';
import '../features/vehicles/presentation/bloc/vehicle_bloc.dart';

// Panic Feature
import '../features/panic/data/datasources/panic_api_data_source.dart';
import '../features/panic/data/datasources/panic_remote_data_source.dart';
import '../features/panic/data/repositories/panic_repository_impl.dart';
import '../features/panic/domain/repositories/panic_repository.dart';
import '../features/panic/domain/usecases/send_panic_alert.dart';
import '../features/panic/domain/usecases/cancel_panic_alert.dart';
import '../features/panic/presentation/bloc/panic_bloc.dart';

// Notifications Feature
import '../core/data/notification_api_data_source.dart';
import '../core/blocs/notification/notification_bloc.dart';

// Admin Feature
import '../features/admin/data/datasources/admin_api_data_source.dart';
import '../features/admin/data/datasources/admin_remote_data_source.dart';
import '../features/admin/data/repositories/admin_repository_impl.dart';
import '../features/admin/domain/repositories/admin_repository.dart';
import '../features/admin/domain/usecases/get_municipal_statistics.dart';
import '../features/admin/presentation/bloc/statistics/statistics_bloc.dart';

final sl = GetIt.instance;
final logger = Logger();

Future<void> initApi() async {
  logger.i('FROGIO: Initializing REST API dependencies...');

  // ===== EXTERNAL =====
  // HTTP Client
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ===== CORE =====
  logger.i('  - Core services');
  sl.registerLazySingleton<Logger>(() => Logger());
  sl.registerLazySingleton<SessionTimeoutService>(() => SessionTimeoutService());

  // Auth HTTP Client (with automatic token refresh)
  sl.registerLazySingleton<AuthHttpClient>(
    () => AuthHttpClient(
      inner: sl<http.Client>(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
      tenantId: ApiConfig.tenantId,
    ),
  );

  // ===== AUTH FEATURE =====
  logger.i('  - Auth feature');

  // Data sources
  // Registrar la implementación concreta para acceso directo (getFileUrl)
  sl.registerLazySingleton<AuthApiDataSource>(
    () => AuthApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
      tenantId: ApiConfig.tenantId,
    ),
  );

  // Registrar la interfaz que apunta a la misma instancia
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => sl<AuthApiDataSource>(),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => SignOutUser(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl()));
  sl.registerLazySingleton(() => UploadProfileImage(sl()));
  sl.registerLazySingleton(() => ForgotPassword(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      signInUser: sl(),
      registerUser: sl(),
      signOutUser: sl(),
      getCurrentUser: sl(),
      forgotPassword: sl(),
    ),
  );

  // Profile BLoC
  sl.registerFactory(
    () => ProfileBloc(
      updateUserProfile: sl(),
      uploadProfileImage: sl(),
    ),
  );

  // ===== CITIZEN REPORTS FEATURE =====
  logger.i('  - Citizen reports feature');

  // Data sources
  sl.registerLazySingleton<enhanced_ds.ReportRemoteDataSource>(
    () => EnhancedReportApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<enhanced_repo.ReportRepository>(
    () => ReportRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateEnhancedReport(sl()));
  sl.registerLazySingleton(() => GetEnhancedReportsByUser(sl()));
  sl.registerLazySingleton(() => GetEnhancedReportById(sl()));
  sl.registerLazySingleton(() => UpdateReportStatus(sl()));
  sl.registerLazySingleton(() => AddReportResponse(sl()));
  sl.registerLazySingleton(() => GetReportsByStatus(sl()));
  sl.registerLazySingleton(() => AssignReport(sl()));
  sl.registerLazySingleton(() => WatchReportsByUser(sl()));
  sl.registerLazySingleton(() => WatchReportsByStatus(sl()));

  // BLoC
  sl.registerFactory(
    () => ReportBloc(
      createReport: sl(),
      getReportsByUser: sl(),
      getReportById: sl(),
      updateReportStatus: sl(),
      addReportResponse: sl(),
      getReportsByStatus: sl(),
      assignReport: sl(),
      watchReportsByUser: sl(),
      watchReportsByStatus: sl(),
    ),
  );

  // ===== INSPECTOR INFRACTIONS FEATURE =====
  logger.i('  - Inspector infractions feature');

  // Data sources
  sl.registerLazySingleton<InfractionRemoteDataSource>(
    () => InfractionApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<InfractionRepository>(
    () => InfractionRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CreateInfraction(sl()));
  sl.registerLazySingleton(() => GetInfractionsByInspector(sl()));
  sl.registerLazySingleton(() => UpdateInfractionStatus(sl()));
  sl.registerLazySingleton(() => UploadInfractionImage(sl()));

  // ===== INSPECTOR CITATIONS FEATURE =====
  logger.i('  - Inspector citations feature');

  // Data sources
  sl.registerLazySingleton<CitationRemoteDataSource>(
    () => CitationApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<CitationRepository>(
    () => CitationRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => CitationBloc(
      repository: sl(),
    ),
  );

  // ===== VEHICLES FEATURE =====
  logger.i('  - Vehicles feature');

  // Data sources
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetVehicles(sl()));
  sl.registerLazySingleton(() => StartVehicleUsage(repository: sl()));
  sl.registerLazySingleton(() => EndVehicleUsage(repository: sl()));

  // BLoC
  sl.registerFactory(
    () => VehicleBloc(
      getVehicles: sl(),
      startVehicleUsage: sl(),
      endVehicleUsage: sl(),
    ),
  );

  // ===== PANIC FEATURE =====
  logger.i('  - Panic feature');

  // Data sources
  sl.registerLazySingleton<PanicRemoteDataSource>(
    () => PanicApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<PanicRepository>(
    () => PanicRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendPanicAlert(sl()));
  sl.registerLazySingleton(() => CancelPanicAlert(sl()));

  // BLoC
  sl.registerFactory(
    () => PanicBloc(
      sendPanicAlert: sl(),
      cancelPanicAlert: sl(),
    ),
  );

  // ===== NOTIFICATIONS FEATURE =====
  logger.i('  - Notifications feature');

  // Data sources (uses AuthHttpClient for automatic token refresh)
  sl.registerLazySingleton<NotificationApiDataSource>(
    () => NotificationApiDataSource(
      client: sl<AuthHttpClient>(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // BLoC
  sl.registerFactory(
    () => NotificationBloc(
      apiDataSource: sl(),
    ),
  );

  // ===== ADMIN FEATURE =====
  logger.i('  - Admin feature');

  // Data sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMunicipalStatistics(sl()));

  // BLoC
  sl.registerFactory(
    () => StatisticsBloc(
      getMunicipalStatistics: sl(),
    ),
  );

  logger.i('FROGIO: Dependencies initialized successfully!');
  logger.i('API Base URL: ${ApiConfig.activeBaseUrl}');
  logger.i('Tenant ID: ${ApiConfig.tenantId}');
}
