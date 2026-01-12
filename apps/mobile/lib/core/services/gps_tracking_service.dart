import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// GPS Configuration
class GpsConfig {
  static const int trackingIntervalMs = 10000; // 10 seconds
  static const int batchSize = 6; // 6 points = 1 minute of data
  static const int batchSendIntervalMs = 60000; // 60 seconds
  static const double minDistanceMeters = 10.0; // Filter for movement
}

/// GPS Point model
class GpsPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime recordedAt;

  GpsPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'recordedAt': recordedAt.toIso8601String(),
      };

  factory GpsPoint.fromPosition(Position position) {
    return GpsPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed * 3.6, // m/s to km/h
      heading: position.heading,
      accuracy: position.accuracy,
      recordedAt: DateTime.now(),
    );
  }
}

/// GPS Tracking Service
class GpsTrackingService {
  static final GpsTrackingService _instance = GpsTrackingService._internal();
  factory GpsTrackingService() => _instance;
  GpsTrackingService._internal();

  final FlutterBackgroundService _service = FlutterBackgroundService();

  bool _isTracking = false;
  String? _vehicleId;
  String? _vehicleLogId;
  String? _accessToken;
  String? _apiUrl;

  final List<GpsPoint> _pointsBuffer = [];
  Position? _lastPosition;
  Timer? _batchTimer;

  bool get isTracking => _isTracking;
  String? get vehicleId => _vehicleId;

  /// Initialize the background service
  Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'frogio_gps_channel',
        initialNotificationTitle: 'FROGIO GPS',
        initialNotificationContent: 'Tracking de vehículo en curso',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Start tracking for a vehicle
  Future<bool> startTracking({
    required String vehicleId,
    required String vehicleLogId,
    required String accessToken,
    required String apiUrl,
  }) async {
    if (_isTracking) {
      debugPrint('GPS Tracking already active');
      return false;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    // Store config
    _vehicleId = vehicleId;
    _vehicleLogId = vehicleLogId;
    _accessToken = accessToken;
    _apiUrl = apiUrl;

    // Save to preferences for background service
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gps_vehicle_id', vehicleId);
    await prefs.setString('gps_vehicle_log_id', vehicleLogId);
    await prefs.setString('gps_access_token', accessToken);
    await prefs.setString('gps_api_url', apiUrl);

    // Start background service
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }

    _isTracking = true;
    _pointsBuffer.clear();

    // Start batch timer
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(
      const Duration(milliseconds: GpsConfig.batchSendIntervalMs),
      (_) => _sendBatch(),
    );

    // Start location stream
    _startLocationStream();

    debugPrint('GPS Tracking started for vehicle: $vehicleId');
    return true;
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    _batchTimer?.cancel();
    _batchTimer = null;

    // Send remaining points
    if (_pointsBuffer.isNotEmpty) {
      await _sendBatch();
    }

    // Stop background service
    _service.invoke('stopService');

    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gps_vehicle_id');
    await prefs.remove('gps_vehicle_log_id');
    await prefs.remove('gps_access_token');
    await prefs.remove('gps_api_url');

    _isTracking = false;
    _vehicleId = null;
    _vehicleLogId = null;
    _pointsBuffer.clear();
    _lastPosition = null;

    debugPrint('GPS Tracking stopped');
  }

  /// Start listening to location updates
  void _startLocationStream() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: GpsConfig.minDistanceMeters.toInt(),
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _onPositionUpdate(position);
    });
  }

  /// Handle position update
  void _onPositionUpdate(Position position) {
    if (!_isTracking) return;

    // Check minimum distance
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < GpsConfig.minDistanceMeters) {
        return;
      }
    }

    _lastPosition = position;
    final point = GpsPoint.fromPosition(position);
    _pointsBuffer.add(point);

    debugPrint(
        'GPS Point recorded: ${point.latitude}, ${point.longitude} (${_pointsBuffer.length} in buffer)');

    // Send batch if buffer is full
    if (_pointsBuffer.length >= GpsConfig.batchSize) {
      _sendBatch();
    }
  }

  /// Send batch of GPS points to server
  Future<void> _sendBatch() async {
    if (_pointsBuffer.isEmpty || _apiUrl == null || _accessToken == null) {
      return;
    }

    final pointsToSend = List<GpsPoint>.from(_pointsBuffer);
    _pointsBuffer.clear();

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/gps/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
          'X-Tenant-ID': 'santa_juana',
        },
        body: jsonEncode({
          'vehicleId': _vehicleId,
          'vehicleLogId': _vehicleLogId,
          'points': pointsToSend.map((p) => p.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('GPS batch sent successfully: ${pointsToSend.length} points');
      } else {
        debugPrint('Failed to send GPS batch: ${response.statusCode}');
        // Re-add points to buffer on failure
        _pointsBuffer.insertAll(0, pointsToSend);
      }
    } catch (e) {
      debugPrint('Error sending GPS batch: $e');
      // Re-add points to buffer on error
      _pointsBuffer.insertAll(0, pointsToSend);
    }
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Get tracking statistics
  Map<String, dynamic> getStats() {
    return {
      'isTracking': _isTracking,
      'vehicleId': _vehicleId,
      'bufferedPoints': _pointsBuffer.length,
      'lastPosition': _lastPosition != null
          ? {
              'latitude': _lastPosition!.latitude,
              'longitude': _lastPosition!.longitude,
            }
          : null,
    };
  }
}

// Background service entry point
@pragma('vm:entry-point')
Future<void> _onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  // Load config from preferences
  final prefs = await SharedPreferences.getInstance();
  final vehicleId = prefs.getString('gps_vehicle_id');
  final vehicleLogId = prefs.getString('gps_vehicle_log_id');
  final accessToken = prefs.getString('gps_access_token');
  final apiUrl = prefs.getString('gps_api_url');

  if (vehicleId == null || accessToken == null || apiUrl == null) {
    debugPrint('Missing GPS config, stopping service');
    service.stopSelf();
    return;
  }

  List<Map<String, dynamic>> buffer = [];

  // Start location tracking
  bool isServiceRunning = true;

  service.on('stopService').listen((event) {
    isServiceRunning = false;
    service.stopSelf();
  });

  Timer.periodic(const Duration(milliseconds: GpsConfig.trackingIntervalMs),
      (timer) async {
    if (!isServiceRunning) {
      timer.cancel();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      buffer.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'speed': position.speed * 3.6,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'recordedAt': DateTime.now().toIso8601String(),
      });

      // Send batch when full
      if (buffer.length >= GpsConfig.batchSize) {
        try {
          final response = await http.post(
            Uri.parse('$apiUrl/api/gps/batch'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'X-Tenant-ID': 'santa_juana',
            },
            body: jsonEncode({
              'vehicleId': vehicleId,
              'vehicleLogId': vehicleLogId,
              'points': buffer,
            }),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            buffer.clear();
          }
        } catch (e) {
          debugPrint('Background GPS send error: $e');
        }
      }

      // Update notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'FROGIO GPS Activo',
          content:
              'Tracking: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        );
      }
    } catch (e) {
      debugPrint('Background GPS error: $e');
    }
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
