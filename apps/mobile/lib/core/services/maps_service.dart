// lib/core/services/maps_service.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import 'nominatim_service.dart';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  final NominatimService _nominatim = NominatimService();

  /// Get self-hosted tile server URL
  static String get tileServerUrl => '${ApiConfig.tileServerUrl}/styles/basic-preview/{z}/{x}/{y}.png';

  /// Alternative: OpenStreetMap fallback URL
  static const String osmFallbackUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  MapController? _controller;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  MapController? get controller => _controller;
  Position? get currentPosition => _currentPosition;

  // Configurar controlador del mapa
  void setController(MapController controller) {
    _controller = controller;
  }

  // Obtener ubicacion actual
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicios de ubicacion desactivados');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicacion denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicacion denegado permanentemente');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentPosition = position;
    return position;
  }

  // Iniciar seguimiento de ubicacion
  StreamSubscription<Position> startLocationTracking({
    required Function(Position) onLocationUpdate,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen((position) {
      _currentPosition = position;
      onLocationUpdate(position);
    });

    return _positionSubscription!;
  }

  // Detener seguimiento
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Mover camara a ubicacion
  Future<void> moveToLocation(LatLng location, {double zoom = 15}) async {
    if (_controller != null) {
      _controller!.move(location, zoom);
    }
  }

  // Obtener direccion desde coordenadas (usando Nominatim self-hosted)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    return _nominatim.getAddressFromCoordinates(lat, lng);
  }

  // Obtener coordenadas desde direccion (usando Nominatim self-hosted)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    return _nominatim.getCoordinatesFromAddress(address);
  }

  // Buscar lugares con autocompletado
  Future<List<NominatimPlace>> searchPlaces(String query, {int limit = 5}) async {
    return _nominatim.searchPlaces(query, limit: limit);
  }

  // Calcular distancia entre dos puntos
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Generar marcadores para reportes
  List<Marker> generateReportMarkers({
    required List<dynamic> reports,
    required Function(String) onMarkerTap,
  }) {
    return reports.map((report) {
      return Marker(
        point: LatLng(
          report.location.latitude,
          report.location.longitude,
        ),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => onMarkerTap(report.id),
          child: Icon(
            Icons.location_on,
            color: _getMarkerColor(report.status),
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  // Color segun estado del reporte
  Color _getMarkerColor(String status) {
    switch (status) {
      case 'Completada':
        return const Color(0xFF4CAF50); // Verde
      case 'En Proceso':
        return const Color(0xFF2196F3); // Azul
      case 'Rechazada':
        return const Color(0xFFF44336); // Rojo
      default:
        return const Color(0xFFFF9800); // Naranja
    }
  }

  // Ajustar camara para mostrar todos los marcadores
  Future<void> fitMarkersInView(List<Marker> markers) async {
    if (_controller == null || markers.isEmpty) return;

    if (markers.length == 1) {
      await moveToLocation(markers.first.point);
      return;
    }

    double minLat = markers.first.point.latitude;
    double maxLat = markers.first.point.latitude;
    double minLng = markers.first.point.longitude;
    double maxLng = markers.first.point.longitude;

    for (final marker in markers) {
      minLat = minLat < marker.point.latitude ? minLat : marker.point.latitude;
      maxLat = maxLat > marker.point.latitude ? maxLat : marker.point.latitude;
      minLng = minLng < marker.point.longitude ? minLng : marker.point.longitude;
      maxLng = maxLng > marker.point.longitude ? maxLng : marker.point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _controller!.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  // Cleanup
  void dispose() {
    stopLocationTracking();
    _controller = null;
  }
}
