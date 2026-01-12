import 'package:flutter/material.dart';

class TrackingIndicator extends StatefulWidget {
  final bool isTracking;
  final double? currentSpeed;
  final int pointsRecorded;
  final Duration? elapsedTime;
  final VoidCallback? onTap;

  const TrackingIndicator({
    super.key,
    required this.isTracking,
    this.currentSpeed,
    this.pointsRecorded = 0,
    this.elapsedTime,
    this.onTap,
  });

  @override
  State<TrackingIndicator> createState() => _TrackingIndicatorState();
}

class _TrackingIndicatorState extends State<TrackingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isTracking) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TrackingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTracking && !oldWidget.isTracking) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isTracking && oldWidget.isTracking) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isTracking
              ? Colors.green.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isTracking
                ? Colors.green.shade300
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: widget.isTracking
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // GPS Icon with pulse animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isTracking ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isTracking
                          ? Colors.green.shade400
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gps_fixed,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),

            // Status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.isTracking ? 'GPS Activo' : 'GPS Inactivo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.isTracking
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (widget.isTracking) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (widget.isTracking) ...[
                    Row(
                      children: [
                        if (widget.currentSpeed != null) ...[
                          Icon(
                            Icons.speed,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.currentSpeed!.toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.pointsRecorded} puntos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      'Toca para ver detalles',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ),

            // Duration
            if (widget.isTracking && widget.elapsedTime != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(widget.elapsedTime!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for app bar or floating button
class TrackingIndicatorCompact extends StatelessWidget {
  final bool isTracking;
  final VoidCallback? onTap;

  const TrackingIndicatorCompact({
    super.key,
    required this.isTracking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isTracking ? Colors.green : Colors.grey.shade400,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isTracking ? Colors.green : Colors.grey)
                  .withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isTracking ? Icons.gps_fixed : Icons.gps_off,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
