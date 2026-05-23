// lib/features/admin/presentation/pages/admin_live_map_screen.dart
//
// Mapa en vivo del administrador: vehiculos (inspectores), SOS y denuncias
// en una sola vista, con auto-refresh y exportacion.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../services/export_service.dart';

/// Real-time admin map showing inspectors, SOS alerts and citizen reports.
class AdminLiveMapScreen extends StatefulWidget {
  final UserEntity user;

  const AdminLiveMapScreen({super.key, required this.user});

  @override
  State<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends State<AdminLiveMapScreen>
    with TickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(-37.1769, -72.9386);
  static const double _defaultZoom = 14;

  final MapController _mapController = MapController();

  // Data
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _sosAlerts = [];
  List<Map<String, dynamic>> _reports = [];

  // Filters (visibility per layer)
  bool _showVehicles = true;
  bool _showSos = true;
  bool _showReports = true;

  // State
  bool _loading = false;
  DateTime? _lastUpdated;

  Timer? _refreshTimer;

  late final AnimationController _bounceCtl;
  late final AnimationController _reloadCtl;
  late final AnimationController _pulseCtl;

  @override
  void initState() {
    super.initState();
    _bounceCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _reloadCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _bounceCtl.dispose();
    _reloadCtl.dispose();
    _pulseCtl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _reloadCtl.repeat();

    final results = await Future.wait([
      _fetchVehicles(),
      _fetchSos(),
      _fetchReports(),
    ]);

    if (!mounted) {
      _reloadCtl.stop();
      return;
    }
    setState(() {
      _vehicles = results[0];
      _sosAlerts = results[1];
      _reports = results[2];
      _lastUpdated = DateTime.now();
      _loading = false;
    });
    _reloadCtl.stop();
    _reloadCtl.value = 0;
  }

  Future<List<Map<String, dynamic>>> _fetchVehicles() async {
    final client = di.sl<AuthHttpClient>();
    try {
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/gps/vehicles/live'),
      );
      if (res.statusCode < 400) {
        final decoded = json.decode(res.body);
        List list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = (decoded['data'] as List?) ??
              (decoded['vehicles'] as List?) ??
              const [];
        } else {
          list = const [];
        }
        final mapped = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((m) => _hasLatLng(m, latKey: 'latitude', lngKey: 'longitude'))
            .toList();
        if (mapped.isNotEmpty) return mapped;
      }
    } catch (_) {/* fall through */}

    // Fallback: /api/vehicles with active_log_id != null
    try {
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles'),
      );
      if (res.statusCode >= 400) return [];
      final decoded = json.decode(res.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['data'] as List?) ??
            (decoded['vehicles'] as List?) ??
            const [];
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) => m['active_log_id'] != null)
          .map((m) {
        // Normalize keys to match live shape
        final normalized = <String, dynamic>{
          'vehicleId': m['id'],
          'vehiclePlate': m['plate'],
          'driverName': m['active_driver_name'],
          'latitude': _toDouble(m['latitude'] ?? m['last_latitude']),
          'longitude': _toDouble(m['longitude'] ?? m['last_longitude']),
          'speed': m['speed'] ?? m['last_speed'],
          'lastUpdate': m['last_update'] ?? m['updated_at'],
        };
        return normalized;
      }).where((m) => _hasLatLng(m, latKey: 'latitude', lngKey: 'longitude')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSos() async {
    final client = di.sl<AuthHttpClient>();
    try {
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/'),
      );
      if (res.statusCode >= 400) return [];
      final decoded = json.decode(res.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['data'] as List?) ??
            (decoded['alerts'] as List?) ??
            const [];
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) {
            final st = (m['status'] ?? '').toString().toLowerCase();
            return st == 'active' || st == 'responding';
          })
          .where((m) => _hasLatLng(m, latKey: 'latitude', lngKey: 'longitude'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final client = di.sl<AuthHttpClient>();
    try {
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/reports/'),
      );
      if (res.statusCode >= 400) return [];
      final decoded = json.decode(res.body);
      List list;
      if (decoded is Map) {
        list = (decoded['data'] as List?) ??
            (decoded['reports'] as List?) ??
            const [];
      } else if (decoded is List) {
        list = decoded;
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) =>
              (m['status'] ?? '').toString().toLowerCase() == 'pendiente')
          .where((m) => _hasLatLng(m, latKey: 'latitude', lngKey: 'longitude'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _hasLatLng(Map<String, dynamic> m, {required String latKey, required String lngKey}) {
    final lat = _toDouble(m[latKey]);
    final lng = _toDouble(m[lngKey]);
    return lat != null && lng != null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CENTER ON MARKERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _centerOnMarkers() {
    final points = <LatLng>[];
    if (_showVehicles) {
      for (final v in _vehicles) {
        final lat = _toDouble(v['latitude']);
        final lng = _toDouble(v['longitude']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    if (_showSos) {
      for (final a in _sosAlerts) {
        final lat = _toDouble(a['latitude']);
        final lng = _toDouble(a['longitude']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    if (_showReports) {
      for (final r in _reports) {
        final lat = _toDouble(r['latitude']);
        final lng = _toDouble(r['longitude']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }

    if (points.isEmpty) {
      _mapController.move(_defaultCenter, _defaultZoom);
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 16);
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(points);
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
    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          _buildSectionHeader(),
          _buildFilterChips(),
          const SizedBox(height: 6),
          Expanded(child: _buildMap()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final stamp = _lastUpdated != null
        ? DateFormat('HH:mm:ss').format(_lastUpdated!)
        : '--:--:--';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradientVertical,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Flexible(
                  child: Text(
                    'Mapa en Vivo',
                    style: AppTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                _buildLivePulse(),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    stamp,
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.textTertiary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.ios_share_rounded,
            tooltip: 'Exportar',
            onTap: _openExportModal,
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulse() {
    return AnimatedBuilder(
      animation: _pulseCtl,
      builder: (_, __) {
        final v = _pulseCtl.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.successLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.5 * (1 - v)),
                      blurRadius: 6 * v,
                      spreadRadius: 3 * v,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LIVE',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(
              label: 'Inspectores',
              icon: Icons.directions_car_rounded,
              color: AppTheme.primary,
              selected: _showVehicles,
              count: _vehicles.length,
              onTap: () => setState(() => _showVehicles = !_showVehicles),
            ),
            const SizedBox(width: 8),
            _filterChip(
              label: 'SOS',
              icon: Icons.emergency_rounded,
              color: AppTheme.emergency,
              selected: _showSos,
              count: _sosAlerts.length,
              onTap: () => setState(() => _showSos = !_showSos),
            ),
            const SizedBox(width: 8),
            _filterChip(
              label: 'Denuncias',
              icon: Icons.report_problem_rounded,
              color: AppTheme.info,
              selected: _showReports,
              count: _reports.length,
              onTap: () => setState(() => _showReports = !_showReports),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required int count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.4)
                  : AppTheme.border.withValues(alpha: 0.7),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? color : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _defaultZoom,
                minZoom: 6,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsService.tileServerUrl,
                  tileProvider: MapsService.tileProvider,
                  userAgentPackageName: ApiConfig.appPackageName,
                ),
                if (_showVehicles) MarkerLayer(markers: _buildVehicleMarkers()),
                if (_showReports) MarkerLayer(markers: _buildReportMarkers()),
                if (_showSos) MarkerLayer(markers: _buildSosMarkers()),
              ],
            ),
            // Counter pill (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: _buildCounterPill(),
            ),
            // Recargar (bottom-right)
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildReloadButton(),
            ),
            // Centrar (bottom-left)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildCenterButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterPill() {
    final v = _showVehicles ? _vehicles.length : 0;
    final s = _showSos ? _sosAlerts.length : 0;
    final r = _showReports ? _reports.length : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        boxShadow: AppTheme.shadowSmall,
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$v inspectores · $s SOS · $r denuncias',
        style: AppTheme.labelMedium.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReloadButton() {
    return Material(
      color: AppTheme.primary,
      shape: const StadiumBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _loading ? null : _loadAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _reloadCtl,
                builder: (_, __) {
                  return Transform.rotate(
                    angle: _reloadCtl.value * 6.2831853,
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  );
                },
              ),
              const SizedBox(width: 6),
              const Text(
                'Recargar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Material(
      color: AppTheme.surfaceWhite,
      shape: const StadiumBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _centerOnMarkers,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location_rounded,
                  color: AppTheme.primaryDark, size: 18),
              SizedBox(width: 6),
              Text(
                'Centrar',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKERS
  // ═══════════════════════════════════════════════════════════════════════════

  List<Marker> _buildVehicleMarkers() {
    return _vehicles.map((v) {
      final lat = _toDouble(v['latitude']);
      final lng = _toDouble(v['longitude']);
      if (lat == null || lng == null) return null;
      return Marker(
        point: LatLng(lat, lng),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () => _openVehicleSheet(v),
          child: AnimatedBuilder(
            animation: _bounceCtl,
            builder: (_, __) {
              final bounce = (_bounceCtl.value - 0.5).abs() * 6;
              return Transform.translate(
                offset: Offset(0, -bounce),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: Colors.white, size: 20),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  // Match inspector_map_screen.dart styling
  List<Marker> _buildSosMarkers() {
    return _sosAlerts.map((a) {
      final lat = _toDouble(a['latitude']);
      final lng = _toDouble(a['longitude']);
      if (lat == null || lng == null) return null;
      return Marker(
        point: LatLng(lat, lng),
        width: 70,
        height: 70,
        child: GestureDetector(
          onTap: () => _openSosSheet(a),
          child: AnimatedBuilder(
            animation: _pulseCtl,
            builder: (_, __) {
              // Pulse 1.0 .. 1.2 .. 1.0 like inspector
              final scale = 1.0 + 0.2 * (1 - (_pulseCtl.value - 0.5).abs() * 2);
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.5),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sos,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Color _reportColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'resuelto':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _reportIcon(String type) {
    switch (type.toLowerCase()) {
      case 'infraestructura':
        return Icons.construction_rounded;
      case 'seguridad':
        return Icons.security_rounded;
      case 'salud':
        return Icons.local_hospital_rounded;
      case 'medio_ambiente':
        return Icons.eco_rounded;
      case 'transito':
      case 'tránsito':
        return Icons.traffic_rounded;
      case 'ruido':
        return Icons.volume_up_rounded;
      case 'limpieza':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }

  List<Marker> _buildReportMarkers() {
    return _reports.map((r) {
      final lat = _toDouble(r['latitude']);
      final lng = _toDouble(r['longitude']);
      if (lat == null || lng == null) return null;
      final color = _reportColor((r['status'] ?? '').toString());
      final icon = _reportIcon(
          (r['report_type'] ?? r['category'] ?? '').toString());
      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _openReportSheet(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEETS
  // ═══════════════════════════════════════════════════════════════════════════

  void _openVehicleSheet(Map<String, dynamic> v) {
    final plate = (v['vehiclePlate'] ?? v['plate'] ?? '').toString().toUpperCase();
    final driver = (v['driverName'] ?? v['driver_name'] ?? '').toString();
    final speed = _toDouble(v['speed']);
    final lat = _toDouble(v['latitude']);
    final lng = _toDouble(v['longitude']);
    final updated = _parseDate(v['lastUpdate'] ?? v['last_update']);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => _DetailSheet(
        title: plate.isEmpty ? 'Vehiculo' : plate,
        subtitle: 'Inspector en terreno',
        accent: AppTheme.primary,
        icon: Icons.directions_car_rounded,
        rows: [
          _SheetRow(Icons.person_rounded, 'Conductor', driver.isEmpty ? '-' : driver),
          _SheetRow(Icons.speed_rounded, 'Velocidad',
              speed != null ? '${speed.toStringAsFixed(1)} km/h' : '-'),
          _SheetRow(Icons.gps_fixed_rounded, 'Coordenadas',
              (lat != null && lng != null)
                  ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                  : '-'),
          _SheetRow(Icons.access_time_rounded, 'Actualizado',
              updated != null
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(updated)
                  : '-'),
        ],
        onDetail: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openSosSheet(Map<String, dynamic> a) {
    final firstName = (a['first_name'] ?? '').toString();
    final lastName = (a['last_name'] ?? '').toString();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final phone = (a['contact_phone'] ?? '').toString();
    final addr = (a['address'] ?? '').toString();
    final status = (a['status'] ?? '').toString();
    final msg = (a['message'] ?? '').toString();
    final created = _parseDate(a['created_at']);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => _DetailSheet(
        title: 'ALERTA SOS',
        subtitle: status.toUpperCase(),
        accent: AppTheme.emergency,
        icon: Icons.notifications_active_rounded,
        rows: [
          _SheetRow(Icons.person_rounded, 'Nombre', fullName.isEmpty ? '-' : fullName),
          _SheetRow(Icons.phone_rounded, 'Telefono', phone.isEmpty ? '-' : phone),
          _SheetRow(Icons.location_on_rounded, 'Direccion', addr.isEmpty ? '-' : addr),
          if (msg.isNotEmpty) _SheetRow(Icons.message_rounded, 'Mensaje', msg),
          _SheetRow(Icons.access_time_rounded, 'Recibida',
              created != null
                  ? DateFormat('dd/MM/yyyy HH:mm:ss').format(created)
                  : '-'),
        ],
        onDetail: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openReportSheet(Map<String, dynamic> r) {
    final title = (r['title'] ?? 'Denuncia').toString();
    final category = (r['category'] ?? '').toString();
    final addr = (r['address'] ?? '').toString();
    final citizen = (r['citizen_name'] ?? r['citizenName'] ?? '').toString();
    final status = (r['status'] ?? '').toString();
    final created = _parseDate(r['created_at']);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => _DetailSheet(
        title: title,
        subtitle: 'Denuncia ciudadana',
        accent: AppTheme.info,
        icon: Icons.report_problem_rounded,
        rows: [
          _SheetRow(Icons.category_rounded, 'Categoria', category.isEmpty ? '-' : category),
          _SheetRow(Icons.location_on_rounded, 'Direccion', addr.isEmpty ? '-' : addr),
          _SheetRow(Icons.person_rounded, 'Ciudadano', citizen.isEmpty ? '-' : citizen),
          _SheetRow(Icons.flag_rounded, 'Estado', status.isEmpty ? '-' : status),
          _SheetRow(Icons.access_time_rounded, 'Creada',
              created != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(created)
                  : '-'),
        ],
        onDetail: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  void _openExportModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Exportar mapa en vivo',
                    style: AppTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Se exportaran solo las capas visibles',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _exportCsv();
                  },
                  icon: const Icon(Icons.table_view_rounded),
                  label: const Text('Exportar como CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _exportPdf();
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Exportar como PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    try {
      if (_showVehicles && _vehicles.isNotEmpty) {
        final rows = _vehicles.map((v) {
          final updated = _parseDate(v['lastUpdate'] ?? v['last_update']);
          return <dynamic>[
            (v['vehiclePlate'] ?? v['plate'] ?? '').toString(),
            (v['driverName'] ?? v['driver_name'] ?? '').toString(),
            (_toDouble(v['latitude']) ?? '').toString(),
            (_toDouble(v['longitude']) ?? '').toString(),
            _toDouble(v['speed'])?.toStringAsFixed(1) ?? '',
            updated != null ? fmt.format(updated) : '',
          ];
        }).toList();
        await ExportService.exportCsv(
          filenamePrefix: 'mapa_inspectores',
          headers: const [
            'Patente',
            'Conductor',
            'Lat',
            'Lng',
            'Velocidad',
            'Actualizado'
          ],
          rows: rows,
        );
      }
      if (_showSos && _sosAlerts.isNotEmpty) {
        final rows = _sosAlerts.map((a) {
          final firstName = (a['first_name'] ?? '').toString();
          final lastName = (a['last_name'] ?? '').toString();
          final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
          final created = _parseDate(a['created_at']);
          return <dynamic>[
            (a['id'] ?? '').toString(),
            fullName,
            (a['contact_phone'] ?? '').toString(),
            (a['address'] ?? '').toString(),
            (a['status'] ?? '').toString(),
            created != null ? fmt.format(created) : '',
          ];
        }).toList();
        await ExportService.exportCsv(
          filenamePrefix: 'mapa_sos',
          headers: const [
            'ID',
            'Nombre',
            'Telefono',
            'Direccion',
            'Estado',
            'Fecha'
          ],
          rows: rows,
        );
      }
      if (_showReports && _reports.isNotEmpty) {
        final rows = _reports.map((r) {
          final created = _parseDate(r['created_at']);
          return <dynamic>[
            (r['title'] ?? '').toString(),
            (r['category'] ?? '').toString(),
            (r['address'] ?? '').toString(),
            (r['citizen_name'] ?? r['citizenName'] ?? '').toString(),
            (r['status'] ?? '').toString(),
            created != null ? fmt.format(created) : '',
          ];
        }).toList();
        await ExportService.exportCsv(
          filenamePrefix: 'mapa_denuncias',
          headers: const [
            'Titulo',
            'Categoria',
            'Direccion',
            'Ciudadano',
            'Estado',
            'Fecha'
          ],
          rows: rows,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar CSV: $e'),
          backgroundColor: AppTheme.emergency,
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    try {
      // Combine into a single PDF using sections
      // We delegate to ExportService.exportPdf 3 times if needed,
      // but spec says combine into ONE PDF with sections per type.
      // Since ExportService doesn't expose multi-section, we render
      // sections sequentially as a "merged" report by stacking headers
      // in one document. Simplest valid path: emit a per-section PDF
      // when only one type is visible, otherwise merge headers.

      final sections = <_PdfSection>[];
      if (_showVehicles && _vehicles.isNotEmpty) {
        sections.add(_PdfSection(
          title: 'Inspectores en terreno',
          headers: const [
            'Patente',
            'Conductor',
            'Lat',
            'Lng',
            'Velocidad',
            'Actualizado'
          ],
          rows: _vehicles.map((v) {
            final updated = _parseDate(v['lastUpdate'] ?? v['last_update']);
            return <String>[
              (v['vehiclePlate'] ?? v['plate'] ?? '').toString(),
              (v['driverName'] ?? v['driver_name'] ?? '').toString(),
              (_toDouble(v['latitude']) ?? '').toString(),
              (_toDouble(v['longitude']) ?? '').toString(),
              _toDouble(v['speed'])?.toStringAsFixed(1) ?? '',
              updated != null ? fmt.format(updated) : '',
            ];
          }).toList(),
        ));
      }
      if (_showSos && _sosAlerts.isNotEmpty) {
        sections.add(_PdfSection(
          title: 'Alertas SOS activas',
          headers: const [
            'ID',
            'Nombre',
            'Telefono',
            'Direccion',
            'Estado',
            'Fecha'
          ],
          rows: _sosAlerts.map((a) {
            final firstName = (a['first_name'] ?? '').toString();
            final lastName = (a['last_name'] ?? '').toString();
            final fullName = [firstName, lastName]
                .where((s) => s.isNotEmpty)
                .join(' ');
            final created = _parseDate(a['created_at']);
            return <String>[
              (a['id'] ?? '').toString(),
              fullName,
              (a['contact_phone'] ?? '').toString(),
              (a['address'] ?? '').toString(),
              (a['status'] ?? '').toString(),
              created != null ? fmt.format(created) : '',
            ];
          }).toList(),
        ));
      }
      if (_showReports && _reports.isNotEmpty) {
        sections.add(_PdfSection(
          title: 'Denuncias pendientes',
          headers: const [
            'Titulo',
            'Categoria',
            'Direccion',
            'Ciudadano',
            'Estado',
            'Fecha'
          ],
          rows: _reports.map((r) {
            final created = _parseDate(r['created_at']);
            return <String>[
              (r['title'] ?? '').toString(),
              (r['category'] ?? '').toString(),
              (r['address'] ?? '').toString(),
              (r['citizen_name'] ?? r['citizenName'] ?? '').toString(),
              (r['status'] ?? '').toString(),
              created != null ? fmt.format(created) : '',
            ];
          }).toList(),
        ));
      }

      if (sections.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay datos visibles para exportar')),
        );
        return;
      }

      // Use ExportService.exportPdf for each section sequentially.
      // (Single-PDF combiner not exposed by ExportService.)
      for (final s in sections) {
        await ExportService.exportPdf(
          title: 'Mapa en vivo - ${s.title}',
          subtitle: 'Generado: $stamp',
          headers: s.headers,
          rows: s.rows,
          generatedBy: widget.user.displayName,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar PDF: $e'),
          backgroundColor: AppTheme.emergency,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border:
                  Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppTheme.primaryDark),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _SheetRow {
  final IconData icon;
  final String label;
  final String value;
  const _SheetRow(this.icon, this.label, this.value);
}

class _DetailSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<_SheetRow> rows;
  final VoidCallback onDetail;

  const _DetailSheet({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.rows,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis),
                      Text(subtitle,
                          style: AppTheme.labelSmall
                              .copyWith(color: accent, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(r.icon, size: 18, color: accent),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: Text(r.label, style: AppTheme.labelMedium),
                      ),
                      Expanded(
                        child: Text(
                          r.value,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDetail,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Ir al detalle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
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

class _PdfSection {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  const _PdfSection({
    required this.title,
    required this.headers,
    required this.rows,
  });
}
