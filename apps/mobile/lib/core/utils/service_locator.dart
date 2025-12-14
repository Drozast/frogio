// lib/core/utils/service_locator.dart
import 'package:get_it/get_it.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  // Getter principal
  static T get<T extends Object>() => _getIt.get<T>();

  // Getter con parámetro opcional
  static T? getOptional<T extends Object>() {
    try {
      return _getIt.get<T>();
    } catch (e) {
      return null;
    }
  }

  // Registrar servicios manualmente (útil para testing)
  static void registerSingleton<T extends Object>(T instance) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerSingleton<T>(instance);
    }
  }

  static void registerFactory<T extends Object>(T Function() factory) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerFactory<T>(factory);
    }
  }

  static void registerLazySingleton<T extends Object>(T Function() factory) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerLazySingleton<T>(factory);
    }
  }

  // Verificar si un servicio está registrado
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  // Remover registros (útil para testing)
  static Future<void> unregister<T extends Object>() async {
    if (_getIt.isRegistered<T>()) {
      await _getIt.unregister<T>();
    }
  }

  // Reset completo (útil para testing)
  static Future<void> reset() async {
    await _getIt.reset();
  }

  // Verificar estado
  static Future<void> get isReady => _getIt.allReady();

  // Esperar a que todos los servicios estén listos
  static Future<void> allReady() => _getIt.allReady();
}

// Extension para facilitar uso en widgets
extension ServiceLocatorContext on Object {
  T locate<T extends Object>() => ServiceLocator.get<T>();
  T? locateOptional<T extends Object>() => ServiceLocator.getOptional<T>();
}