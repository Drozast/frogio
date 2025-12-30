// lib/features/auth/di/auth_injection.dart
import 'package:get_it/get_it.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/datasources/auth_remote_data_source_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/forgot_password.dart';
import '../domain/usecases/get_current_user.dart';
import '../domain/usecases/register_user.dart';
import '../domain/usecases/sign_in_user.dart';
import '../domain/usecases/sign_out_user.dart';
import '../domain/usecases/update_user_profile.dart';
import '../domain/usecases/upload_profile_image.dart';
import '../presentation/bloc/auth_bloc.dart';
import '../presentation/bloc/profile/profile_bloc.dart';

class AuthInjection {
  static void init(GetIt sl) {
    // BLoCs
    sl.registerFactory(
      () => AuthBloc(
        getCurrentUser: sl(),
        signInUser: sl(),
        signOutUser: sl(),
        registerUser: sl(),
        forgotPassword: sl(),
      ),
    );

    sl.registerFactory(
      () => ProfileBloc(
        updateUserProfile: sl(),
        uploadProfileImage: sl(),
      ),
    );

    // Use Cases
    sl.registerLazySingleton(() => GetCurrentUser(sl()));
    sl.registerLazySingleton(() => SignInUser(sl()));
    sl.registerLazySingleton(() => SignOutUser(sl()));
    sl.registerLazySingleton(() => RegisterUser(sl()));
    sl.registerLazySingleton(() => ForgotPassword(sl()));
    sl.registerLazySingleton(() => UpdateUserProfile(sl()));
    sl.registerLazySingleton(() => UploadProfileImage(sl()));

    // Repository
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl()),
    );

    // Data Sources
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        firebaseAuth: sl(),
        firestore: sl(),
        storage: sl(),
      ),
    );
  }
}