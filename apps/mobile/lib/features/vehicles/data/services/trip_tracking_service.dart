// lib/features/vehicles/data/services/trip_tracking_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../di/injection_container_api.dart' as di;

/// Singleton service that tracks GPS while a vehicle trip is active.
/// Periodically captures location + speed and sends batches to the backend.
class TripTrackingService {
  static final TripTrackingService _instance = TripTrackingService._internal();
  factory TripTrackingService() => _instance;
  TripTrackingService._internal();

  static const _activeLogKey = 'active_vehicle_log_id';
  static const _activeVehiclePlateKey = 'active_vehicle_plate';
  static const _startTimeKey = 'active_vehicle_start_time';
  static const _startKmKey = 'active_vehicle_start_km';
  static const _distanceKey = 'active_vehicle_distance_km';
  static const _maxSpeedKey = 'active_vehicle_max_speed';
  static const _routeKey = 'active_vehicle_route';

  StreamSubscription<Position>? _positionSub;
  Timer? _uploadTimer;
  final List<Map<String, dynamic>> _pendingPoints = [];

  String? _activeLogId;
  String? _activePlate;
  DateTime? _startTime;
  double _maxSpeed = 0;
  double _startKm = 0;
  double _totalDistanceKm = 0;
  double _currentSpeedKmh = 0;
  LatLng? _currentPosition;
  final List<LatLng> _route = [];

  // Listeners
  final _listeners = <VoidCallback>{};
  void addListener(VoidCallback l) => _listeners.add(l);
  void removeListener(VoidCallback l) => _listeners.remove(l);
  void _notify() {
    for (final l in _listeners.toList()) {
      try { l(); } catch (_) {}
    }
  }

  bool get isActive => _activeLogId != null;
  String? get activeLogId => _activeLogId;
  String? get activePlate => _activePlate;
  DateTime? get startTime => _startTime;
  double get maxSpeedKmh => _maxSpeed;
  double get startKm => _startKm;
  double get totalDistanceKm => _totalDistanceKm;
  double get currentSpeedKmh => _currentSpeedKmh;
  LatLng? get currentPosition => _currentPosition;
  List<LatLng> get route => List.unmodifiable(_route);
  int get pointsCount => _pendingPoints.length;

  /// Called on app startup to restore active trip from prefs
  Future<void> restoreActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeLogKey);
    if (id != null && id.isNotEmpty) {
      _activeLogId = id;
      _activePlate = prefs.getString(_activeVehiclePlateKey);
      final ts = prefs.getString(_startTimeKey);
      if (ts != null) _startTime = DateTime.tryParse(ts);
      _startKm = prefs.getDouble(_startKmKey) ?? 0;
      _totalDistanceKm = prefs.getDouble(_distanceKey) ?? 0;
      _maxSpeed = prefs.getDouble(_maxSpeedKey) ?? 0;

      // Restore route
      final routeJson = prefs.getString(_routeKey);
      if (routeJson != null) {
        try {
          final list = json.decode(routeJson) as List;
          _route.clear();
          for (final p in list) {
            if (p is Map) {
              final lat = (p['lat'] as num?)?.toDouble();
              final lng = (p['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                _route.add(LatLng(lat, lng));
              }
            }
          }
          if (_route.isNotEmpty) _currentPosition = _route.last;
        } catch (_) {}
      }

      debugPrint('TripTracking: restored active trip $_activeLogId km=$_startKm dist=$_totalDistanceKm pts=${_route.length}');
      _startTracking();
      _notify();
    }
  }

  /// Start tracking a new trip
  Future<void> startTrip({
    required String logId,
    required String plate,
    double startKm = 0,
  }) async {
    _activeLogId = logId;
    _activePlate = plate;
    _startTime = DateTime.now();
    _pendingPoints.clear();
    _route.clear();
    _maxSpeed = 0;
    _totalDistanceKm = 0;
    _currentSpeedKmh = 0;
    _currentPosition = null;
    _startKm = startKm;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeLogKey, logId);
    await prefs.setString(_activeVehiclePlateKey, plate);
    await prefs.setString(_startTimeKey, _startTime!.toIso8601String());
    await prefs.setDouble(_startKmKey, startKm);
    await prefs.setDouble(_distanceKey, 0);
    await prefs.setDouble(_maxSpeedKey, 0);
    await prefs.remove(_routeKey);

    _startTracking();
    _notify();
    debugPrint('TripTracking: started trip $logId');
  }

  /// Stop tracking and clear state
  Future<void> stopTrip() async {
    _positionSub?.cancel();
    _positionSub = null;
    _uploadTimer?.cancel();
    _uploadTimer = null;

    // Flush remaining points
    if (_pendingPoints.isNotEmpty && _activeLogId != null) {
      await _uploadPoints();
    }

    _activeLogId = null;
    _activePlate = null;
    _startTime = null;
    _maxSpeed = 0;
    _startKm = 0;
    _totalDistanceKm = 0;
    _currentSpeedKmh = 0;
    _currentPosition = null;
    _route.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeLogKey);
    await prefs.remove(_activeVehiclePlateKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_startKmKey);
    await prefs.remove(_distanceKey);
    await prefs.remove(_maxSpeedKey);
    await prefs.remove(_routeKey);

    _notify();
    debugPrint('TripTracking: stopped');
  }

  /// Update start km (e.g., after fetching from backend)
  Future<void> updateStartKm(double km) async {
    _startKm = km;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_startKmKey, km);
    _notify();
  }

  void _startTracking() {
    // Request high-accuracy GPS
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen(_onPosition, onError: (e) => debugPrint('GPS error: $e'));

    // Upload batch every 30 seconds
    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) => _uploadPoints());

    // Persist state every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (t) async {
      if (_activeLogId == null) {
        t.cancel();
        return;
      }
      await _persistState();
    });
  }

  void _onPosition(Position pos) {
    // Convert speed m/s to km/h
    final speedKmh = (pos.speed * 3.6).clamp(0.0, 300.0);
    _currentSpeedKmh = speedKmh;
    if (speedKmh > _maxSpeed) _maxSpeed = speedKmh;

    final newPoint = LatLng(pos.latitude, pos.longitude);
    _currentPosition = newPoint;

    // Append to route and update distance if moved enough
    if (_route.isNotEmpty) {
      final last = _route.last;
      final delta = Geolocator.distanceBetween(
            last.latitude, last.longitude,
            newPoint.latitude, newPoint.longitude,
          ) /
          1000.0;
      if (delta > 0.003) {
        _route.add(newPoint);
        _totalDistanceKm += delta;
      }
    } else {
      _route.add(newPoint);
    }

    _pendingPoints.add({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': speedKmh,
      'accuracy': pos.accuracy,
      'heading': pos.heading,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _notify();
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_distanceKey, _totalDistanceKm);
      await prefs.setDouble(_maxSpeedKey, _maxSpeed);
      // Persist route (cap at last 1000 points to keep size reasonable)
      final routeToSave = _route.length > 1000
          ? _route.sublist(_route.length - 1000)
          : _route;
      final routeJson = json.encode(
        routeToSave.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      );
      await prefs.setString(_routeKey, routeJson);
    } catch (e) {
      debugPrint('TripTracking: persist error $e');
    }
  }

  Future<void> _uploadPoints() async {
    if (_activeLogId == null || _pendingPoints.isEmpty) return;
    if (!di.sl.isRegistered<AuthHttpClient>()) return;

    final batch = List<Map<String, dynamic>>.from(_pendingPoints);
    _pendingPoints.clear();

    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.post(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/logs/$_activeLogId/track'),
        body: json.encode({'points': batch}),
      );
      if (response.statusCode != 200) {
        // Put points back to retry later
        _pendingPoints.insertAll(0, batch);
        debugPrint('TripTracking: upload failed ${response.statusCode}');
      } else {
        debugPrint('TripTracking: uploaded ${batch.length} points');
      }
    } catch (e) {
      _pendingPoints.insertAll(0, batch);
      debugPrint('TripTracking: upload error $e');
    }
  }
}
