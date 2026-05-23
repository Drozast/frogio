import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frogio_mobile/core/services/maps_service.dart';

import '../../../../core/config/api_config.dart';
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

    const reasons = [
      ('error_digitacion', 'Error de digitación'),
      ('situacion_resuelta', 'Situación resuelta'),
      ('otro', 'Otro motivo'),
    ];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.emergency.withValues(alpha: 0.3)),
          ),
          title: Text(
            'Cancelar Alerta',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Por qué cancelas tu alerta?',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              ...reasons.map(((String value, String label) r) => RadioListTile<String>(
                    value: r.$1,
                    groupValue: selectedReason,
                    onChanged: (v) => setDialogState(() => selectedReason = v),
                    title: Text(r.$2, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppTheme.emergency,
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Volver', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: AppTheme.emergency.withValues(alpha: 0.2), blurRadius: 8)],
              ),
              child: ElevatedButton(
                onPressed: selectedReason == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        final label = reasons.firstWhere((r) => r.$1 == selectedReason).$2;
                        _panicBloc.add(CancelPanicAlertEvent(
                          alertId: _alert!.id,
                          reason: label,
                        ));
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emergency,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.emergency.withValues(alpha: 0.3),
                ),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
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
        return AppTheme.success;
      case 'active':
        return AppTheme.emergency;
      case 'resolved':
        return AppTheme.success;
      case 'cancelled':
        return const Color(0xFF778899);
      default:
        return AppTheme.emergency;
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
          } else if (state is PanicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.emergency,
              ),
            );
          }
        },
        builder: (context, state) {
          final alert = _alert;
          final status = alert?.status ?? 'active';
          final statusColor = _getStatusColor(status);
          final isTerminal = status == 'resolved' || status == 'cancelled' || status == 'dismissed';

          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              title: const Text('Seguimiento SOS'),
              backgroundColor: AppTheme.surfaceWhite,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
              shadowColor: statusColor.withValues(alpha: 0.3),
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 8)],
        border: Border(
          bottom: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.5),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: opacity * 0.18),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2 * opacity), blurRadius: 8)],
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 36,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status == 'responding'
                ? 'Manten la calma, la ayuda esta en camino'
                : status == 'active'
                    ? 'Tu alerta ha sido enviada'
                    : status == 'resolved'
                        ? 'Tu emergencia ha sido atendida'
                        : '',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF778899),
            ),
            textAlign: TextAlign.center,
          ),
          if (_alert?.address != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: statusColor.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _alert!.address!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF778899),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Progress steps: Enviado → En camino → Finalizado
          _buildProgressSteps(status),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(String status) {
    final steps = [
      {'label': 'Enviado', 'icon': Icons.send_rounded},
      {'label': 'En camino', 'icon': Icons.directions_run_rounded},
      {'label': 'Finalizado', 'icon': Icons.check_circle_rounded},
    ];

    int currentStep;
    switch (status) {
      case 'active':
        currentStep = 0;
        break;
      case 'responding':
        currentStep = 1;
        break;
      case 'resolved':
      case 'cancelled':
      case 'dismissed':
        currentStep = 2;
        break;
      default:
        currentStep = 0;
    }

    final accent = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? accent.withValues(alpha: 0.18)
                              : AppTheme.surfaceWhite,
                          border: Border.all(
                            color: isCompleted ? accent : const Color(0xFF334455),
                            width: isCurrent ? 2 : 1,
                          ),
                          boxShadow: isCurrent ? [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 8)] : null,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 18,
                          color: isCompleted ? accent : const Color(0xFF445566),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? accent : const Color(0xFF445566),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? accent.withValues(alpha: 0.6)
                          : const Color(0xFF223344),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          );
        }),
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
          urlTemplate: MapsService.tileServerUrl,
                  tileProvider: MapsService.tileProvider,
          userAgentPackageName: ApiConfig.appPackageName,
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
                          color: AppTheme.emergency.withValues(alpha: 0.18 * (1 - _pulseController.value)),
                          border: Border.all(
                            color: AppTheme.emergency.withValues(alpha: 0.5 * (1 - _pulseController.value)),
                            width: 2,
                          ),
                        ),
                      ),
                      // Center pin
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.emergency,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: AppTheme.emergency.withValues(alpha: 0.3), blurRadius: 10)],
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
        color: AppTheme.surfaceWhite,
        border: Border(
          top: BorderSide(color: AppTheme.emergency.withValues(alpha: 0.25), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emergency.withValues(alpha: 0.08),
            blurRadius: 16,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${alert.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: AppTheme.emergency.withValues(alpha: 0.2), blurRadius: 8)],
            ),
            child: ElevatedButton.icon(
              onPressed: _cancelAlert,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancelar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emergency.withValues(alpha: 0.15),
                foregroundColor: AppTheme.emergency,
                elevation: 0,
                side: BorderSide(color: AppTheme.emergency.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
