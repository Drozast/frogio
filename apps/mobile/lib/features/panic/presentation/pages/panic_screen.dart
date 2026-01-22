import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  // Colores del tema (estilo FROGIO)
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF7CB342);
  static const Color _emergencyRed = Color(0xFFC62828);
  static const Color _emergencyRedLight = Color(0xFFE57373);

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
            context.read<PanicBloc>().add(const ResetPanicStateEvent());
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
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // Fondo con patrón de hojas/nenúfares (estilo FROGIO)
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
                                  color: isActive ? _primaryGreen : _emergencyRed,
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
                                  color: isActive ? _primaryGreen : _emergencyRed,
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
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: CustomPaint(
          painter: _LeafPatternPainter(
            color: isActive ? _primaryGreen : _emergencyRed,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isActive) {
    final headerColor = isActive ? _primaryGreen : _emergencyRed;

    return Container(
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Título
                      Text(
                        isActive ? 'ALERTA ACTIVA' : 'EMERGENCIA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tarjeta de usuario (estilo FROGIO)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: isActive ? _lightGreen : _emergencyRedLight,
                            borderRadius: BorderRadius.circular(16),
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
    final borderColor = isActive ? _lightGreen : _emergencyRedLight;
    final iconBgColor = isActive ? _primaryGreen.withValues(alpha: 0.1) : _emergencyRed.withValues(alpha: 0.1);
    final iconColor = isActive ? _primaryGreen : _emergencyRed;

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  child: Icon(
                    Icons.refresh,
                    color: iconColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade800,
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
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: TextButton.icon(
        onPressed: () => _cancelAlert(context),
        icon: Icon(Icons.close_rounded, size: 22, color: Colors.orange.shade700),
        label: Text(
          'Cancelar alerta',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
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
