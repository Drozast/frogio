// lib/core/services/enhanced_maps_service.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class EnhancedMapsService {
  static final EnhancedMapsService _instance = EnhancedMapsService._internal();
  factory EnhancedMapsService() => _instance;
  EnhancedMapsService._internal();

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

  // Obtener ubicacion actual con manejo de errores mejorado
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Servicios de ubicacion desactivados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Permiso de ubicacion denegado');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException('Permiso de ubicacion denegado permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw LocationException('Timeout obteniendo ubicacion'),
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      log('Error obteniendo ubicacion: $e');

      // Si falla, usar ubicacion por defecto de Santa Juana
      final defaultPosition = Position(
        latitude: -37.0636,
        longitude: -72.7306,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      _currentPosition = defaultPosition;
      throw LocationException('No se pudo obtener ubicacion GPS. Usando ubicacion por defecto: ${e.toString()}');
    }
  }

  // Iniciar seguimiento de ubicacion
  StreamSubscription<Position> startLocationTracking({
    required Function(Position) onLocationUpdate,
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        onLocationUpdate(position);
      },
      onError: (error) {
        log('Error en stream de ubicacion: $error');
      },
    );

    return _positionSubscription!;
  }

  // Detener seguimiento
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Mover camara a ubicacion (con manejo de errores)
  Future<bool> moveToLocation(LatLng location, {double zoom = 15}) async {
    try {
      if (_controller != null) {
        _controller!.move(location, zoom);
        return true;
      }
      return false;
    } catch (e) {
      log('Error moviendo camara: $e');
      return false;
    }
  }

  // Obtener direccion desde coordenadas con fallback
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return _formatAddress(place);
      }
    } catch (e) {
      log('Error getting address: $e');

      // Fallback: devolver coordenadas formateadas
      return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
    }
    return null;
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true) parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);

    return parts.isEmpty ? 'Direccion no disponible' : parts.join(', ');
  }

  // Obtener coordenadas desde direccion con fallback
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      log('Error getting coordinates: $e');
    }
    return null;
  }

  // Calcular distancia entre dos puntos
  double calculateDistance(LatLng point1, LatLng point2) {
    try {
      return Geolocator.distanceBetween(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );
    } catch (e) {
      log('Error calculando distancia: $e');
      return 0.0;
    }
  }

  // Generar marcadores para reportes con manejo de errores
  List<Marker> generateReportMarkers({
    required List<dynamic> reports,
    required Function(String) onMarkerTap,
  }) {
    try {
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
    } catch (e) {
      log('Error generando marcadores: $e');
      return <Marker>[];
    }
  }

  // Color segun estado del reporte
  Color _getMarkerColor(String status) {
    switch (status) {
      case 'Completada':
      case 'Resuelta':
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
  Future<bool> fitMarkersInView(List<Marker> markers) async {
    try {
      if (_controller == null || markers.isEmpty) {
        return false;
      }

      if (markers.length == 1) {
        await moveToLocation(markers.first.point);
        return true;
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

      return true;
    } catch (e) {
      log('Error ajustando vista de marcadores: $e');
      return false;
    }
  }

  // Obtener ubicacion por defecto de Santa Juana
  LatLng getDefaultLocation() {
    return const LatLng(-37.0636, -72.7306);
  }

  // Verificar si una ubicacion esta en Santa Juana
  bool isLocationInSantaJuana(LatLng location) {
    const santaJuana = LatLng(-37.0636, -72.7306);
    const radiusKm = 20.0; // 20 km de radio

    final distance = calculateDistance(location, santaJuana);
    return distance <= (radiusKm * 1000); // Convertir a metros
  }

  // Cleanup
  void dispose() {
    stopLocationTracking();
    _controller = null;
    _currentPosition = null;
  }
}

// Excepcion personalizada para ubicacion
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}
