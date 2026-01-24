import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';
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
  final List<TripStop> _stops = [];
  final _uuid = const Uuid();

  Timer? _updateTimer;
  DateTime _startTime = DateTime.now();
  double _totalDistance = 0.0;
  Position? _currentPosition;
  bool _isTracking = false;
  TripStop? _activeStop;

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

                  // Close confirmation sheet now
                  Navigator.pop(context);

                  // Capture references before async gaps to avoid using context later
                  final vehicleBloc = context.read<VehicleBloc>();
                  final navigator = Navigator.of(context);

                  // Stop GPS tracking
                  await _gpsService.stopTracking();
                  _updateTimer?.cancel();

                  // Convert route points to LocationPoint entities
                  final routePoints = _routePoints.map((point) {
                    return LocationPoint(
                      latitude: point.latitude,
                      longitude: point.longitude,
                      timestamp: DateTime.now(), // Simplified timestamp
                    );
                  }).toList();

                  // Dispatch event without using context post-await
                  vehicleBloc.add(
                    EndVehicleUsageEvent(
                      logId: widget.vehicleLogId,
                      endKm: endKm,
                      observations: observationsController.text.isNotEmpty
                          ? observationsController.text
                          : null,
                      route: routePoints,
                      stops: _stops,
                    ),
                  );

                  // Navigate back using captured navigator
                  navigator.popUntil((route) => route.isFirst);
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

  void _showStopDialog() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando ubicación GPS...')),
      );
      return;
    }

    StopReason? selectedReason;
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Row(
                children: [
                  const Icon(Icons.pause_circle, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Registrar Parada',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Motivo de la parada:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StopReason.values.map((reason) {
                  final isSelected = selectedReason == reason;
                  return ChoiceChip(
                    avatar: Icon(
                      reason.icon,
                      size: 18,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    label: Text(reason.displayName),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (selected) {
                      setModalState(() {
                        selectedReason = selected ? reason : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detalles (opcional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          final stop = TripStop(
                            id: _uuid.v4(),
                            latitude: _currentPosition!.latitude,
                            longitude: _currentPosition!.longitude,
                            startTime: DateTime.now(),
                            reason: selectedReason!,
                            details: detailsController.text.isNotEmpty
                                ? detailsController.text
                                : null,
                          );
                          setState(() {
                            _activeStop = stop;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Parada iniciada: ${selectedReason!.displayName}',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Parada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _endStop() {
    if (_activeStop == null) return;

    final completedStop = _activeStop!.copyWith(
      endTime: DateTime.now(),
    );

    setState(() {
      _stops.add(completedStop);
      _activeStop = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Parada finalizada: ${completedStop.reason.displayName} (${_formatDuration(completedStop.duration!)})',
        ),
        backgroundColor: Colors.green,
      ),
    );
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
                  : const LatLng(-37.174650, -72.936815), // Municipalidad de Santa Juana
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
                            Icons.pause_circle,
                            '${_stops.length}',
                            'Paradas',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Active stop indicator
                      if (_activeStop != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(_activeStop!.reason.icon, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Parada: ${_activeStop!.reason.displayName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      'Duración: ${_formatDuration(DateTime.now().difference(_activeStop!.startTime))}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _endStop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text('Continuar'),
                              ),
                            ],
                          ),
                        ),

                      // Action Buttons
                      Row(
                        children: [
                          // Stop/Pause Button
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _activeStop != null ? null : _showStopDialog,
                                icon: const Icon(Icons.pause),
                                label: const Text('Parada'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // End Trip Button
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _activeStop != null ? null : _stopTracking,
                                icon: const Icon(Icons.stop),
                                label: const Text('Finalizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
