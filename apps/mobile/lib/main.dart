// lib/main.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/blocs/notification/notification_bloc.dart';
import 'core/presentation/pages/notifications_screen.dart';
import 'core/services/notification_manager.dart';
import 'features/vehicles/data/services/trip_tracking_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/animations.dart';
import 'dashboard/presentation/pages/dashboard_screen.dart';
import 'di/injection_container_api.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/edit_profile_screen.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/citizen/presentation/pages/enhanced_my_reports_screen.dart';
import 'features/citizen/presentation/pages/enhanced_report_detail_screen.dart';
import 'features/inspector/presentation/pages/inspector_map_screen.dart';
import 'features/legal/presentation/pages/privacy_policy_screen.dart';
import 'features/panic/presentation/pages/panic_screen.dart';
import 'features/panic/presentation/pages/sos_tracking_screen.dart';
import 'tenants/current_tenant.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paso 1: arrancar la UI inmediatamente
  runApp(const _BootstrapApp());

  // Paso 2: Firebase + Crashlytics
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    debugPrint('FROGIO: Firebase + Crashlytics initialized OK');
  } catch (e) {
    debugPrint('FROGIO: Firebase init error: $e');
  }

  // Paso 3: inicializar dependencias
  try {
    await di.initApi();
    debugPrint('FROGIO: initApi completed OK');
  } catch (e, st) {
    debugPrint('FROGIO: initApi error: $e\n$st');
  }

  try {
    await NotificationManager().initialize();
    debugPrint('FROGIO: NotificationManager initialized OK');
  } catch (e) {
    debugPrint('FROGIO: NotificationManager error: $e');
  }

  // Restore active vehicle trip tracking if any (resumes GPS recording)
  try {
    await TripTrackingService().restoreActiveTrip();
  } catch (e) {
    debugPrint('FROGIO: TripTracking restore error: $e');
  }

  // Paso 4: reemplazar con la app real
  runApp(const MyApp());
}

/// App mínima que muestra mientras se inicializan dependencias
class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF00FF88),
              ),
              SizedBox(height: 20),
              Text('Cargando FROGIO...', style: TextStyle(color: Colors.black, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        // Unificar instancia global de notificaciones con DI y carga inicial
        BlocProvider(
          create: (_) => di.sl<NotificationBloc>()..add(LoadNotificationsEvent()),
        ),
      ],
      child: MaterialApp(
        title: currentTenant.appTitle,
        theme: AppTheme.lightThemeFor(
          primaryColor: currentTenant.primaryColor,
          primaryDarkColor: currentTenant.primaryDark,
          accentColorValue: currentTenant.accentColor,
        ),
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'CL'),
        supportedLocales: const [Locale('es', 'CL')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: NotificationManager().navigatorKey,
        // Envolver en PopScope para prevenir cierre accidental
        home: const _AppWrapper(),
        onGenerateRoute: (settings) {
          // Manejo dinamico de rutas con parametros
          switch (settings.name) {
            case '/notifications':
              return FadeScaleRoute(page: const NotificationsScreen());

            case '/reports':
              final userId = settings.arguments as String? ?? '';
              return FadeScaleRoute(page: MyReportsScreen(userId: userId));

            case '/profile':
              return FadeScaleRoute(
                page: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return EditProfileScreen(user: state.user);
                    } else {
                      return const SplashScreen();
                    }
                  },
                ),
              );

            case '/dashboard':
              return FadeScaleRoute(page: const DashboardScreen());

            case '/privacy-policy':
              return FadeScaleRoute(page: const PrivacyPolicyScreen());

            case '/report-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              final reportId = args?['reportId'] as String? ?? '';
              final userRole = args?['userRole'] as String?;
              return FadeScaleRoute(
                page: EnhancedReportDetailScreen(
                  reportId: reportId,
                  currentUserRole: userRole,
                ),
              );

            case '/panic':
              return FadeScaleRoute(
                page: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return PanicScreen(user: state.user);
                    } else {
                      return const SplashScreen();
                    }
                  },
                ),
              );

            case '/sos-tracking':
              final args = settings.arguments as Map<String, dynamic>?;
              final alertId = args?['alertId'] as String?;
              return FadeScaleRoute(page: SosTrackingScreen(alertId: alertId));

            case '/inspector-map':
              final args = settings.arguments as Map<String, dynamic>?;
              final lat = args?['latitude'] as double?;
              final lng = args?['longitude'] as double?;
              return FadeScaleRoute(
                page: InspectorMapScreen(
                  initialLocation: (lat != null && lng != null) ? LatLng(lat, lng) : null,
                ),
              );

            default:
              return FadeScaleRoute(
                page: Scaffold(
                  appBar: AppBar(title: const Text('Pagina no encontrada')),
                  body: const Center(
                    child: Text('La pagina solicitada no existe'),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

/// Wrapper que previene el cierre accidental de la app
/// y mantiene la sesión activa
class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> with WidgetsBindingObserver {
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La app se mantiene activa incluso cuando va al fondo
    // No hacemos nada especial aquí para permitir que Flutter
    // maneje el ciclo de vida normalmente
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Presiona de nuevo para minimizar (la app seguirá activa)',
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    // En lugar de cerrar la app, la minimizamos
    SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: const SplashScreen(),
    );
  }
}
