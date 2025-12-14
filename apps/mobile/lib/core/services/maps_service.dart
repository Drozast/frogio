// lib/core/services/maps_service.dart
import 'dart:async';
import 'dart:developer';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  GoogleMapController? _controller;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  GoogleMapController? get controller => _controller;
  Position? get currentPosition => _currentPosition;

  // Configurar controlador del mapa
  void setController(GoogleMapController controller) {
    _controller = controller;
  }

  // Obtener ubicación actual
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicios de ubicación desactivados');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    _currentPosition = position;
    return position;
  }

  // Iniciar seguimiento de ubicación
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

  // Mover cámara a ubicación
  Future<void> moveToLocation(LatLng location, {double zoom = 15}) async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: zoom),
        ),
      );
    }
  }

  // Obtener dirección desde coordenadas
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
      }
    } catch (e) {
      log('Error getting address: $e');
    }
    return null;
  }

  // Obtener coordenadas desde dirección
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
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Generar marcadores para reportes
  Set<Marker> generateReportMarkers({
    required List<dynamic> reports,
    required Function(String) onMarkerTap,
  }) {
    return reports.map((report) {
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(
          report.location.latitude,
          report.location.longitude,
        ),
        infoWindow: InfoWindow(
          title: report.title,
          snippet: report.status,
          onTap: () => onMarkerTap(report.id),
        ),
        icon: _getMarkerIcon(report.status),
        onTap: () => onMarkerTap(report.id),
      );
    }).toSet();
  }

  // Icono según estado del reporte
  BitmapDescriptor _getMarkerIcon(String status) {
    switch (status) {
      case 'Completada':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'En Proceso':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'Rechazada':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  // Ajustar cámara para mostrar todos los marcadores
  Future<void> fitMarkersInView(Set<Marker> markers) async {
    if (_controller == null || markers.isEmpty) return;

    if (markers.length == 1) {
      await moveToLocation(markers.first.position);
      return;
    }

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  // Cleanup
  void dispose() {
    stopLocationTracking();
    _controller = null;
  }
}