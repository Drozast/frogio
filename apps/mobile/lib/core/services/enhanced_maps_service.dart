// lib/core/services/enhanced_maps_service.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EnhancedMapsService {
  static final EnhancedMapsService _instance = EnhancedMapsService._internal();
  factory EnhancedMapsService() => _instance;
  EnhancedMapsService._internal();

  GoogleMapController? _controller;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isGoogleMapsAvailable = true;

  // Getters
  GoogleMapController? get controller => _controller;
  Position? get currentPosition => _currentPosition;
  bool get isGoogleMapsAvailable => _isGoogleMapsAvailable;

  // Configurar controlador del mapa
  void setController(GoogleMapController controller) {
    _controller = controller;
  }

  // Verificar disponibilidad de Google Maps
  Future<bool> checkGoogleMapsAvailability() async {
    try {
      if (kIsWeb) {
        // En web, verificar si Google Maps está disponible
        return await _checkWebGoogleMaps();
      } else {
        // En móvil, asumir que está disponible
        return true;
      }
    } catch (e) {
      log('Error verificando Google Maps: $e');
      _isGoogleMapsAvailable = false;
      return false;
    }
  }

  Future<bool> _checkWebGoogleMaps() async {
    // Verificar si Google Maps está disponible en web
    const maxWaitTime = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 500);
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < maxWaitTime) {
      try {
        // Verificar si hay error de autenticación
        if (kIsWeb && _hasWebAuthError()) {
          _isGoogleMapsAvailable = false;
          throw Exception('Error de autenticación con Google Maps API');
        }
        
        // Verificar si Google Maps está cargado
        if (kIsWeb && _isWebGoogleMapsLoaded()) {
          _isGoogleMapsAvailable = true;
          return true;
        }
        
        await Future.delayed(checkInterval);
      } catch (e) {
        log('Error en verificación de Google Maps: $e');
        break;
      }
    }
    
    _isGoogleMapsAvailable = false;
    return false;
  }

  bool _hasWebAuthError() {
    // Implementar verificación de errores de autenticación en web
    // Esto requiere acceso a JavaScript en web
    return false; // Placeholder
  }

  bool _isWebGoogleMapsLoaded() {
    // Implementar verificación de carga de Google Maps en web
    // Esto requiere acceso a JavaScript en web
    return true; // Placeholder - asumir que está cargado
  }

  // Obtener ubicación actual con manejo de errores mejorado
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Servicios de ubicación desactivados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Permiso de ubicación denegado');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw LocationException('Permiso de ubicación denegado permanentemente');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      return position;
    } catch (e) {
      log('Error obteniendo ubicación: $e');
      
      // Si falla, usar ubicación por defecto de Santa Juana
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
      throw LocationException('No se pudo obtener ubicación GPS. Usando ubicación por defecto: ${e.toString()}');
    }
  }

  // Iniciar seguimiento de ubicación
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
        timeLimit: const Duration(seconds: 10),
      ),
    ).listen(
      (position) {
        _currentPosition = position;
        onLocationUpdate(position);
      },
      onError: (error) {
        log('Error en stream de ubicación: $error');
      },
    );

    return _positionSubscription!;
  }

  // Detener seguimiento
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Mover cámara a ubicación (con manejo de errores)
  Future<bool> moveToLocation(LatLng location, {double zoom = 15}) async {
    try {
      if (_controller != null && _isGoogleMapsAvailable) {
        await _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: zoom),
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      log('Error moviendo cámara: $e');
      return false;
    }
  }

  // Obtener dirección desde coordenadas con fallback
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
    
    return parts.isEmpty ? 'Dirección no disponible' : parts.join(', ');
  }

  // Obtener coordenadas desde dirección con fallback
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
  Set<Marker> generateReportMarkers({
    required List<dynamic> reports,
    required Function(String) onMarkerTap,
  }) {
    try {
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
    } catch (e) {
      log('Error generando marcadores: $e');
      return <Marker>{};
    }
  }

  // Icono según estado del reporte
  BitmapDescriptor _getMarkerIcon(String status) {
    try {
      switch (status) {
        case 'Completada':
        case 'Resuelta':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        case 'En Proceso':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        case 'Rechazada':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        default:
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      }
    } catch (e) {
      log('Error obteniendo icono de marcador: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Ajustar cámara para mostrar todos los marcadores
  Future<bool> fitMarkersInView(Set<Marker> markers) async {
    try {
      if (_controller == null || markers.isEmpty || !_isGoogleMapsAvailable) {
        return false;
      }

      if (markers.length == 1) {
        await moveToLocation(markers.first.position);
        return true;
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
      
      return true;
    } catch (e) {
      log('Error ajustando vista de marcadores: $e');
      return false;
    }
  }

  // Obtener ubicación por defecto de Santa Juana
  LatLng getDefaultLocation() {
    return const LatLng(-37.0636, -72.7306);
  }

  // Verificar si una ubicación está en Santa Juana
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

// Excepción personalizada para ubicación
class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}