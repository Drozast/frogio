// lib/features/vehicles/presentation/pages/active_trip_page.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frogio_mobile/core/services/maps_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/services/trip_tracking_service.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../bloc/vehicle_bloc.dart';

class ActiveTripPage extends StatefulWidget {
  final String vehicleLogId;
  final VehicleEntity vehicle;
  final String userId;
  final String userName;

  const ActiveTripPage({
    super.key,
    required this.vehicleLogId,
    required this.vehicle,
    required this.userId,
    required this.userName,
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  final MapController _mapController = MapController();
  final _service = TripTrackingService();

  Timer? _uiTicker;
  bool _isLoadingLog = true;
  bool _autoCenter = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadLogData();
    _startUiTicker();
    _service.addListener(_onServiceChange);
    _ensureCurrentLocation();
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _service.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() {
    if (!mounted) return;
    setState(() {});
    if (_autoCenter && _mapReady && _service.currentPosition != null) {
      try {
        _mapController.move(_service.currentPosition!, _mapController.camera.zoom);
      } catch (_) {}
    }
  }

  Future<void> _ensureCurrentLocation() async {
    if (_service.currentPosition != null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (!mounted) return;
      setState(() {});
      if (_autoCenter && _mapReady) {
        try {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('ActiveTripPage: could not get current position $e');
    }
  }

  void _startUiTicker() {
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadLogData() async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/logs/${widget.vehicleLogId}'),
      );
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final startKm = (data['start_km'] as num?)?.toDouble() ?? 0;

        if (_service.startKm != startKm && startKm > 0) {
          await _service.updateStartKm(startKm);
        }

        setState(() => _isLoadingLog = false);
      } else {
        if (mounted) setState(() => _isLoadingLog = false);
      }
    } catch (e) {
      debugPrint('Error loading log: $e');
      if (mounted) setState(() => _isLoadingLog = false);
    }
  }

  Duration get _elapsed {
    if (_service.startTime != null) {
      return DateTime.now().difference(_service.startTime!);
    }
    return Duration.zero;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  double get _avgSpeed {
    final hours = _elapsed.inSeconds / 3600.0;
    if (hours <= 0) return 0;
    return _service.totalDistanceKm / hours;
  }

  double get _calculatedEndKm => _service.startKm + _service.totalDistanceKm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Viaje Activo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingLog
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildVehicleCard()),
                SliverToBoxAdapter(child: _buildMap()),
                SliverToBoxAdapter(child: _buildStats()),
                SliverToBoxAdapter(child: _buildFinalizeButton()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildVehicleCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.vehicle.brand} ${widget.vehicle.model}',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.vehicle.plate,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.vehicle.year.toString(),
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 6),
                Text('ACTIVO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final current = _service.currentPosition;
    final route = _service.route;
    final center = current ?? (route.isNotEmpty ? route.last : const LatLng(-37.1769, -72.9386));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                onMapReady: () {
                  _mapReady = true;
                  if (_autoCenter && current != null) {
                    try { _mapController.move(current, 16); } catch (_) {}
                  }
                },
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _autoCenter) {
                    setState(() => _autoCenter = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsService.tileServerUrl,
                  tileProvider: MapsService.tileProvider,
                ),
                if (route.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(points: route, strokeWidth: 4, color: AppTheme.primary),
                  ]),
                MarkerLayer(markers: [
                  if (route.isNotEmpty)
                    Marker(
                      point: route.first,
                      width: 30, height: 30,
                      child: const Icon(Icons.trip_origin, color: Colors.green, size: 24),
                    ),
                  if (current != null)
                    Marker(
                      point: current,
                      width: 36, height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 18),
                      ),
                    ),
                ]),
              ],
            ),
            Positioned(
              bottom: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  final cur = _service.currentPosition;
                  if (cur != null) {
                    setState(() => _autoCenter = true);
                    _mapController.move(cur, 16);
                  } else {
                    _ensureCurrentLocation();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _autoCenter ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_autoCenter ? Colors.blue : Colors.black).withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _autoCenter ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _autoCenter ? Colors.white : Colors.blue,
                    size: 22,
                  ),
                ),
              ),
            ),
            if (_autoCenter)
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Siguiendo', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Estadisticas del viaje', style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  Icons.flag_rounded,
                  'Km inicial',
                  '${_service.startKm.toStringAsFixed(0)} km',
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _statTile(
                  Icons.route_rounded,
                  'Recorrido',
                  '${_service.totalDistanceKm.toStringAsFixed(2)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile(Icons.access_time_rounded, 'Tiempo', _formatDuration(_elapsed))),
              Expanded(child: _statTile(Icons.speed_rounded, 'Velocidad', '${_service.currentSpeedKmh.toStringAsFixed(1)} km/h')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile(Icons.bolt_rounded, 'Max', '${_service.maxSpeedKmh.toStringAsFixed(1)} km/h')),
              Expanded(child: _statTile(Icons.trending_up_rounded, 'Promedio', '${_avgSpeed.toStringAsFixed(1)} km/h')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value, {Color? color}) {
    final c = color ?? AppTheme.textTertiary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color != null ? c.withValues(alpha: 0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: color != null ? Border.all(color: c.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.labelSmall.copyWith(color: color ?? AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showFinalizeDialog,
          icon: const Icon(Icons.stop_circle_rounded, size: 22),
          label: const Text('DEVOLVER VEHICULO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emergency,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  void _showFinalizeDialog() {
    final observationsController = TextEditingController();
    final incidentsController = TextEditingController();
    final endKmController = TextEditingController();
    final List<File> evidence = [];

    final vehicleBloc = context.read<VehicleBloc>();
    final parentNavigator = Navigator.of(context);
    final parentMessenger = ScaffoldMessenger.of(context);

    final gpsCalculatedEndKm = _calculatedEndKm;
    final gpsDistance = _service.totalDistanceKm;
    final startKm = _service.startKm;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Devolver Vehiculo', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${widget.vehicle.brand} ${widget.vehicle.model} - ${widget.vehicle.plate}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),

                const SizedBox(height: 20),

                // GPS reference info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.straighten_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text('Km inicial registrado', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          const Spacer(),
                          Text('${startKm.toStringAsFixed(0)} km',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: AppTheme.info, size: 20),
                          const SizedBox(width: 8),
                          const Text('Distancia GPS (referencia)', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          const Spacer(),
                          Text('${gpsDistance.toStringAsFixed(2)} km',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.info)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded, color: AppTheme.textTertiary, size: 20),
                          const SizedBox(width: 8),
                          const Text('GPS sugiere km final', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          const Spacer(),
                          Text('${gpsCalculatedEndKm.toStringAsFixed(0)} km',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textTertiary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El GPS puede sumar distancia caminada. Ingresa el kilometraje real del odómetro del vehículo.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Mandatory final km input
                Text('Kilometraje final del odómetro *',
                    style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 8),
                TextField(
                  controller: endKmController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Ej: ${gpsCalculatedEndKm.toStringAsFixed(0)}',
                    suffixText: 'km',
                    prefixIcon: const Icon(Icons.flag_rounded, color: AppTheme.success),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                ),

                const SizedBox(height: 20),

                Text('Anotaciones', style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 8),
                TextField(
                  controller: observationsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Observaciones del viaje (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                ),

                const SizedBox(height: 16),

                Text('Incidentes', style: AppTheme.titleSmall.copyWith(color: AppTheme.emergency)),
                const SizedBox(height: 8),
                TextField(
                  controller: incidentsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe cualquier incidente, problema mecanico o dano (opcional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: AppTheme.surface,
                    prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppTheme.emergency),
                  ),
                ),

                const SizedBox(height: 16),

                // Photo attachments
                Row(
                  children: [
                    Text('Fotos', style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
                    const SizedBox(width: 6),
                    Text('(opcional)', style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary)),
                  ],
                ),
                const SizedBox(height: 8),

                if (evidence.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: evidence.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(evidence[i], width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -4, right: -4,
                            child: GestureDetector(
                              onTap: () => setSheet(() => evidence.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (evidence.isNotEmpty) const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: evidence.length >= 5 ? null : () async {
                      final source = await showModalBottomSheet<ImageSource>(
                        context: ctx,
                        builder: (c) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded),
                                title: const Text('Camara'),
                                onTap: () => Navigator.pop(c, ImageSource.camera),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library_rounded),
                                title: const Text('Galeria'),
                                onTap: () => Navigator.pop(c, ImageSource.gallery),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (source != null) {
                        final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
                        if (picked != null) {
                          File f = File(picked.path);
                          try {
                            final dir = await getTemporaryDirectory();
                            final target = '${dir.path}/veh_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            final compressed = await FlutterImageCompress.compressAndGetFile(
                              f.absolute.path, target, quality: 70, minWidth: 1280, minHeight: 1280,
                            );
                            if (compressed != null) f = File(compressed.path);
                          } catch (_) {}
                          setSheet(() => evidence.add(f));
                        }
                      }
                    },
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text('Adjuntar foto (${evidence.length}/5)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final endKmRaw = endKmController.text.trim();
                      final endKm = double.tryParse(endKmRaw.replaceAll(',', '.'));
                      if (endKm == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa el kilometraje final del odómetro'),
                            backgroundColor: AppTheme.emergency,
                          ),
                        );
                        return;
                      }
                      if (endKm < startKm) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                                'El km final ($endKm) no puede ser menor al inicial (${startKm.toStringAsFixed(0)})'),
                            backgroundColor: AppTheme.emergency,
                          ),
                        );
                        return;
                      }

                      final obs = StringBuffer();
                      if (observationsController.text.trim().isNotEmpty) {
                        obs.writeln('Anotaciones: ${observationsController.text.trim()}');
                      }
                      if (incidentsController.text.trim().isNotEmpty) {
                        obs.writeln('Incidentes: ${incidentsController.text.trim()}');
                      }
                      // Always log GPS distance for traceability
                      obs.writeln(
                          'Distancia GPS: ${gpsDistance.toStringAsFixed(2)} km · Km real: ${(endKm - startKm).toStringAsFixed(2)} km');

                      Navigator.pop(ctx);

                      await TripTrackingService().stopTrip();

                      try {
                        final client = di.sl<AuthHttpClient>();
                        final res = await client.patch(
                          Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/logs/${widget.vehicleLogId}/end'),
                          body: json.encode({
                            'endKm': endKm,
                            'gpsDistanceKm': gpsDistance,
                            'observations': obs.toString().trim().isEmpty ? null : obs.toString().trim(),
                          }),
                        );
                        if (res.statusCode != 200) {
                          final err = json.decode(res.body);
                          parentMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${err['error'] ?? 'No se pudo finalizar'}'),
                              backgroundColor: AppTheme.emergency,
                            ),
                          );
                          return;
                        }

                        // Upload evidence photos (non-blocking: trip already ended)
                        if (evidence.isNotEmpty) {
                          _uploadEvidence(widget.vehicleLogId, evidence);
                        }

                        vehicleBloc.add(EndVehicleUsageEvent(
                          logId: widget.vehicleLogId,
                          endKm: endKm,
                          observations: obs.toString().trim().isEmpty ? null : obs.toString().trim(),
                        ));

                        parentMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Vehiculo devuelto exitosamente'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                        parentNavigator.popUntil((route) => route.isFirst);
                      } catch (e) {
                        parentMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error de conexion: $e'),
                            backgroundColor: AppTheme.emergency,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Confirmar devolucion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Upload evidence photos to the backend as vehicle_log attachments.
  Future<void> _uploadEvidence(String logId, List<File> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      for (final f in files) {
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.activeBaseUrl}/api/files/upload'),
        );
        req.headers['Authorization'] = 'Bearer $token';
        req.fields['entityType'] = 'vehicle_log';
        req.fields['entityId'] = logId;
        req.files.add(await http.MultipartFile.fromPath('file', f.path));
        await req.send();
      }
    } catch (e) {
      debugPrint('Error uploading evidence: $e');
    }
  }
}
