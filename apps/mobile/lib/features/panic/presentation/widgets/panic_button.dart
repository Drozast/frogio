import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PanicButton extends StatefulWidget {
  final VoidCallback onPanicTriggered;
  final bool isLoading;
  final bool isActive;

  const PanicButton({
    super.key,
    required this.onPanicTriggered,
    this.isLoading = false,
    this.isActive = false,
  });

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with TickerProviderStateMixin {
  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Estado del hold
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;
  static const _holdDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Animación de pulso principal
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Animación de rotación para el anillo exterior
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    _rotationController.repeat();

    // Animación de escala al presionar
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Animación de brillo
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.isLoading || widget.isActive) return;

    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    _scaleController.forward();
    HapticFeedback.mediumImpact();

    const tickDuration = Duration(milliseconds: 20);
    final totalTicks = _holdDuration.inMilliseconds ~/ tickDuration.inMilliseconds;

    _holdTimer = Timer.periodic(tickDuration, (timer) {
      setState(() {
        _holdProgress = timer.tick / totalTicks;
      });

      // Vibración suave cada 25%
      if (_holdProgress > 0.25 && _holdProgress < 0.26 ||
          _holdProgress > 0.5 && _holdProgress < 0.51 ||
          _holdProgress > 0.75 && _holdProgress < 0.76) {
        HapticFeedback.lightImpact();
      }

      if (_holdProgress >= 1.0) {
        timer.cancel();
        _triggerPanic();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _scaleController.reverse();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _triggerPanic() {
    HapticFeedback.heavyImpact();
    widget.onPanicTriggered();
    _scaleController.reverse();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Instrucciones con diseño moderno
        _buildInstructions(),
        const SizedBox(height: 32),

        // Botón de pánico con animaciones
        _buildAnimatedButton(),

        const SizedBox(height: 32),

        // Estado actual
        if (widget.isActive) _buildActiveStatus(),
      ],
    );
  }

  Widget _buildInstructions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isActive
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (widget.isActive ? Colors.green : Colors.red)
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isActive ? Icons.shield_rounded : Icons.touch_app_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            widget.isActive
                ? 'Alerta enviada - Ayuda en camino'
                : 'Mantén presionado para activar',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _scaleAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive
                ? 1.0
                : _pulseAnimation.value * _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Anillo exterior animado
              _buildOuterRing(),

              // Círculo de progreso
              if (_isHolding) _buildProgressCircle(),

              // Círculos de onda
              if (!widget.isActive && !widget.isLoading) ..._buildWaveCircles(),

              // Botón principal
              _buildMainButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOuterRing() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: widget.isActive
                    ? [
                        Colors.green.shade300,
                        Colors.green.shade500,
                        Colors.teal.shade400,
                        Colors.green.shade300,
                      ]
                    : [
                        Colors.red.shade300,
                        Colors.red.shade500,
                        Colors.orange.shade400,
                        Colors.red.shade300,
                      ],
              ),
            ),
            child: Center(
              child: Container(
                width: 225,
                height: 225,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCircle() {
    return SizedBox(
      width: 230,
      height: 230,
      child: CircularProgressIndicator(
        value: _holdProgress,
        strokeWidth: 6,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(
          Color.lerp(Colors.orange, Colors.red.shade700, _holdProgress)!,
        ),
        strokeCap: StrokeCap.round,
      ),
    );
  }

  List<Widget> _buildWaveCircles() {
    return [
      AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 210 + (20 * _glowAnimation.value),
            height: 210 + (20 * _glowAnimation.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1 * (1 - _glowAnimation.value)),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 195 + (15 * _glowAnimation.value),
            height: 195 + (15 * _glowAnimation.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.15 * (1 - _glowAnimation.value)),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: widget.isActive
                  ? [Colors.green.shade400, Colors.green.shade700]
                  : widget.isLoading
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : [
                          Colors.red.shade400,
                          Colors.red.shade600,
                          Colors.red.shade800,
                        ],
              stops: widget.isActive || widget.isLoading
                  ? [0.0, 1.0]
                  : [0.0, 0.6, 1.0],
              center: Alignment.topLeft,
              radius: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isActive
                        ? Colors.green
                        : widget.isLoading
                            ? Colors.grey
                            : Colors.red)
                    .withValues(alpha: 0.4 + (0.2 * _glowAnimation.value)),
                blurRadius: 25 + (10 * _glowAnimation.value),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Escudo de la municipalidad como fondo sutil
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Image.asset(
                        'assets/images/muni-vertical.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                // Contenido del botón
                Material(
                  color: Colors.transparent,
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          )
                        : _buildButtonContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _isHolding ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono con efecto de shake cuando se presiona
            Transform.translate(
              offset: Offset(
                _isHolding ? math.sin(DateTime.now().millisecondsSinceEpoch / 50) * 2 : 0,
                0,
              ),
              child: Icon(
                widget.isActive
                    ? Icons.check_circle_rounded
                    : _isHolding
                        ? Icons.front_hand_rounded
                        : Icons.warning_rounded,
                size: 65 - (value * 10),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            // Texto con porcentaje cuando se mantiene presionado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                widget.isActive
                    ? 'ENVIADO'
                    : _isHolding
                        ? '${(_holdProgress * 100).toInt()}%'
                        : 'SOS',
                key: ValueKey(widget.isActive
                    ? 'sent'
                    : _isHolding
                        ? 'progress'
                        : 'sos'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isHolding ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: _isHolding ? 1 : 4,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveStatus() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta enviada',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspectores notificados',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
