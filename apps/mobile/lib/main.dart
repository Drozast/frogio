// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/notification/notification_bloc.dart';
import 'core/presentation/pages/notifications_screen.dart';
import 'core/services/notification_manager.dart';
import 'core/theme/app_theme.dart';
import 'dashboard/presentation/pages/dashboard_screen.dart';
import 'di/injection_container_api.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/edit_profile_screen.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/citizen/presentation/pages/enhanced_my_reports_screen.dart';
import 'features/citizen/presentation/pages/enhanced_report_detail_screen.dart';
import 'features/panic/presentation/pages/panic_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios REST API
  await di.initApi();
  await NotificationManager().initialize();

  runApp(const MyApp());
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
        BlocProvider(
          create: (_) => NotificationBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'FROGIO',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        navigatorKey: NotificationManager().navigatorKey,
        // Envolver en PopScope para prevenir cierre accidental
        home: const _AppWrapper(),
        onGenerateRoute: (settings) {
          // Manejo dinamico de rutas con parametros
          switch (settings.name) {
            case '/notifications':
              return MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              );

            case '/reports':
              final userId = settings.arguments as String? ?? '';
              return MaterialPageRoute(
                builder: (_) => MyReportsScreen(userId: userId),
              );

            case '/profile':
              // Obtener el usuario actual del AuthBloc
              return MaterialPageRoute(
                builder: (context) => BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return EditProfileScreen(user: state.user);
                    } else {
                      // Redirigir al login si no esta autenticado
                      return const SplashScreen();
                    }
                  },
                ),
              );

            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
              );

            case '/report-detail':
              final args = settings.arguments as Map<String, dynamic>?;
              final reportId = args?['reportId'] as String? ?? '';
              final userRole = args?['userRole'] as String?;
              return MaterialPageRoute(
                builder: (_) => EnhancedReportDetailScreen(
                  reportId: reportId,
                  currentUserRole: userRole,
                ),
              );

            case '/panic':
              return MaterialPageRoute(
                builder: (context) => BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return PanicScreen(user: state.user);
                    } else {
                      return const SplashScreen();
                    }
                  },
                ),
              );

            default:
              // Ruta no encontrada
              return MaterialPageRoute(
                builder: (_) => Scaffold(
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
