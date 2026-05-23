// lib/features/citizen/presentation/pages/citizen_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/profile/profile_bloc.dart';
import '../../../panic/presentation/bloc/panic_bloc.dart';
import '../../../panic/presentation/bloc/panic_event.dart';
import '../../../panic/presentation/bloc/panic_state.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';
import 'create_report_screen.dart';
import 'my_reports_screen.dart';

/// Pantalla principal del Ciudadano — Tema claro profesional
///
/// Caracteristicas UX:
/// - Boton SOS como elemento HERO central con progreso visible
/// - Acciones rapidas en cards blancas con sombra suave
/// - Fondo blanco/crema claro, verde como color institucional
/// - Accesibilidad: contraste WCAG AA, tap targets minimos 44px
class CitizenHomeScreen extends StatefulWidget {
  final UserEntity user;

  const CitizenHomeScreen({super.key, required this.user});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen>
    with TickerProviderStateMixin {
  // Animacion de pulso suave para el boton en reposo
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animacion de activacion (scale presionado)
  late AnimationController _activationController;

  // Estado de ubicacion para SOS
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _activeAlertId;

  // Estado del boton SOS
  bool _isSOSPressed = false;
  double _sosProgress = 0.0;
  Timer? _sosTimer;

  // Timer para actualizacion automatica
  Timer? _refreshTimer;

  // Referencia al PanicBloc para usar fuera del build context
  PanicBloc? _panicBloc;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveAlert();
      _startAutoRefresh();
    });
  }

  void _loadActiveAlert() {
    _panicBloc ??= di.sl<PanicBloc>();
    _panicBloc!.add(const LoadActiveAlertEvent());
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (mounted) {
      try {
        final reportBloc = context.read<ReportBloc>();
        reportBloc.add(LoadReportsEvent(userId: widget.user.id));
      } catch (e) {
        debugPrint('Warning: Error accessing ReportBloc: $e');
      }
      _loadActiveAlert();
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Pulso más pronunciado para botón rojo de emergencia
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _activationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
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
            _locationError = 'Permiso de ubicacion denegado';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Habilita ubicacion en configuracion';
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

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _isLoadingLocation = false;
        });
        // Silently update the user's stored location in the backend
        _updateUserLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error al obtener ubicacion';
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Silently updates the user's latitude/longitude in their profile.
  /// Failures are intentionally swallowed — this is best-effort.
  Future<void> _updateUserLocation(double latitude, double longitude) async {
    try {
      final repo = di.sl<AuthRepository>();
      await repo.updateUserProfile(
        userId: widget.user.id,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      // Non-critical — do not surface errors to the user
    }
  }

  void _onSOSPressStart() {
    if (_activeAlertId != null) return;

    setState(() {
      _isSOSPressed = true;
      _sosProgress = 0.0;
    });

    HapticFeedback.mediumImpact();
    _activationController.forward();

    _sosTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isSOSPressed) {
        timer.cancel();
        return;
      }

      setState(() {
        _sosProgress += 0.01; // ~3 segundos para completar
      });

      if (_sosProgress >= 1.0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _onSOSPressEnd() {
    _sosTimer?.cancel();
    _activationController.reverse();
    if (_sosProgress < 1.0 && mounted) {
      setState(() {
        _isSOSPressed = false;
        _sosProgress = 0.0;
      });
    }
  }

  void _triggerSOS() {
    HapticFeedback.heavyImpact();

    debugPrint('SOS triggered! Position: $_currentPosition');

    final latitude = _currentPosition?.latitude ?? -37.1765;
    final longitude = _currentPosition?.longitude ?? -72.9383;
    final address = _currentAddress ?? 'Santa Juana, Bio Bio';

    _panicBloc?.add(
      SendPanicAlertEvent(
        latitude: latitude,
        longitude: longitude,
        address: address,
        message: 'Alerta de emergencia',
        contactPhone: widget.user.phoneNumber,
      ),
    );

    setState(() {
      _isSOSPressed = false;
      _sosProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('Enviando alerta de emergencia...'),
          ],
        ),
        backgroundColor: AppTheme.emergency,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelAlert() {
    if (_activeAlertId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.warningLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 32,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancelar la alerta?',
              style: AppTheme.headlineSmall.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo cancela si la emergencia fue un error o ya fue resuelta.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Mantener'),
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
                      backgroundColor: AppTheme.emergency,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancelar alerta'),
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
    _pulseController.dispose();
    _activationController.dispose();
    _sosTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _panicBloc ??= di.sl<PanicBloc>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _panicBloc!),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider(
          create: (_) => di.sl<ReportBloc>()
            ..add(LoadReportsEvent(userId: widget.user.id)),
        ),
      ],
      child: BlocListener<PanicBloc, PanicState>(
        listener: (context, panicState) {
          debugPrint('PanicState changed: ${panicState.runtimeType}');
          if (panicState is PanicAlertActive) {
            setState(() => _activeAlertId = panicState.alert.id);
          } else if (panicState is PanicAlertSent) {
            setState(() => _activeAlertId = panicState.alert.id);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Alerta enviada! Ayuda en camino.'),
                  ],
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
            final reportBloc = context.read<ReportBloc>();
            final userId = widget.user.id;
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                reportBloc.add(LoadReportsEvent(userId: userId));
              }
            });
          } else if (panicState is PanicAlertCancelled) {
            setState(() {
              _activeAlertId = null;
              _sosProgress = 0.0;
            });
            context.read<PanicBloc>().add(const ResetPanicStateEvent());
          } else if (panicState is PanicInitial && _activeAlertId != null) {
            setState(() {
              _activeAlertId = null;
              _sosProgress = 0.0;
              _isSOSPressed = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(child: Text('Tu alerta ha sido atendida y resuelta.')),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          } else if (panicState is PanicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(panicState.message),
                backgroundColor: AppTheme.emergency,
              ),
            );
            setState(() {
              _sosProgress = 0.0;
              _isSOSPressed = false;
            });
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header sticky con saludo
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // HERO: Boton SOS
                        FadeSlideTransition(
                          child: _buildSOSSection(),
                        ),

                        const SizedBox(height: 28),

                        // Acciones rapidas
                        FadeSlideTransition(
                          delay: const Duration(milliseconds: 150),
                          child: _buildQuickActions(),
                        ),

                        const SizedBox(height: 24),

                        // Resumen de denuncias
                        FadeSlideTransition(
                          delay: const Duration(milliseconds: 300),
                          child: _buildReportsSummary(),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final firstName = widget.user.displayName.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos dias'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        children: [
          // Avatar con inicial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Center(
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                ),
                Text(
                  firstName,
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),

          // Indicador de ubicacion
          _buildLocationChip(),
        ],
      ),
    );
  }

  Widget _buildLocationChip() {
    if (_isLoadingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Ubicando...',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.primary),
            ),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return GestureDetector(
        onTap: _getCurrentLocation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.warningLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 12, color: AppTheme.warning),
              const SizedBox(width: 4),
              Text(
                'Sin GPS',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.warning),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.refresh, size: 11, color: AppTheme.warning),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 12, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            'GPS listo',
            style: AppTheme.labelSmall.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  // ─── Seccion SOS ──────────────────────────────────────────────────────────

  Widget _buildSOSSection() {
    return BlocBuilder<PanicBloc, PanicState>(
      builder: (context, panicState) {
        final isLoading = panicState is PanicLoading;
        final isActive = panicState is PanicAlertSent || _activeAlertId != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.emergencyLight
                : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(
              color: isActive
                  ? AppTheme.emergency.withValues(alpha: 0.4)
                  : AppTheme.emergency.withValues(alpha: 0.15),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emergency.withValues(
                    alpha: isActive ? 0.18 : 0.08),
                blurRadius: isActive ? 24 : 16,
                spreadRadius: isActive ? 3 : 1,
              ),
              ...AppTheme.shadowSmall,
            ],
          ),
          child: Column(
            children: [
              // Etiqueta de estado
              _buildSOSStatusBadge(isActive),

              const SizedBox(height: 28),

              // Boton SOS principal
              _buildSOSButton(isLoading, isActive),

              const SizedBox(height: 20),

              // Instrucciones contextuales
              _buildSOSInstructions(isActive),

              // Boton cancelar si hay alerta activa
              if (isActive && _activeAlertId != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _cancelAlert,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancelar alerta'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.emergency,
                    textStyle: AppTheme.labelMedium,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSOSStatusBadge(bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.emergency.withValues(alpha: 0.12)
                : AppTheme.emergency.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: isActive
                  ? AppTheme.emergency.withValues(alpha: 0.4)
                  : AppTheme.emergency.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.shield_rounded : Icons.emergency_rounded,
                size: 14,
                color: AppTheme.emergency,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'ALERTA ACTIVA' : 'BOTON DE PANICO',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.emergency,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSOSButton(bool isLoading, bool isActive) {
    const double size = 200.0;
    const double innerSize = 160.0;

    // Botón siempre rojo (emergencia) cuando no está activo — verde solo cuando alerta activa
    final buttonColor = isActive
        ? AppTheme.success
        : AppTheme.emergency;

    return GestureDetector(
      onLongPressStart: isActive || isLoading ? null : (_) => _onSOSPressStart(),
      onLongPressEnd: isActive || isLoading ? null : (_) => _onSOSPressEnd(),
      onLongPressCancel: isActive || isLoading ? null : _onSOSPressEnd,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive
                ? 1.0
                : _isSOSPressed
                    ? 0.96
                    : _pulseAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo de progreso circular — rojo oscuro cuando inactivo, verde cuando activo
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: _isSOSPressed ? _sosProgress : (isActive ? 1.0 : 0.0),
                  strokeWidth: 6,
                  backgroundColor: isActive
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.emergencyDark.withValues(alpha: 0.20),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? AppTheme.success : AppTheme.emergencyDark,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Circulo de fondo con sombra
              Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: buttonColor,
                  boxShadow: [
                    // Glow primario — intensidad aumenta al presionar
                    BoxShadow(
                      color: buttonColor.withValues(
                          alpha: _isSOSPressed ? 0.55 : 0.40),
                      blurRadius: _isSOSPressed ? 32 : 22,
                      spreadRadius: _isSOSPressed ? 8 : 4,
                    ),
                    // Glow exterior difuso
                    BoxShadow(
                      color: buttonColor.withValues(
                          alpha: _isSOSPressed ? 0.25 : 0.18),
                      blurRadius: _isSOSPressed ? 56 : 40,
                      spreadRadius: _isSOSPressed ? 12 : 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive
                                ? Icons.shield_rounded
                                : Icons.emergency_share_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isActive ? 'ACTIVA' : 'SOS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
              ),

              // Contador de progreso encima del boton (visible al presionar)
              if (_isSOSPressed && !isActive)
                Positioned(
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emergency,
                      borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                    ),
                    child: Text(
                      '${(3 - (_sosProgress * 3)).ceil()}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSInstructions(bool isActive) {
    if (isActive) {
      return Column(
        children: [
          Text(
            'Ayuda en camino. Manten la calma.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.emergency,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Las autoridades han sido notificadas de tu ubicacion.',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_isSOSPressed) {
      return Column(
        children: [
          Text(
            'Manten presionado...',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.emergency,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _sosProgress,
              minHeight: 4,
              backgroundColor: AppTheme.emergencyLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.emergency),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          'Manten presionado 3 segundos',
          style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Envia tu ubicacion y alerta a las autoridades',
          style: AppTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Acciones rapidas ─────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rapidas',
          style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Nueva denuncia — CTA principal (mas ancho)
            Expanded(
              flex: 3,
              child: _buildActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Nueva denuncia',
                subtitle: 'Reportar un problema',
                color: AppTheme.primary,
                isPrimary: true,
                onTap: () async {
                  // Use fresh user from AuthBloc (not stale widget.user)
                  final authState = context.read<AuthBloc>().state;
                  final currentUser = authState is Authenticated ? authState.user : widget.user;
                  if (!currentUser.isProfileComplete) {
                    _showIncompleteProfileDialog();
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateReportScreen(userId: widget.user.id),
                    ),
                  );
                  // Refresh reports when returning from create screen
                  if (mounted) {
                    context.read<ReportBloc>().add(LoadReportsEvent(userId: widget.user.id));
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            // Mis denuncias
            Expanded(
              flex: 2,
              child: _buildActionCard(
                icon: Icons.list_alt_rounded,
                title: 'Mis denuncias',
                color: AppTheme.info,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyReportsScreen(
                        userId: widget.user.id,
                        user: widget.user,
                      ),
                    ),
                  );
                  if (mounted) {
                    context.read<ReportBloc>().add(LoadReportsEvent(userId: widget.user.id));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(isPrimary ? 16.0 : 14.0),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: isPrimary
            ? Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.titleSmall.copyWith(color: color),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppTheme.labelMedium.copyWith(color: AppTheme.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Resumen de denuncias ─────────────────────────────────────────────────

  Widget _buildReportsSummary() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        int totalReports = 0;
        int pendingReports = 0;
        int resolvedReports = 0;

        if (state is ReportsLoaded) {
          totalReports = state.reports.length;
          pendingReports = state.reports
              .where((r) =>
                  r.status == ReportStatus.pendiente ||
                  r.status == ReportStatus.enProceso)
              .length;
          resolvedReports = state.reports
              .where((r) => r.status == ReportStatus.resuelto)
              .length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis denuncias',
                    style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary),
                  ),
                  if (state is ReportLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyReportsScreen(
                              userId: widget.user.id,
                              user: widget.user,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Ver todas'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      value: totalReports.toString(),
                      label: 'Total',
                      color: AppTheme.primary,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppTheme.divider),
                  Expanded(
                    child: _buildStatItem(
                      value: pendingReports.toString(),
                      label: 'En proceso',
                      color: AppTheme.warning,
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppTheme.divider),
                  Expanded(
                    child: _buildStatItem(
                      value: resolvedReports.toString(),
                      label: 'Resueltas',
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ─── Dialogo perfil incompleto ─────────────────────────────────────────────

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppTheme.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Perfil incompleto'),
            ),
          ],
        ),
        content: const Text(
          'Para crear denuncias necesitas completar tu perfil con nombre, telefono y direccion.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegar a completar perfil
            },
            child: const Text('Completar perfil'),
          ),
        ],
      ),
    );
  }
}
