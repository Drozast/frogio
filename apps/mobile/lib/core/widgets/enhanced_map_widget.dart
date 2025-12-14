// lib/core/widgets/enhanced_map_widget.dart
import 'dart:html' as html show window;
import 'dart:js_util' as js_util show getProperty;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';

class EnhancedMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Function(LatLng)? onLocationSelected;
  final Function(GoogleMapController)? onMapCreated;
  final bool showCurrentLocation;
  final bool allowLocationSelection;
  final double zoom;
  final MapType mapType;
  final String? errorMessage;

  const EnhancedMapWidget({
    super.key,
    this.initialLocation,
    this.markers,
    this.polylines,
    this.onLocationSelected,
    this.onMapCreated,
    this.showCurrentLocation = true,
    this.allowLocationSelection = false,
    this.zoom = 15.0,
    this.mapType = MapType.normal,
    this.errorMessage,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  bool _mapError = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  static const LatLng _defaultLocation = LatLng(-37.0636, -72.7306); // Santa Juana, Chile

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsAvailability();
  }

  void _checkGoogleMapsAvailability() {
    if (kIsWeb) {
      // En web, verificar si Google Maps está disponible
      _checkWebGoogleMaps();
    } else {
      // En móvil, asumir que está disponible
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkWebGoogleMaps() {
    // Verificar cada 100ms por hasta 10 segundos si Google Maps está disponible
    int attempts = 0;
    const maxAttempts = 100; // 10 segundos
    
    void checkMaps() {
      attempts++;
      
      // Verificar si hay error global de Google Maps
      if (kIsWeb && _hasWebGoogleMapsError()) {
        setState(() {
          _mapError = true;
          _isLoading = false;
          _errorMessage = 'Error de autenticación con Google Maps. Verifica tu API key.';
        });
        return;
      }
      
      // Verificar si Google Maps está disponible
      if (kIsWeb && _isWebGoogleMapsLoaded()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Si no está listo y no hemos agotado los intentos, seguir intentando
      if (attempts < maxAttempts) {
        Future.delayed(const Duration(milliseconds: 100), checkMaps);
      } else {
        // Timeout: mostrar error
        setState(() {
          _mapError = true;
          _isLoading = false;
          _errorMessage = 'Timeout cargando Google Maps. Verifica tu conexión a internet.';
        });
      }
    }
    
    checkMaps();
  }

  bool _hasWebGoogleMapsError() {
    try {
      // Verificar si hay variables de error globales
      return kIsWeb && (
        js_util.getProperty(html.window, 'googleMapsError') == true
      );
    } catch (e) {
      return false;
    }
  }

  bool _isWebGoogleMapsLoaded() {
    try {
      // Verificar si Google Maps está disponible en web
      return kIsWeb && (
        js_util.getProperty(html.window, 'googleMapsLoaded') == true ||
        js_util.getProperty(html.window, 'google') != null
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_mapError) {
      return _buildErrorState();
    }

    return _buildMap();
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando mapa...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 16),
              Text(
                'Mapa no disponible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? widget.errorMessage ?? 
                'No se pudo cargar Google Maps. Verifica tu conexión a internet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _mapError = false;
                    _isLoading = true;
                  });
                  _checkGoogleMapsAvailability();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              if (widget.initialLocation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ubicación:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${widget.initialLocation!.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${widget.initialLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? _defaultLocation,
          zoom: widget.zoom,
        ),
        markers: widget.markers ?? {},
        polylines: widget.polylines ?? {},
        mapType: widget.mapType,
        onTap: widget.allowLocationSelection ? widget.onLocationSelected : null,
        myLocationEnabled: widget.showCurrentLocation,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: false,
       
      );
    } catch (e) {
      // Si hay error al crear el mapa, mostrar estado de error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _mapError = true;
            _errorMessage = 'Error al inicializar el mapa: ${e.toString()}';
          });
        }
      });
      
      return _buildErrorState();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      widget.onMapCreated?.call(controller);
    } catch (e) {
      debugPrint('Error al crear controlador de mapa: $e');
    }
  }
}

// Imports necesarios para web (agregar al inicio del archivo)
