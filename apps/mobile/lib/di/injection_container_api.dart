// lib/di/injection_container_api.dart
/// 🚧 ARCHIVO DE REFERENCIA - NO USAR DIRECTAMENTE 🚧
/// 
/// Este archivo es un template/ejemplo de cómo configurar la inyección de
/// dependencias para usar las nuevas fuentes de datos REST API.
/// 
/// Para usar este archivo:
/// 1. Revisar los constructores de los BLoCs para usar los parámetros correctos
/// 2. Descomentar las secciones según sea necesario
/// 3. Actualizar main.dart para usar initApi() en lugar de init()
/// 
/// NOTA: Actualmente contiene ejemplos de configuración que necesitan ajustarse
/// a los constructores reales de cada BLoC.

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

// Core
import '../core/config/api_config.dart';

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
// import '../features/auth/presentation/bloc/auth_bloc.dart';
// import '../features/auth/presentation/bloc/profile/profile_bloc.dart';

// Citizen Reports Feature
import '../features/citizen/data/datasources/report_api_data_source.dart';
import '../features/citizen/data/datasources/report_remote_data_source.dart';
import '../features/citizen/data/repositories/report_repository_impl.dart';
import '../features/citizen/domain/repositories/report_repository.dart';
// import '../features/citizen/presentation/bloc/report/report_bloc.dart';

// Inspector Infractions Feature
import '../features/inspector/data/datasources/infraction_api_data_source.dart';
import '../features/inspector/data/datasources/infraction_remote_data_source.dart';
import '../features/inspector/data/repositories/infraction_repository_impl.dart';
import '../features/inspector/domain/repositories/infraction_repository.dart';
import '../features/inspector/domain/usecases/create_infraction.dart';
import '../features/inspector/domain/usecases/get_infractions_by_inspector.dart';
import '../features/inspector/domain/usecases/update_infraction_status.dart';
import '../features/inspector/domain/usecases/upload_infraction_image.dart';
// import '../features/inspector/presentation/bloc/infraction_bloc.dart';

final sl = GetIt.instance;
final logger = Logger();

Future<void> initApi() async {
  logger.i('🚀 FROGIO: Initializing REST API dependencies...');

  // ===== EXTERNAL =====
  // HTTP Client
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ===== CORE =====
  logger.i('  - Core services');
  sl.registerLazySingleton<Logger>(() => Logger());

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

  // BLoC - COMENTADO: Necesita ajustarse a los constructores reales
  // sl.registerFactory(
  //   () => AuthBloc(
  //     signInUser: sl(),
  //     registerUser: sl(),
  //     signOutUser: sl(),
  //     getCurrentUser: sl(),
  //     // Agregar parámetros faltantes según el constructor real
  //   ),
  // );

  // sl.registerFactory(
  //   () => ProfileBloc(
  //     // Ajustar parámetros según el constructor real
  //   ),
  // );

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

  // Use cases - Agregar según sean necesarios
  // sl.registerLazySingleton(() => CreateReport(sl()));
  // sl.registerLazySingleton(() => GetReportsByUser(sl()));
  // sl.registerLazySingleton(() => GetReportById(sl()));
  // sl.registerLazySingleton(() => UpdateReportStatus(sl()));
  // etc.

  // BLoC - COMENTADO: Necesita ajustarse a los constructores reales
  // sl.registerFactory(
  //   () => ReportBloc(
  //     // Ajustar parámetros según el constructor real
  //   ),
  // );

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

  // BLoC - COMENTADO: Necesita ajustarse a los constructores reales
  // sl.registerFactory(
  //   () => InfractionBloc(
  //     createInfraction: sl(),
  //     getInfractionsByInspector: sl(),
  //     updateInfractionStatus: sl(),
  //     uploadInfractionImage: sl(),
  //   ),
  // );

  logger.i('✅ FROGIO: Dependencies initialized successfully!');
  logger.i('🌐 API Base URL: ${ApiConfig.activeBaseUrl}');
  logger.i('🏛️  Tenant ID: ${ApiConfig.tenantId}');
}
