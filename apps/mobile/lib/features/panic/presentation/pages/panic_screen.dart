import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';
import '../bloc/panic_state.dart';
import '../widgets/panic_button.dart';

class PanicScreen extends StatefulWidget {
  final UserEntity user;

  const PanicScreen({super.key, required this.user});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> with TickerProviderStateMixin {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _activeAlertId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _emergencyRed = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  void _sendPanicAlert(BuildContext context) {
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
            contactPhone: widget.user.phoneNumber,
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
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: Color(0x33FFAA00), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.warning),
            const SizedBox(height: 16),
            const Text(
              '¿Cancelar la alerta?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo cancela si la emergencia fue un error',
              style: TextStyle(color: Color(0xFF778899)),
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
                      backgroundColor: _emergencyRed,
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PanicBloc>(),
      child: BlocConsumer<PanicBloc, PanicState>(
        listener: (context, state) {
          if (state is PanicAlertSent) {
            setState(() => _activeAlertId = state.alert.id);
          } else if (state is PanicAlertCancelled) {
            setState(() => _activeAlertId = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Alerta cancelada correctamente'),
                  ],
                ),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is PanicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PanicLoading;
          final isActive = state is PanicAlertSent || _activeAlertId != null;

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Stack(
              children: [
                // Fondo con patrón decorativo neon
                _buildBackgroundPattern(isActive),

                // Contenido principal
                Column(
                  children: [
                    // Header estilo FROGIO con escudo de la muni
                    _buildHeader(context, isActive),

                    // Contenido scrollable
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título de sección
                              Text(
                                'Información de Emergencia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppTheme.success : AppTheme.emergency,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Grid de información (estilo FROGIO)
                              _buildInfoGrid(isActive),

                              const SizedBox(height: 24),

                              // Título de sección
                              Text(
                                'Botón de Pánico',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppTheme.success : AppTheme.emergency,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Botón de pánico centrado
                              Center(
                                child: PanicButton(
                                  onPanicTriggered: () => _sendPanicAlert(context),
                                  isLoading: isLoading,
                                  isActive: isActive,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Botón cancelar
                              if (isActive && _activeAlertId != null)
                                Center(child: _buildCancelButton(context)),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundPattern(bool isActive) {
    final accent = isActive ? AppTheme.success : AppTheme.emergency;
    return Positioned.fill(
      child: Stack(
        children: [
          // Radial glow top
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          // Leaf pattern with neon tint
          Opacity(
            opacity: 0.04,
            child: CustomPaint(
              painter: _LeafPatternPainter(color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isActive) {
    final accent = isActive ? AppTheme.success : AppTheme.emergency;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Escudo de la municipalidad (como el sapo en el dashboard)
            Positioned(
              top: -20,
              right: -30,
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/muni-vertical.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),

            // Hojas decorativas
            Positioned(
              top: 10,
              left: -20,
              child: Transform.rotate(
                angle: 0.3,
                child: _buildLeaf(Colors.white.withValues(alpha: 0.1), 80),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 80,
              child: Transform.rotate(
                angle: -0.5,
                child: _buildLeaf(Colors.white.withValues(alpha: 0.08), 60),
              ),
            ),

            // Contenido del header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior con título y botón volver
                  Row(
                    children: [
                      // Botón volver
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: accent, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Título
                      Text(
                        isActive ? 'ALERTA ACTIVA' : 'EMERGENCIA',
                        style: TextStyle(
                          color: accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta de usuario neon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12)],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: accent.withValues(alpha: 0.4)),
                          ),
                          child: Center(
                            child: Text(
                              widget.user.displayName.isNotEmpty
                                  ? widget.user.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isActive ? '¡Ayuda en camino!' : '¡Necesito ayuda!',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.user.phoneNumber != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.user.phoneNumber!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
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

  Widget _buildInfoGrid(bool isActive) {
    final accent = isActive ? AppTheme.success : AppTheme.emergency;
    final borderColor = accent.withValues(alpha: 0.4);
    final iconBgColor = accent.withValues(alpha: 0.10);
    final iconColor = accent;

    return Column(
      children: [
        // Fila 1: Ubicación y Estado
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: _locationError != null ? Icons.location_off : Icons.location_on,
                title: 'Tu Ubicación',
                subtitle: _isLoadingLocation
                    ? 'Obteniendo...'
                    : _locationError ?? _currentAddress ?? 'Ubicación detectada',
                borderColor: borderColor,
                iconBgColor: iconBgColor,
                iconColor: _locationError != null ? _emergencyRed : iconColor,
                onRefresh: !_isLoadingLocation ? _getCurrentLocation : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: isActive ? Icons.check_circle : Icons.warning_rounded,
                title: 'Estado',
                subtitle: isActive ? 'Alerta enviada' : 'Listo para activar',
                borderColor: borderColor,
                iconBgColor: iconBgColor,
                iconColor: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fila 2: Coordenadas
        if (_currentPosition != null)
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.my_location,
                  title: 'Latitud',
                  subtitle: _currentPosition!.latitude.toStringAsFixed(5),
                  borderColor: borderColor,
                  iconBgColor: iconBgColor,
                  iconColor: iconColor,
                  isMonospace: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.explore,
                  title: 'Longitud',
                  subtitle: _currentPosition!.longitude.toStringAsFixed(5),
                  borderColor: borderColor,
                  iconBgColor: iconBgColor,
                  iconColor: iconColor,
                  isMonospace: true,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color borderColor,
    required Color iconBgColor,
    required Color iconColor,
    VoidCallback? onRefresh,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: borderColor.withValues(alpha: 0.12), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (onRefresh != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: Icon(Icons.refresh, color: iconColor.withValues(alpha: 0.6), size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF778899), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: AppTheme.warning.withValues(alpha: 0.12), blurRadius: 12)],
      ),
      child: TextButton.icon(
        onPressed: () => _cancelAlert(context),
        icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.warning),
        label: const Text(
          'Cancelar alerta',
          style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
      ),
    );
  }
}

// Patrón de hojas/nenúfares para el fondo (estilo FROGIO)
class _LeafPatternPainter extends CustomPainter {
  final Color color;

  _LeafPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const spacing = 100.0;
    const leafSize = 30.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Offset alternado para patrón más natural
        final offsetX = (y ~/ spacing).isEven ? 0.0 : spacing / 2;

        _drawLeaf(canvas, paint, Offset(x + offsetX, y), leafSize);
      }
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();

    // Forma de hoja/nenúfar simplificada
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
