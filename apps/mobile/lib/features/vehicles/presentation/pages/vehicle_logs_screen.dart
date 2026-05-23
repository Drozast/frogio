// lib/features/vehicles/presentation/pages/vehicle_logs_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/vehicle_api_data_source.dart';
import '../../data/models/vehicle_log_model.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/services/trip_tracking_service.dart';
import 'package:http/http.dart' as http;

class VehicleLogsScreen extends StatefulWidget {
  const VehicleLogsScreen({super.key});

  @override
  State<VehicleLogsScreen> createState() => _VehicleLogsScreenState();
}

class _VehicleLogsScreenState extends State<VehicleLogsScreen> {
  late final VehicleApiDataSource _datasource;
  final _tripService = TripTrackingService();

  bool _isLoading = true;
  String? _error;
  List<_EnrichedLog> _logs = [];
  String _search = '';
  bool _wasTripActive = false;

  @override
  void initState() {
    super.initState();
    _wasTripActive = _tripService.isActive;
    _tripService.addListener(_onTripServiceChange);
    _initDatasource();
  }

  @override
  void dispose() {
    _tripService.removeListener(_onTripServiceChange);
    super.dispose();
  }

  /// Refresh the list when a trip transitions from active to inactive
  /// (i.e. when a user finishes a trip and returns a vehicle).
  void _onTripServiceChange() {
    if (!mounted) return;
    final nowActive = _tripService.isActive;
    if (_wasTripActive && !nowActive) {
      _loadLogs();
    }
    _wasTripActive = nowActive;
  }

  Future<void> _initDatasource() async {
    final prefs = await SharedPreferences.getInstance();
    _datasource = VehicleApiDataSource(
      client: http.Client(),
      prefs: prefs,
      baseUrl: ApiConfig.activeBaseUrl,
    );
    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch vehicles first, then their logs
      final vehicles = await _datasource.getVehicles('');
      final enriched = <_EnrichedLog>[];

      for (final vehicle in vehicles) {
        try {
          final logs = await _datasource.getVehicleLogs(vehicle.id);
          for (final log in logs) {
            enriched.add(_EnrichedLog(log: log, vehicle: vehicle));
          }
        } catch (_) {
          // Skip vehicles whose logs fail to load
        }
      }

      enriched.sort((a, b) => b.log.startTime.compareTo(a.log.startTime));

      setState(() {
        _logs = enriched;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<_EnrichedLog> get _filtered {
    if (_search.isEmpty) return _logs;
    final q = _search.toLowerCase();
    return _logs.where((e) {
      return e.vehicle.plate.toLowerCase().contains(q) ||
          e.log.driverName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _exportCsv() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${dir.path}/bitacora_$timestamp.csv');

      final buf = StringBuffer();
      buf.writeln(
          'Patente,Conductor,Inicio,Fin,Duracion (min),Distancia (km),Tipo,Proposito,Observaciones');

      for (final e in _logs) {
        final log = e.log;
        final duration = log.endTime != null
            ? log.endTime!.difference(log.startTime).inMinutes.toString()
            : '';
        final distance = log.endKm != null
            ? (log.endKm! - log.startKm).toStringAsFixed(1)
            : '';
        final start = DateFormat('dd/MM/yyyy HH:mm').format(log.startTime);
        final end =
            log.endTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(log.endTime!) : '';

        buf.writeln(
          '"${e.vehicle.plate}","${log.driverName}","$start","$end","$duration","$distance","${log.usageType.name}","${log.purpose ?? ''}","${log.observations ?? ''}"',
        );
      }

      await file.writeAsString(buf.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exportado: ${file.path}'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: AppTheme.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Bitácora de Vehículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Exportar CSV',
            onPressed: _logs.isEmpty ? null : _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar por patente o conductor...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 12),
            Text('Cargando bitácora...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.emergency),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLogs,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filtered;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No hay registros en la bitácora',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _VehicleLogCard(
          enriched: filtered[index],
          onTap: () => _openRouteDetail(filtered[index]),
        ),
      ),
    );
  }

  void _openRouteDetail(_EnrichedLog enriched) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteDetailSheet(enriched: enriched),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _VehicleLogCard extends StatelessWidget {
  final _EnrichedLog enriched;
  final VoidCallback onTap;

  const _VehicleLogCard({required this.enriched, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final log = enriched.log;
    final vehicle = enriched.vehicle;

    final duration = log.endTime != null
        ? log.endTime!.difference(log.startTime)
        : DateTime.now().difference(log.startTime);
    final distance =
        log.endKm != null ? log.endKm! - log.startKm : null;
    final isActive = log.endTime == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle.plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.driverName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTIVO',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(log.startTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Chip(
                    icon: Icons.timer_outlined,
                    label: _formatDuration(duration),
                  ),
                  const SizedBox(width: 8),
                  if (distance != null)
                    _Chip(
                      icon: Icons.speed,
                      label: '${distance.toStringAsFixed(1)} km',
                    ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.route,
                    label: '${log.route.length} pts GPS',
                  ),
                ],
              ),
              if (log.purpose != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.purpose!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// ── Route Detail Sheet ────────────────────────────────────────────────────────

class _RouteDetailSheet extends StatefulWidget {
  final _EnrichedLog enriched;

  const _RouteDetailSheet({required this.enriched});

  @override
  State<_RouteDetailSheet> createState() => _RouteDetailSheetState();
}

class _RouteDetailSheetState extends State<_RouteDetailSheet> {
  final MapController _mapController = MapController();
  Timer? _animTimer;
  int _animIndex = 0;
  final List<LatLng> _animatedPoints = [];
  bool _isPlaying = false;

  List<LocationPointModel> get _route => widget.enriched.log.route;

  @override
  void initState() {
    super.initState();
    // Show full route on open
    _animatedPoints.addAll(
      _route.map((p) => LatLng(p.latitude, p.longitude)),
    );
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  void _playAnimation() {
    if (_route.isEmpty) return;
    setState(() {
      _animatedPoints.clear();
      _animIndex = 0;
      _isPlaying = true;
    });

    const speed = Duration(milliseconds: 80);
    _animTimer = Timer.periodic(speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_animIndex >= _route.length) {
        timer.cancel();
        setState(() => _isPlaying = false);
        return;
      }
      final p = _route[_animIndex];
      setState(() {
        _animatedPoints.add(LatLng(p.latitude, p.longitude));
        _animIndex++;
      });
      if (_animatedPoints.length > 1) {
        try {
          _mapController.move(_animatedPoints.last, _mapController.camera.zoom);
        } catch (_) {}
      }
    });
  }

  void _stopAnimation() {
    _animTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _animatedPoints.clear();
      _animatedPoints.addAll(
        _route.map((p) => LatLng(p.latitude, p.longitude)),
      );
    });
  }

  LatLngBounds? get _bounds {
    if (_animatedPoints.isEmpty) return null;
    double minLat = _animatedPoints.first.latitude;
    double maxLat = _animatedPoints.first.latitude;
    double minLng = _animatedPoints.first.longitude;
    double maxLng = _animatedPoints.first.longitude;
    for (final p in _animatedPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      LatLng(minLat - 0.001, minLng - 0.001),
      LatLng(maxLat + 0.001, maxLng + 0.001),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.enriched.log;
    final vehicle = widget.enriched.vehicle;
    final hasRoute = _route.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicle.plate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.driverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm', 'es').format(log.startTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Stats row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.timer_outlined,
                      label: 'Duración',
                      value: log.endTime != null
                          ? _formatDuration(log.endTime!.difference(log.startTime))
                          : 'En curso',
                    ),
                    if (log.endKm != null)
                      _StatItem(
                        icon: Icons.speed,
                        label: 'Distancia',
                        value: '${(log.endKm! - log.startKm).toStringAsFixed(1)} km',
                      ),
                    _StatItem(
                      icon: Icons.route,
                      label: 'Puntos GPS',
                      value: '${_route.length}',
                    ),
                    _StatItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Tipo',
                      value: log.usageType.name,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Map
              Expanded(
                child: hasRoute
                    ? _buildMap()
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            const Text('Sin datos de ruta GPS',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),

              // Playback controls
              if (hasRoute)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isPlaying ? _stopAnimation : _playAnimation,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(_isPlaying ? 'Detener' : 'Animar Ruta'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap() {
    final bounds = _bounds;
    final center = bounds != null
        ? LatLng(
            (bounds.south + bounds.north) / 2,
            (bounds.west + bounds.east) / 2,
          )
        : LatLng(
            _route.first.latitude,
            _route.first.longitude,
          );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14,
        onMapReady: () {
          if (bounds != null) {
            try {
              _mapController.fitCamera(
                CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
              );
            } catch (_) {}
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: '${ApiConfig.tileServerUrl}/tile/{z}/{x}/{y}.png',
          userAgentPackageName: ApiConfig.appPackageName,
        ),
        if (_animatedPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _animatedPoints,
                color: AppTheme.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        if (_animatedPoints.isNotEmpty)
          MarkerLayer(
            markers: [
              // Start marker
              Marker(
                point: LatLng(_route.first.latitude, _route.first.longitude),
                width: 32,
                height: 32,
                child: const Icon(Icons.trip_origin, color: Colors.green, size: 28),
              ),
              // Current/end marker
              Marker(
                point: _animatedPoints.last,
                width: 32,
                height: 32,
                child: Icon(
                  _route.last.latitude == _animatedPoints.last.latitude &&
                          _route.last.longitude == _animatedPoints.last.longitude
                      ? Icons.flag
                      : Icons.directions_car,
                  color: _isPlaying ? AppTheme.primary : Colors.red,
                  size: 28,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// ── Data helpers ───────────────────────────────────────────────────────────────

class _EnrichedLog {
  final VehicleLogModel log;
  final VehicleModel vehicle;

  const _EnrichedLog({required this.log, required this.vehicle});
}
