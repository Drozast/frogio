import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/services/trip_tracking_service.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../bloc/vehicle_bloc.dart';
import '../widgets/active_trip_banner.dart';
import '../widgets/vehicle_card.dart';
import 'active_trip_page.dart';
import 'start_trip_page.dart';

class VehicleSelectionPage extends StatefulWidget {
  final String userId;
  final String userName;

  const VehicleSelectionPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(
          LoadVehiclesByStatusEvent(
            status: VehicleStatus.available,
            muniId: ApiConfig.tenantId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Bitácora'),
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.primary.withValues(alpha: 0.15)),
        ),
      ),
      body: Column(
        children: [
          // Active trip banner (if any) — tap to continue
          ActiveTripBanner(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ya tienes un viaje activo. Finalizalo antes de iniciar otro.'),
                  backgroundColor: Colors.teal,
                ),
              );
            },
          ),

          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceWhite,
            child: TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por patente o modelo...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Vehicle List
          Expanded(
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  );
                }

                if (state is VehicleError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<VehicleBloc>().add(
                                  LoadVehiclesByStatusEvent(
                                    status: VehicleStatus.available,
                                    muniId: ApiConfig.tenantId,
                                  ),
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is VehiclesLoaded) {
                  // Show ALL vehicles (not just filteredVehicles) so users can see in-use too
                  final vehicles = state.vehicles.where((v) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    return v.plate.toLowerCase().contains(query) ||
                        v.model.toLowerCase().contains(query) ||
                        v.brand.toLowerCase().contains(query);
                  }).toList()
                    ..sort((a, b) {
                      // My active trip first, then in-use by others, then available
                      final aMine = a.status == VehicleStatus.inUse && a.currentDriverId == widget.userId;
                      final bMine = b.status == VehicleStatus.inUse && b.currentDriverId == widget.userId;
                      if (aMine && !bMine) return -1;
                      if (!aMine && bMine) return 1;
                      final aInUse = a.status == VehicleStatus.inUse;
                      final bInUse = b.status == VehicleStatus.inUse;
                      if (aInUse && !bInUse) return -1;
                      if (!aInUse && bInUse) return 1;
                      return a.plate.compareTo(b.plate);
                    });

                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: AppTheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay vehículos disponibles'
                                : 'No se encontraron vehículos',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceWhite,
                    onRefresh: () async {
                      context.read<VehicleBloc>().add(
                            LoadVehiclesByStatusEvent(
                              status: VehicleStatus.available,
                              muniId: ApiConfig.tenantId,
                            ),
                          );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        final isMine = vehicle.status == VehicleStatus.inUse && vehicle.currentDriverId == widget.userId;
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(vehicle.id),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 80)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(30 * (1 - value), 0),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AppVehicleCardWrapper(
                              vehicle: vehicle,
                              highlight: isMine,
                              onTap: () => _onVehicleSelected(vehicle),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onVehicleSelected(VehicleEntity vehicle) {
    // Vehicle in use
    if (vehicle.status == VehicleStatus.inUse) {
      // By current user → go to active trip
      if (vehicle.currentDriverId == widget.userId) {
        // Prefer the vehicle.activeLogId from backend, fallback to local service
        final logId = vehicle.activeLogId ?? TripTrackingService().activeLogId;
        if (logId != null) {
          // Ensure tracking is running (restore it if necessary after fresh install)
          if (!TripTrackingService().isActive) {
            TripTrackingService().startTrip(logId: logId, plate: vehicle.plate);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => di.sl<VehicleBloc>(),
                child: ActiveTripPage(
                  vehicleLogId: logId,
                  vehicle: vehicle,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el viaje activo')),
          );
        }
      } else {
        // Someone else's trip
        final driver = vehicle.currentDriverName ?? 'otro inspector';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Este vehiculo esta en uso por $driver'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Available
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (_) => di.sl<VehicleBloc>(),
          child: StartTripPage(
            vehicle: vehicle,
            userId: widget.userId,
            userName: widget.userName,
          ),
        ),
      ),
    );
  }
}

/// Wraps [VehicleCard] in an AppTheme-styled container with selection border.
class _AppVehicleCardWrapper extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onTap;
  final bool highlight;

  const _AppVehicleCardWrapper({
    required this.vehicle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: highlight
                ? Colors.teal
                : AppTheme.primary.withValues(alpha: 0.15),
            width: highlight ? 2.0 : 1.0,
          ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.shadowSmall,
        ),
        child: Stack(
          children: [
            VehicleCard(vehicle: vehicle, onTap: onTap),
            if (highlight)
              Positioned(
                top: 10,
                right: 10,
                child: _PulsingBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingBadge extends StatefulWidget {
  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withValues(alpha: 0.3 + _c.value * 0.3),
                blurRadius: 8 + _c.value * 8,
                spreadRadius: 1 + _c.value * 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              const Text('MI VIAJE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        );
      },
    );
  }
}
