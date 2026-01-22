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

// Citizen Reports Feature
import '../features/citizen/data/datasources/report_api_data_source.dart';
import '../features/citizen/data/datasources/report_remote_data_source.dart';
import '../features/citizen/data/repositories/report_repository_impl.dart';
import '../features/citizen/domain/repositories/report_repository.dart';

// Inspector Infractions Feature
import '../features/inspector/data/datasources/infraction_api_data_source.dart';
import '../features/inspector/data/datasources/infraction_remote_data_source.dart';
import '../features/inspector/data/repositories/infraction_repository_impl.dart';
import '../features/inspector/domain/repositories/infraction_repository.dart';
import '../features/inspector/domain/usecases/create_infraction.dart';
import '../features/inspector/domain/usecases/get_infractions_by_inspector.dart';
import '../features/inspector/domain/usecases/update_infraction_status.dart';
import '../features/inspector/domain/usecases/upload_infraction_image.dart';

// Vehicles Feature
import '../features/vehicles/data/datasources/vehicle_api_data_source.dart';
import '../features/vehicles/data/datasources/vehicle_remote_data_source.dart';
import '../features/vehicles/data/repositories/vehicle_repository_impl.dart';
import '../features/vehicles/data/repositories/vehicle_repository.dart';
import '../features/vehicles/domain/usecases/get_vehicles.dart';
import '../features/vehicles/domain/usecases/start_vehicle_usage.dart';
import '../features/vehicles/domain/usecases/end_vehicle_usage.dart';
import '../features/vehicles/presentation/bloc/vehicle_bloc.dart';

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

  // ===== AUTH FEATURE =====
  logger.i('  - Auth feature');

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
      tenantId: ApiConfig.tenantId,
    ),
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

  // ===== CITIZEN REPORTS FEATURE =====
  logger.i('  - Citizen reports feature');

  // Data sources
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportApiDataSource(
      client: sl(),
      prefs: sl(),
      baseUrl: ApiConfig.activeBaseUrl,
    ),
  );

  // Repository
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(
      remoteDataSource: sl(),
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

  logger.i('FROGIO: Dependencies initialized successfully!');
  logger.i('API Base URL: ${ApiConfig.activeBaseUrl}');
  logger.i('Tenant ID: ${ApiConfig.tenantId}');
}
