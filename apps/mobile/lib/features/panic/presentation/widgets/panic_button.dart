import 'dart:async';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _holdTimer;
  double _holdProgress = 0.0;
  bool _isHolding = false;
  static const _holdDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (widget.isLoading || widget.isActive) return;

    setState(() {
      _isHolding = true;
      _holdProgress = 0.0;
    });

    HapticFeedback.mediumImpact();

    const tickDuration = Duration(milliseconds: 50);
    final totalTicks = _holdDuration.inMilliseconds ~/ tickDuration.inMilliseconds;

    _holdTimer = Timer.periodic(tickDuration, (timer) {
      setState(() {
        _holdProgress = timer.tick / totalTicks;
      });

      if (_holdProgress >= 1.0) {
        timer.cancel();
        _triggerPanic();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
  }

  void _triggerPanic() {
    HapticFeedback.heavyImpact();
    widget.onPanicTriggered();
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
        // Instrucciones
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                widget.isActive
                    ? 'Alerta activa - Ayuda en camino'
                    : 'Mantén presionado 2 segundos',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Botón de pánico
        GestureDetector(
          onLongPressStart: (_) => _startHold(),
          onLongPressEnd: (_) => _cancelHold(),
          onLongPressCancel: _cancelHold,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isActive ? 1.0 : _pulseAnimation.value,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de progreso de fondo
                if (_isHolding)
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 8,
                      backgroundColor: Colors.red.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red.shade900,
                      ),
                    ),
                  ),

                // Botón principal
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: widget.isActive
                          ? [Colors.orange.shade400, Colors.orange.shade700]
                          : widget.isLoading
                              ? [Colors.grey.shade400, Colors.grey.shade600]
                              : [Colors.red.shade400, Colors.red.shade700],
                      center: Alignment.topLeft,
                      radius: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isActive
                                ? Colors.orange
                                : widget.isLoading
                                    ? Colors.grey
                                    : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.isActive
                                    ? Icons.check_circle
                                    : Icons.warning_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isActive ? 'ENVIADO' : 'SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Mensaje de estado
        if (widget.isActive)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alerta enviada correctamente',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Los inspectores han sido notificados',
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
      ],
    );
  }
}
