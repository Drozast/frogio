import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/gps_tracking_service.dart';
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
  final GpsTrackingService _gpsService = GpsTrackingService();
  final MapController _mapController = MapController();
  final List<LatLng> _routePoints = [];

  Timer? _updateTimer;
  DateTime _startTime = DateTime.now();
  double _totalDistance = 0.0;
  Position? _currentPosition;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    // Get API URL from config and token from storage
    final apiUrl = ApiConfig.activeBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    if (accessToken.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No hay sesión activa'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final success = await _gpsService.startTracking(
      vehicleId: widget.vehicle.id,
      vehicleLogId: widget.vehicleLogId,
      accessToken: accessToken,
      apiUrl: apiUrl,
    );

    if (success) {
      setState(() => _isTracking = true);
      _startTime = DateTime.now();

      // Start UI update timer
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _updateUI();
      });

      // Get initial position
      _updateUI();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar el tracking GPS'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUI() async {
    final position = await _gpsService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        // Add to route if moved significantly
        if (_currentPosition != null) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          if (distance > 10) {
            _routePoints.add(LatLng(position.latitude, position.longitude));
            _totalDistance += distance / 1000; // Convert to km
          }
        } else {
          _routePoints.add(LatLng(position.latitude, position.longitude));
        }
        _currentPosition = position;
      });

      // Center map on current position
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  Future<void> _stopTracking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Viaje'),
        content: const Text(
          '¿Está seguro de finalizar el viaje? Se detendrá el registro GPS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showEndTripDialog();
    }
  }

  void _showEndTripDialog() {
    final endKmController = TextEditingController();
    final observationsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finalizar Viaje',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: endKmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometraje Final',
                prefixIcon: Icon(Icons.speed),
                suffixText: 'km',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: observationsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final endKm = double.tryParse(endKmController.text);
                  if (endKm == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingrese un kilometraje válido'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  // Stop GPS tracking
                  await _gpsService.stopTracking();
                  _updateTimer?.cancel();

                  // End vehicle usage
                  if (mounted) {
                    context.read<VehicleBloc>().add(
                          EndVehicleUsageEvent(
                            logId: widget.vehicleLogId,
                            endKm: endKm,
                            observations: observationsController.text.isNotEmpty
                                ? observationsController.text
                                : null,
                          ),
                        );

                    // Navigate back
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: const Text('Confirmar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
    final duration = DateTime.now().difference(_startTime);

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(-37.1738, -72.4249), // Santa Juana - Yungay 125
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.frogio.santa_juana',
              ),
              // Route polyline
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Current position marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top Info Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Tracking indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isTracking ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vehicle.plate.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.vehicle.brand} ${widget.vehicle.model}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Stats Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.timer,
                            _formatDuration(duration),
                            'Tiempo',
                          ),
                          _buildStatItem(
                            Icons.straighten,
                            '${_totalDistance.toStringAsFixed(1)} km',
                            'Distancia',
                          ),
                          _buildStatItem(
                            Icons.speed,
                            _currentPosition?.speed != null
                                ? '${(_currentPosition!.speed * 3.6).toStringAsFixed(0)} km/h'
                                : '0 km/h',
                            'Velocidad',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stop Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _stopTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.stop, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Finalizar Viaje',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
