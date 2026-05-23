// lib/features/admin/presentation/pages/route_playback_screen.dart
//
// Reproduccion animada de la ruta de un vehicle log.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;

/// Animated route playback for a single vehicle log.
class RoutePlaybackScreen extends StatefulWidget {
  final String vehicleLogId;
  final String? plate;
  final String? driverName;

  const RoutePlaybackScreen({
    super.key,
    required this.vehicleLogId,
    this.plate,
    this.driverName,
  });

  @override
  State<RoutePlaybackScreen> createState() => _RoutePlaybackScreenState();
}

class _RoutePlaybackScreenState extends State<RoutePlaybackScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Data
  bool _loading = true;
  String? _error;
  List<_RoutePoint> _points = [];

  // Stats
  double _totalDistanceKm = 0;
  Duration _totalDuration = Duration.zero;
  double _avgSpeedKmh = 0;
  double _maxSpeedKmh = 0;

  // Playback
  Ticker? _ticker;
  bool _isPlaying = false;
  int _currentIndex = 0;
  Duration _accumElapsed = Duration.zero;
  Duration _lastTickDuration = Duration.zero;
  double _speedMultiplier = 1.0;

  static const List<double> _speedOptions = [1, 2, 4, 8];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _load();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.get(
        Uri.parse(
            '${ApiConfig.activeBaseUrl}/api/vehicles/logs/${widget.vehicleLogId}'),
      );
      if (res.statusCode >= 400) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final decoded = json.decode(res.body);
      Map<String, dynamic> log;
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map) {
          log = Map<String, dynamic>.from(decoded['data'] as Map);
        } else if (decoded['log'] is Map) {
          log = Map<String, dynamic>.from(decoded['log'] as Map);
        } else {
          log = decoded;
        }
      } else {
        throw Exception('Respuesta invalida del servidor');
      }

      final raw = log['route_points'] ?? log['routePoints'];
      if (raw is! List) {
        throw Exception('La bitacora no tiene puntos de ruta');
      }
      final pts = raw
          .whereType<Map>()
          .map((e) => _RoutePoint.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p != null)
          .cast<_RoutePoint>()
          .toList();

      // Sort by timestamp if present
      pts.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return -1;
        if (b.timestamp == null) return 1;
        return a.timestamp!.compareTo(b.timestamp!);
      });

      _computeStats(pts);

      if (!mounted) return;
      setState(() {
        _points = pts;
        _loading = false;
        _currentIndex = 0;
        _accumElapsed = Duration.zero;
      });

      // Fit camera once data is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToRoute();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _computeStats(List<_RoutePoint> pts) {
    double dist = 0;
    double maxSpeed = 0;
    double sumSpeed = 0;
    int speedCount = 0;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      if (p.speed != null) {
        if (p.speed! > maxSpeed) maxSpeed = p.speed!;
        sumSpeed += p.speed!;
        speedCount++;
      }
      if (i > 0) {
        final prev = pts[i - 1];
        dist += Geolocator.distanceBetween(
              prev.latLng.latitude,
              prev.latLng.longitude,
              p.latLng.latitude,
              p.latLng.longitude,
            ) /
            1000.0;
      }
    }

    Duration total = Duration.zero;
    if (pts.length >= 2 &&
        pts.first.timestamp != null &&
        pts.last.timestamp != null) {
      total = pts.last.timestamp!.difference(pts.first.timestamp!);
      if (total.isNegative) total = Duration.zero;
    }
    _totalDistanceKm = dist;
    _totalDuration = total;
    _maxSpeedKmh = maxSpeed;
    _avgSpeedKmh = speedCount > 0 ? sumSpeed / speedCount : 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYBACK
  // ═══════════════════════════════════════════════════════════════════════════

  Duration get _routeDuration {
    if (_points.length < 2 ||
        _points.first.timestamp == null ||
        _points.last.timestamp == null) {
      // Fallback: 1 second per point
      return Duration(seconds: math.max(1, _points.length));
    }
    final d = _points.last.timestamp!.difference(_points.first.timestamp!);
    if (d.isNegative || d == Duration.zero) {
      return Duration(seconds: math.max(1, _points.length));
    }
    return d;
  }

  void _play() {
    if (_points.length < 2) return;
    if (_currentIndex >= _points.length - 1) {
      // Reset to start
      setState(() {
        _currentIndex = 0;
        _accumElapsed = Duration.zero;
      });
    }
    _lastTickDuration = Duration.zero;
    _ticker?.start();
    setState(() => _isPlaying = true);
  }

  void _pause() {
    _ticker?.stop();
    setState(() => _isPlaying = false);
  }

  void _stop() {
    _ticker?.stop();
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
      _accumElapsed = Duration.zero;
    });
    if (_points.isNotEmpty) {
      _mapController.move(_points.first.latLng, _mapController.camera.zoom);
    }
  }

  void _onTick(Duration elapsed) {
    if (_points.length < 2) return;
    final delta = elapsed - _lastTickDuration;
    _lastTickDuration = elapsed;

    final scaled = Duration(microseconds: (delta.inMicroseconds * _speedMultiplier).round());
    _accumElapsed += scaled;

    final routeDur = _routeDuration;
    final progress = _accumElapsed.inMicroseconds / routeDur.inMicroseconds;
    if (progress >= 1.0) {
      // End of playback
      setState(() {
        _currentIndex = _points.length - 1;
        _accumElapsed = routeDur;
        _isPlaying = false;
      });
      _ticker?.stop();
      _mapController.move(_points.last.latLng, _mapController.camera.zoom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reproducción finalizada')),
        );
      }
      return;
    }

    final newIndex = _indexAtProgress(progress);
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
      _mapController.move(
        _points[newIndex].latLng,
        _mapController.camera.zoom,
      );
    }
  }

  int _indexAtProgress(double progress) {
    if (_points.isEmpty) return 0;
    if (_points.first.timestamp == null || _points.last.timestamp == null) {
      // Linear by index
      final idx = (progress * (_points.length - 1)).floor();
      return idx.clamp(0, _points.length - 1);
    }
    final start = _points.first.timestamp!;
    final routeDur = _routeDuration;
    final targetTs = start.add(
      Duration(microseconds: (routeDur.inMicroseconds * progress).round()),
    );
    // Linear scan from current index forward
    int i = _currentIndex;
    while (i < _points.length - 1 &&
        (_points[i + 1].timestamp == null ||
            _points[i + 1].timestamp!.isBefore(targetTs))) {
      i++;
    }
    return i;
  }

  void _onSeek(double value) {
    if (_points.length < 2) return;
    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      _ticker?.stop();
    }
    final routeDur = _routeDuration;
    final newElapsed = Duration(
      microseconds: (routeDur.inMicroseconds * value).round(),
    );
    final idx = _indexAtProgress(value);
    setState(() {
      _accumElapsed = newElapsed;
      _currentIndex = idx;
    });
    _mapController.move(_points[idx].latLng, _mapController.camera.zoom);
    if (wasPlaying) {
      _lastTickDuration = Duration.zero;
      _ticker?.start();
    }
  }

  void _setSpeed(double s) {
    setState(() => _speedMultiplier = s);
  }

  void _fitToRoute() {
    if (_points.isEmpty) return;
    if (_points.length == 1) {
      _mapController.move(_points.first.latLng, 15);
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(
        _points.map((p) => p.latLng).toList(),
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    } catch (_) {/* ignore */}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final plate = (widget.plate ?? '').toUpperCase();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        foregroundColor: Colors.white,
        title: Text(
          'Reproduccion de Ruta - ${plate.isEmpty ? '—' : plate}',
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Centrar',
            onPressed: _fitToRoute,
            icon: const Icon(Icons.fit_screen_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppTheme.emergency, size: 56),
              const SizedBox(height: 12),
              const Text('Error al cargar la ruta',
                  style: AppTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_error!,
                  style: AppTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_points.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('La bitacora no tiene puntos de ruta',
              style: AppTheme.titleMedium, textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: [
        Expanded(child: _buildMap()),
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildMap() {
    final visiblePoints = _points
        .take(_currentIndex + 1)
        .map((p) => p.latLng)
        .toList(growable: false);
    final allPoints = _points.map((p) => p.latLng).toList(growable: false);
    final current = _points[_currentIndex];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _points.first.latLng,
        initialZoom: 15,
        minZoom: 6,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: MapsService.tileServerUrl,
          tileProvider: MapsService.tileProvider,
          userAgentPackageName: ApiConfig.appPackageName,
        ),
        // Full route in light gray
        if (allPoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: allPoints,
                color: AppTheme.border,
                strokeWidth: 4,
              ),
            ],
          ),
        // Animated polyline (bright green, thicker)
        if (visiblePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: visiblePoints,
                color: AppTheme.primary,
                strokeWidth: 6,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Start (green flag)
            Marker(
              point: _points.first.latLng,
              width: 36,
              height: 36,
              child: const Icon(Icons.flag_rounded,
                  color: AppTheme.success, size: 32),
            ),
            // End (red flag)
            Marker(
              point: _points.last.latLng,
              width: 36,
              height: 36,
              child: const Icon(Icons.flag_rounded,
                  color: AppTheme.emergency, size: 32),
            ),
            // Moving vehicle (rotating)
            Marker(
              point: current.latLng,
              width: 48,
              height: 48,
              child: Transform.rotate(
                angle: ((current.heading ?? 0) * math.pi) / 180.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final current = _points[_currentIndex];
    final progress = _routeDuration.inMicroseconds == 0
        ? 0.0
        : (_accumElapsed.inMicroseconds / _routeDuration.inMicroseconds)
            .clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.driverName != null && widget.driverName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 16, color: AppTheme.primaryDark),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.driverName!,
                          style: AppTheme.labelMedium
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Stats grid
              Row(
                children: [
                  _statCard(
                      Icons.route_rounded,
                      'Distancia',
                      '${_totalDistanceKm.toStringAsFixed(2)} km',
                      AppTheme.primary),
                  const SizedBox(width: 8),
                  _statCard(
                      Icons.timer_rounded,
                      'Tiempo',
                      _formatDuration(_totalDuration),
                      AppTheme.warning),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statCard(
                      Icons.speed_rounded,
                      'Vel. promedio',
                      '${_avgSpeedKmh.toStringAsFixed(1)} km/h',
                      AppTheme.info),
                  const SizedBox(width: 8),
                  _statCard(
                      Icons.flash_on_rounded,
                      'Vel. máxima',
                      '${_maxSpeedKmh.toStringAsFixed(1)} km/h',
                      AppTheme.emergency),
                ],
              ),
              const SizedBox(height: 12),
              // Current point info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            current.timestamp != null
                                ? DateFormat('dd/MM/yyyy HH:mm:ss')
                                    .format(current.timestamp!)
                                : 'Punto ${_currentIndex + 1}/${_points.length}',
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vel: ${current.speed?.toStringAsFixed(1) ?? "—"} km/h · Dir: ${current.heading?.toStringAsFixed(0) ?? "—"}°',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1}/${_points.length}',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Seek slider
              Slider(
                value: progress,
                onChanged: _onSeek,
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.border,
              ),
              // Controls
              Row(
                children: [
                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isPlaying ? _pause : _play,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Stop
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: IconButton(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop_rounded,
                          color: AppTheme.textSecondary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Speed selector
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _speedOptions.map((s) {
                          final selected = s == _speedMultiplier;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusRound),
                                onTap: () => _setSpeed(s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.surfaceWhite,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusRound),
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.primary
                                          : AppTheme.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${s.toInt()}x',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTheme.titleSmall.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d == Duration.zero) return '--';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROUTE POINT
// ═══════════════════════════════════════════════════════════════════════════

class _RoutePoint {
  final LatLng latLng;
  final double? speed;
  final DateTime? timestamp;
  final double? accuracy;
  final double? heading;

  _RoutePoint({
    required this.latLng,
    this.speed,
    this.timestamp,
    this.accuracy,
    this.heading,
  });

  static _RoutePoint? fromJson(Map<String, dynamic> json) {
    final lat = _num(json['lat'] ?? json['latitude']);
    final lng = _num(json['lng'] ?? json['lon'] ?? json['longitude']);
    if (lat == null || lng == null) return null;
    DateTime? ts;
    final raw = json['timestamp'];
    if (raw != null) {
      try {
        ts = DateTime.parse(raw.toString()).toLocal();
      } catch (_) {/* ignore */}
    }
    return _RoutePoint(
      latLng: LatLng(lat, lng),
      speed: _num(json['speed']),
      timestamp: ts,
      accuracy: _num(json['accuracy']),
      heading: _num(json['heading']),
    );
  }

  static double? _num(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
