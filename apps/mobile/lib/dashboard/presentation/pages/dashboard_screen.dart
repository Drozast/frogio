import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/services/session_timeout_service.dart';
import '../../../di/injection_container_api.dart' as di;
import '../../../features/auth/domain/entities/user_entity.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/auth/presentation/bloc/profile/profile_bloc.dart';
import '../../../features/auth/presentation/pages/complete_profile_screen.dart';
import '../../../features/auth/presentation/pages/login_screen.dart';
import '../../../features/auth/presentation/widgets/profile_avatar.dart';
import '../../../features/citizen/presentation/pages/create_report_screen.dart';
import '../../../features/citizen/presentation/pages/my_reports_screen.dart';
import '../../../features/citizen/presentation/pages/citizen_home_screen.dart';
import '../../../features/admin/presentation/bloc/statistics/statistics_bloc.dart';
import '../../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../../features/inspector/presentation/pages/inspector_home_screen_v2.dart';
import '../../../features/inspector/presentation/pages/citations_main_screen.dart';
import '../../../features/inspector/presentation/bloc/citation_bloc.dart';
import '../../../features/panic/presentation/bloc/panic_bloc.dart';
import '../../../features/panic/presentation/bloc/panic_event.dart';
import '../../../features/panic/presentation/bloc/panic_state.dart';
import '../../../features/panic/presentation/widgets/panic_button.dart';
import '../../../core/blocs/notification/notification_bloc.dart';
import '../../../core/presentation/pages/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  // Colores del tema FROGIO
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF7CB342);

  // Estado para el botón de pánico
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _activeAlertId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();

    // Inicializar servicio de timeout de sesión
    final sessionService = di.sl<SessionTimeoutService>();
    sessionService.onSessionTimeout = () {
      if (mounted) {
        context.read<AuthBloc>().add(SignOutEvent());
      }
    };
    sessionService.startTimer();

    // Obtener ubicación para el botón de pánico
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicación denegado';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Habilita los permisos de ubicación en configuración';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.street ?? ''}, ${place.locality ?? ''}';
        }
      } catch (_) {}

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación';
        _isLoadingLocation = false;
      });
    }
  }

  void _sendPanicAlert(BuildContext context, UserEntity user) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Esperando ubicación...'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    context.read<PanicBloc>().add(
          SendPanicAlertEvent(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            address: _currentAddress,
            message: 'Alerta de emergencia',
            contactPhone: user.phoneNumber,
          ),
        );
  }

  void _cancelAlert(BuildContext context) {
    if (_activeAlertId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange.shade600),
            const SizedBox(height: 16),
            const Text(
              '¿Cancelar la alerta?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Solo cancela si la emergencia fue un error',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Mantener activa'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<PanicBloc>().add(
                            CancelPanicAlertEvent(alertId: _activeAlertId!),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar alerta', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider(create: (_) => di.sl<PanicBloc>()),
        // NotificationBloc global provisto en MyApp
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: BlocListener<PanicBloc, PanicState>(
          listener: (context, panicState) {
            if (panicState is PanicAlertSent) {
              setState(() => _activeAlertId = panicState.alert.id);
            } else if (panicState is PanicAlertCancelled) {
              setState(() => _activeAlertId = null);
              context.read<PanicBloc>().add(const ResetPanicStateEvent());
            } else if (panicState is PanicError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(panicState.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return _buildDashboard(state.user);
              } else if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cerrando sesión...'),
                      ],
                    ),
                  ),
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(UserEntity user) {
    // Solo mostrar header en Inicio (index 0)
    final showHeader = _currentIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          di.sl<SessionTimeoutService>().updateLastActivityTime();
        },
        child: Stack(
          children: [
            // Fondo con patrón de nenúfares
            _buildBackgroundPattern(),

            // Contenido principal
            Column(
              children: [
                // Header personalizado estilo FROGIO - solo en Inicio
                if (showHeader) _buildCustomHeader(user),

                // SafeArea para páginas sin header
                if (!showHeader) SafeArea(child: Container()),

                // Contenido de la página actual
                Expanded(
                  child: _getPage(_currentIndex, user),
                ),
              ],
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar curva con botón SOS
      bottomNavigationBar: _buildCurvedBottomNavBar(user),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.04,
        child: CustomPaint(
          painter: _LilyPadPatternPainter(color: _primaryGreen),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(UserEntity user) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Imagen del sapo/rana decorativa
            Positioned(
              top: -10,
              right: -20,
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  'assets/images/muni-vertical.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),

            // Hojas decorativas
            Positioned(
              top: 0,
              left: -30,
              child: Transform.rotate(
                angle: 0.3,
                child: _buildLeaf(Colors.white.withValues(alpha: 0.1), 100),
              ),
            ),
            Positioned(
              top: 60,
              left: -15,
              child: Transform.rotate(
                angle: -0.2,
                child: _buildLeaf(Colors.white.withValues(alpha: 0.08), 70),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 100,
              child: Transform.rotate(
                angle: -0.5,
                child: _buildLeaf(Colors.white.withValues(alpha: 0.06), 50),
              ),
            ),

            // Contenido del header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior con título y botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FROGIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Row(
                        children: [
                          // Boton de notificaciones
                          BlocBuilder<NotificationBloc, NotificationState>(
                            builder: (context, state) {
                              int unreadCount = 0;
                              if (state is NotificationLoaded) {
                                unreadCount = state.unreadCount;
                              }
                              return GestureDetector(
                                onTap: () => _navigateToNotifications(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          // Boton cerrar sesion
                          GestureDetector(
                            onTap: _showLogoutConfirmationDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.exit_to_app,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta de usuario - clickeable para ir al perfil (navbar)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Ir a la pestaña de perfil
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar con imagen de perfil
                          ProfileAvatar(
                            user: user,
                            radius: 30,
                            isEditable: false,
                          ),
                          const SizedBox(width: 16),
                          // Info del usuario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '¡Hola, ${user.displayName}!',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rol: ${_getRoleDisplayName(user.role)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!user.isProfileComplete) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.orange.shade400,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      'Completa tu perfil',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaf(Color color, double size) {
    return Container(
      width: size,
      height: size * 1.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size),
          topRight: Radius.circular(size * 0.2),
          bottomLeft: Radius.circular(size * 0.2),
          bottomRight: Radius.circular(size),
        ),
      ),
    );
  }

  Widget _buildCurvedBottomNavBar(UserEntity user) {
    return Container(
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getNavItemsForRole(user.role),
          ),
        ),
      ),
    );
  }

  List<Widget> _getNavItemsForRole(String role) {
    switch (role) {
      case 'admin':
        return [
          _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
          _buildNavItem(Icons.people_outline, 'Usuarios', 1),
          _buildNavItem(Icons.analytics_outlined, 'Reportes', 2),
          _buildNavItem(Icons.person_outline, 'Perfil', 3),
        ];
      case 'inspector':
        return [
          _buildNavItem(Icons.home_rounded, 'Inicio', 0),
          _buildNavItem(Icons.assignment_outlined, 'Citaciones', 1),
          _buildNavItem(Icons.person_outline, 'Perfil', 2),
        ];
      case 'citizen':
      default:
        return [
          _buildNavItem(Icons.home_rounded, 'Inicio', 0),
          _buildNavItem(Icons.assignment_outlined, 'Denuncias', 1),
          _buildNavItem(Icons.person_outline, 'Perfil', 2),
        ];
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        di.sl<SessionTimeoutService>().updateLastActivityTime();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySOSSection(UserEntity user) {
    return BlocBuilder<PanicBloc, PanicState>(
      builder: (context, panicState) {
        final isLoading = panicState is PanicLoading;
        final isActive = panicState is PanicAlertSent || _activeAlertId != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? Colors.green.shade300 : Colors.red.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Título de emergencia
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.shield_rounded : Icons.emergency_rounded,
                    color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isActive ? 'ALERTA ACTIVA' : 'BOTÓN DE EMERGENCIA',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Estado de ubicación
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _locationError != null
                        ? Colors.orange.shade50
                        : _isLoadingLocation
                            ? Colors.grey.shade100
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _locationError != null
                            ? Icons.location_off
                            : _isLoadingLocation
                                ? Icons.location_searching
                                : Icons.location_on,
                        size: 16,
                        color: _locationError != null
                            ? Colors.orange.shade700
                            : _isLoadingLocation
                                ? Colors.grey.shade600
                                : Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLoadingLocation
                            ? 'Obteniendo ubicación...'
                            : _locationError ?? (_currentAddress ?? 'Ubicación lista'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _locationError != null
                              ? Colors.orange.shade700
                              : _isLoadingLocation
                                  ? Colors.grey.shade600
                                  : Colors.green.shade700,
                        ),
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _getCurrentLocation,
                          child: Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Botón de pánico
              PanicButton(
                onPanicTriggered: () => _sendPanicAlert(context, user),
                isLoading: isLoading,
                isActive: isActive,
              ),
              // Botón cancelar alerta
              if (isActive && _activeAlertId != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => _cancelAlert(context),
                  icon: Icon(Icons.close_rounded, color: Colors.orange.shade700),
                  label: Text(
                    'Cancelar alerta',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.orange.shade300, width: 2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _getPage(int index, UserEntity user) {
    switch (user.role) {
      case 'admin':
        switch (index) {
          case 0:
            return BlocProvider(
              create: (_) => di.sl<StatisticsBloc>(),
              child: AdminDashboardScreen(user: user),
            );
          case 1:
            return Center(
              child: Text(
                'Gestion de Usuarios - En desarrollo',
                style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              ),
            );
          case 2:
            return Center(
              child: Text(
                'Reportes y Estadisticas - En desarrollo',
                style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
              ),
            );
          case 3:
            return _buildProfilePage(user);
          default:
            return BlocProvider(
              create: (_) => di.sl<StatisticsBloc>(),
              child: AdminDashboardScreen(user: user),
            );
        }
      case 'citizen':
        switch (index) {
          case 0:
            return CitizenHomeScreen(user: user);
          case 1:
            return MyReportsScreen(userId: user.id);
          case 2:
            return _buildProfilePage(user);
          default:
            return CitizenHomeScreen(user: user);
        }
      case 'inspector':
        switch (index) {
          case 0:
            return InspectorHomeScreenV2(user: user);
          case 1:
            return BlocProvider(
              create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent()),
              child: CitationsMainScreen(user: user),
            );
          case 2:
            return _buildProfilePage(user);
          default:
            return InspectorHomeScreenV2(user: user);
        }
      default:
        if (index == 0) {
          return _buildHomeDashboard(user);
        } else if (index == 2) {
          return _buildProfilePage(user);
        } else {
          return Center(
            child: Text(
              'Pagina en desarrollo: $index',
              style: const TextStyle(fontSize: 20),
            ),
          );
        }
    }
  }

  Widget _buildHomeDashboard(UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón SOS integrado directamente
          _buildEmergencySOSSection(user),

          const SizedBox(height: 24),

          // Título de sección
          const Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Grid de accesos rápidos estilo FROGIO
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: _getQuickAccessItemsForRole(user),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tarjeta de perfil
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _lightGreen, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                ProfileAvatar(
                  user: user,
                  radius: 50,
                  isEditable: false,
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompleteProfileScreen(user: user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Estado del perfil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: user.isProfileComplete
                  ? _lightGreen.withValues(alpha: 0.1)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: user.isProfileComplete ? _lightGreen : Colors.orange.shade300,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: user.isProfileComplete
                        ? _lightGreen.withValues(alpha: 0.2)
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    user.isProfileComplete ? Icons.check_circle : Icons.warning,
                    color: user.isProfileComplete ? _primaryGreen : Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.isProfileComplete ? 'Perfil Completo' : 'Perfil Incompleto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: user.isProfileComplete ? _primaryGreen : Colors.orange.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.isProfileComplete
                            ? 'Puedes acceder a todas las funciones'
                            : 'Completa tu perfil para crear denuncias',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Información personal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileRow(Icons.phone, 'Teléfono', user.phoneNumber ?? 'No especificado'),
                _buildProfileRow(Icons.location_on, 'Dirección', user.address ?? 'No especificada'),
                _buildProfileRow(Icons.badge, 'Rol', _getRoleDisplayName(user.role)),
                _buildProfileRow(
                  Icons.calendar_today,
                  'Miembro desde',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getQuickAccessItemsForRole(UserEntity user) {
    final List<Widget> items = [];

    switch (user.role) {
      case 'citizen':
        items.addAll([
          _buildQuickAccessCard(
            icon: Icons.add_circle_outline,
            title: 'Nueva Denuncia',
            onTap: () {
              if (!user.isProfileComplete) {
                _showCompleteProfileDialog();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(userId: user.id),
                ),
              );
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.list_alt,
            title: 'Mis Denuncias',
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          _buildQuickAccessCard(
            icon: Icons.person,
            title: 'Mi Perfil',
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
        ]);
        break;
      default:
        items.add(_buildQuickAccessCard(
          icon: Icons.person,
          title: 'Perfil',
          onTap: () {
            setState(() {
              _currentIndex = 2;
            });
          },
        ));
    }

    return items;
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _lightGreen, width: 2),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: _primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'citizen':
        return 'Ciudadano';
      case 'inspector':
        return 'Inspector';
      case 'admin':
        return 'Administrador';
      default:
        return role;
    }
  }

  void _showCompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Perfil Incompleto'),
        content: const Text(
          'Para crear denuncias necesitas completar tu perfil con nombre, teléfono y dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final currentState = context.read<AuthBloc>().state;
              if (currentState is Authenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompleteProfileScreen(user: currentState.user),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Completar Perfil'),
          ),
        ],
      ),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<NotificationBloc>(),
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

// Patrón de nenúfares para el fondo
class _LilyPadPatternPainter extends CustomPainter {
  final Color color;

  _LilyPadPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 120.0;
    const leafSize = 25.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final offsetX = (y ~/ spacing).isEven ? 0.0 : spacing / 2;
        _drawLilyPad(canvas, paint, Offset(x + offsetX, y), leafSize);
      }
    }
  }

  void _drawLilyPad(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.quadraticBezierTo(
      center.dx + size / 2,
      center.dy - size / 4,
      center.dx + size / 2,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx + size / 2,
      center.dy + size / 4,
      center.dx,
      center.dy + size / 2,
    );
    path.quadraticBezierTo(
      center.dx - size / 2,
      center.dy + size / 4,
      center.dx - size / 2,
      center.dy,
    );
    path.quadraticBezierTo(
      center.dx - size / 2,
      center.dy - size / 4,
      center.dx,
      center.dy - size / 2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
