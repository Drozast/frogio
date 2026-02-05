import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/panic_alert_entity.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';
import '../bloc/panic_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SosTrackingScreen extends StatefulWidget {
  final String? alertId;

  const SosTrackingScreen({super.key, this.alertId});

  @override
  State<SosTrackingScreen> createState() => _SosTrackingScreenState();
}

class _SosTrackingScreenState extends State<SosTrackingScreen>
    with SingleTickerProviderStateMixin {
  late PanicBloc _panicBloc;
  Timer? _refreshTimer;
  late AnimationController _pulseController;
  PanicAlertEntity? _alert;
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();
    _panicBloc = di.sl<PanicBloc>();
    _panicBloc.add(const LoadActiveAlertEvent());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_isResolved) {
        _panicBloc.add(const LoadActiveAlertEvent());
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _panicBloc.close();
    super.dispose();
  }

  void _cancelAlert() {
    if (_alert == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Alerta'),
        content: const Text('¿Estás seguro de que quieres cancelar tu alerta de emergencia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _panicBloc.add(CancelPanicAlertEvent(alertId: _alert!.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Si, cancelar'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'responding':
        return 'Inspector en camino';
      case 'active':
        return 'Buscando ayuda...';
      case 'resolved':
        return 'Alerta resuelta';
      case 'cancelled':
        return 'Alerta cancelada';
      case 'dismissed':
        return 'Alerta descartada';
      default:
        return 'Estado: $status';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'responding':
        return Icons.directions_run_rounded;
      case 'active':
        return Icons.sos_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'responding':
        return const Color(0xFF1B5E20);
      case 'active':
        return const Color(0xFFC62828);
      case 'resolved':
        return AppTheme.success;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _panicBloc,
      child: BlocConsumer<PanicBloc, PanicState>(
        listener: (context, state) {
          if (state is PanicAlertActive) {
            setState(() => _alert = state.alert);
            if (state.alert.isResolved || state.alert.isCancelled) {
              setState(() => _isResolved = true);
              _refreshTimer?.cancel();
            }
          } else if (state is PanicAlertCancelled) {
            setState(() => _isResolved = true);
            _refreshTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alerta cancelada'),
                backgroundColor: Colors.grey,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is PanicInitial) {
            // No active alert found - it was resolved/cancelled
            if (_alert != null) {
              setState(() => _isResolved = true);
              _refreshTimer?.cancel();
            }
          }
        },
        builder: (context, state) {
          final alert = _alert;
          final status = alert?.status ?? 'active';
          final statusColor = _getStatusColor(status);
          final isTerminal = status == 'resolved' || status == 'cancelled' || status == 'dismissed';

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text(
                'Seguimiento SOS',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: statusColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                // Status header
                _buildStatusHeader(status, statusColor, isTerminal),

                // Map
                Expanded(
                  child: alert != null
                      ? _buildMap(alert)
                      : const Center(child: CircularProgressIndicator()),
                ),

                // Bottom action bar
                if (!isTerminal && alert != null)
                  _buildActionBar(alert),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(String status, Color statusColor, bool isTerminal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Animated status icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isTerminal ? 1.0 : 1.0 + (_pulseController.value * 0.15);
              final opacity = isTerminal ? 1.0 : 0.7 + (_pulseController.value * 0.3);
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: opacity * 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusText(status),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status == 'responding'
                ? 'Manten la calma, la ayuda esta en camino'
                : status == 'active'
                    ? 'Tu alerta ha sido enviada'
                    : status == 'resolved'
                        ? 'Tu emergencia ha sido atendida'
                        : '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          if (_alert?.address != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _alert!.address!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap(PanicAlertEntity alert) {
    final center = LatLng(alert.latitude, alert.longitude);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.frogio.santa_juana',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final outerSize = 50.0 + (_pulseController.value * 10);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring
                      Container(
                        width: outerSize,
                        height: outerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.2 * (1 - _pulseController.value)),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4 * (1 - _pulseController.value)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Center pin
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBar(PanicAlertEntity alert) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.isResponding ? 'Inspector respondiendo' : 'Alerta activa',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${alert.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _cancelAlert,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
