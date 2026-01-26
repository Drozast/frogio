// lib/features/citizen/presentation/pages/citizen_home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/profile/profile_bloc.dart';
import '../../../auth/presentation/widgets/profile_avatar.dart';
import '../../../panic/presentation/bloc/panic_bloc.dart';
import '../../../panic/presentation/bloc/panic_event.dart';
import '../../../panic/presentation/bloc/panic_state.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import 'create_report_screen.dart';

/// Pantalla principal del Ciudadano - Diseno Moderno Minimalista
///
/// Caracteristicas UX:
/// - Boton SOS como elemento HERO central
/// - Accesos rapidos limpios y claros
/// - Estado de denuncias visible
/// - Mucho espacio en blanco para respirar
class CitizenHomeScreen extends StatefulWidget {
  final UserEntity user;

  const CitizenHomeScreen({super.key, required this.user});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen>
    with TickerProviderStateMixin {
  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;

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

  // Timer para actualización automática
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _getCurrentLocation();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Actualizar datos cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    // Recargar denuncias si el ReportBloc está disponible
    if (mounted) {
      final reportBloc = context.read<ReportBloc>();
      reportBloc.add(LoadReportsEvent(userId: widget.user.id));
    }
  }

  void _initAnimations() {
    // Animacion de pulso suave para el boton SOS
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animacion de respiracion para el anillo exterior
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
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

  void _onSOSPressStart() {
    if (_activeAlertId != null) return; // Ya hay alerta activa

    setState(() {
      _isSOSPressed = true;
      _sosProgress = 0.0;
    });

    HapticFeedback.mediumImpact();

    // Timer para incrementar progreso
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
    if (_sosProgress < 1.0 && mounted) {
      setState(() {
        _isSOSPressed = false;
        _sosProgress = 0.0;
      });
    }
  }

  void _triggerSOS() {
    HapticFeedback.heavyImpact();

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Esperando ubicacion...'),
            ],
          ),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
        ),
      );
      setState(() {
        _isSOSPressed = false;
        _sosProgress = 0.0;
      });
      return;
    }

    context.read<PanicBloc>().add(
          SendPanicAlertEvent(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            address: _currentAddress,
            message: 'Alerta de emergencia',
            contactPhone: widget.user.phoneNumber,
          ),
        );

    setState(() {
      _isSOSPressed = false;
    });
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
            const Text(
              '¿Cancelar la alerta?',
              style: AppTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo cancela si la emergencia fue un error',
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
                    ),
                    child: const Text('Cancelar'),
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
    _breatheController.dispose();
    _sosTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<PanicBloc>()),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
        BlocProvider(
          create: (_) => di.sl<ReportBloc>()
            ..add(LoadReportsEvent(userId: widget.user.id)),
        ),
      ],
      child: BlocListener<PanicBloc, PanicState>(
        listener: (context, panicState) {
          if (panicState is PanicAlertSent) {
            setState(() => _activeAlertId = panicState.alert.id);
          } else if (panicState is PanicAlertCancelled) {
            setState(() {
              _activeAlertId = null;
              _sosProgress = 0.0;
            });
            context.read<PanicBloc>().add(const ResetPanicStateEvent());
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
        child: Container(
          color: AppTheme.surface,
          child: SafeArea(
            top: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Contenido principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saludo minimalista
                        _buildGreeting(),

                        const SizedBox(height: 32),

                        // HERO: Boton SOS
                        _buildSOSHero(),

                        const SizedBox(height: 32),

                        // Acciones rapidas
                        _buildQuickActions(),

                        const SizedBox(height: 24),

                        // Resumen de denuncias
                        _buildReportsSummary(),

                        const SizedBox(height: 64),
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

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos dias';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.displayName,
                style: AppTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ProfileAvatar(
          user: widget.user,
          radius: 30,
          isEditable: false,
        ),
      ],
    );
  }

  Widget _buildSOSHero() {
    return BlocBuilder<PanicBloc, PanicState>(
      builder: (context, panicState) {
        final isLoading = panicState is PanicLoading;
        final isActive = panicState is PanicAlertSent || _activeAlertId != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Column(
            children: [
              // Titulo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.shield_rounded : Icons.emergency_rounded,
                    color: isActive ? AppTheme.success : AppTheme.emergency,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ALERTA ACTIVA' : 'EMERGENCIA',
                    style: AppTheme.titleMedium.copyWith(
                      color: isActive ? AppTheme.success : AppTheme.emergency,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Estado de ubicacion
              if (!isActive) _buildLocationStatus(),

              const SizedBox(height: 24),

              // Boton SOS Hero
              _buildSOSButton(isLoading, isActive),

              const SizedBox(height: 16),

              // Instrucciones
              Text(
                isActive
                    ? 'Ayuda en camino. Manten la calma.'
                    : _isSOSPressed
                        ? 'Manten presionado...'
                        : 'Manten presionado 3 segundos',
                style: AppTheme.bodySmall.copyWith(
                  color: isActive ? AppTheme.success : AppTheme.textSecondary,
                ),
              ),

              // Boton cancelar
              if (isActive && _activeAlertId != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _cancelAlert,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancelar alerta'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationStatus() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (_locationError != null) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.location_off;
      statusText = _locationError!;
    } else if (_isLoadingLocation) {
      statusColor = AppTheme.textTertiary;
      statusIcon = Icons.location_searching;
      statusText = 'Obteniendo ubicacion...';
    } else {
      statusColor = AppTheme.success;
      statusIcon = Icons.location_on;
      statusText = _currentAddress ?? 'Ubicacion lista';
    }

    return GestureDetector(
      onTap: _locationError != null ? _getCurrentLocation : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                statusText,
                style: AppTheme.labelSmall.copyWith(color: statusColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.refresh, size: 14, color: statusColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(bool isLoading, bool isActive) {
    const size = 180.0;

    return GestureDetector(
      onLongPressStart: isActive || isLoading ? null : (_) => _onSOSPressStart(),
      onLongPressEnd: isActive || isLoading ? null : (_) => _onSOSPressEnd(),
      onLongPressCancel: isActive || isLoading ? null : _onSOSPressEnd,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? 1.0 : (_isSOSPressed ? 0.95 : _pulseAnimation.value),
            child: child,
          );
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo exterior animado (respiracion)
              if (!isActive)
                AnimatedBuilder(
                  animation: _breatheAnimation,
                  builder: (context, _) {
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.emergency.withValues(
                            alpha: 0.2 + (_breatheAnimation.value * 0.1),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

              // Anillo de progreso
              if (_isSOSPressed && !isActive)
                SizedBox(
                  width: size - 20,
                  height: size - 20,
                  child: CircularProgressIndicator(
                    value: _sosProgress,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.emergencyLight,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.emergency),
                  ),
                ),

              // Boton principal
              Container(
                width: size - 40,
                height: size - 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.success : AppTheme.emergency,
                  boxShadow: AppTheme.shadowEmergency(isActive),
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
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
                            size: 48,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isActive ? 'ACTIVA' : 'SOS',
                            style: AppTheme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones rapidas',
          style: AppTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Nueva denuncia - CTA principal
            Expanded(
              flex: 2,
              child: _buildActionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Nueva denuncia',
                subtitle: 'Reportar un problema',
                color: AppTheme.primary,
                isPrimary: true,
                onTap: () {
                  if (!widget.user.isProfileComplete) {
                    _showIncompleteProfileDialog();
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateReportScreen(userId: widget.user.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Mis denuncias
            Expanded(
              child: _buildActionCard(
                icon: Icons.list_alt_rounded,
                title: 'Mis denuncias',
                color: AppTheme.info,
                onTap: () {
                  // Navegar a tab de denuncias (manejado por padre)
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(isPrimary ? 16.0 : 12.0),
        decoration: isPrimary
            ? BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : AppTheme.cardBorderedDecoration,
        child: isPrimary
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.titleSmall.copyWith(color: Colors.white),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(icon, color: color, size: 24),
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

  Widget _buildReportsSummary() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        int totalReports = 0;
        int pendingReports = 0;
        int resolvedReports = 0;

        if (state is ReportsLoaded) {
          totalReports = state.reports.length;
          pendingReports = state.reports
              .where((r) => r.status == ReportStatus.submitted || r.status == ReportStatus.inProgress || r.status == ReportStatus.reviewing)
              .length;
          resolvedReports = state.reports
              .where((r) => r.status == ReportStatus.resolved)
              .length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardBorderedDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis denuncias',
                    style: AppTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navegar a lista completa
                    },
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
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.divider,
                  ),
                  Expanded(
                    child: _buildStatItem(
                      value: pendingReports.toString(),
                      label: 'En proceso',
                      color: AppTheme.warning,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.divider,
                  ),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.labelSmall,
        ),
      ],
    );
  }

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}
