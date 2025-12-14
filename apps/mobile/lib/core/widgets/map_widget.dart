// lib/core/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/maps_service.dart';
import '../theme/app_theme.dart';

class MapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Function(LatLng)? onLocationSelected;
  final Function(GoogleMapController)? onMapCreated;
  final bool showCurrentLocation;
  final bool allowLocationSelection;
  final double zoom;
  final MapType mapType;

  const MapWidget({
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
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapsService _mapsService = MapsService();
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  static const LatLng _defaultLocation = LatLng(-37.0636, -72.7306); // Santa Juana, Chile

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.showCurrentLocation) {
      try {
        final position = await _mapsService.getCurrentLocation();
        _currentLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Usar ubicación por defecto si falla
        _currentLocation = _defaultLocation;
      }
    } else {
      _currentLocation = widget.initialLocation ?? _defaultLocation;
    }

    _updateMarkers();
    setState(() {
      _isLoading = false;
    });
  }

  void _updateMarkers() {
    _markers = Set.from(widget.markers ?? {});
    
    // Agregar marcador de ubicación actual si está habilitado
    if (widget.showCurrentLocation && _currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando mapa...'),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? _defaultLocation,
            zoom: widget.zoom,
          ),
          markers: _markers,
          polylines: widget.polylines ?? {},
          mapType: widget.mapType,
          onTap: widget.allowLocationSelection ? _onMapTap : null,
          myLocationEnabled: widget.showCurrentLocation,
          myLocationButtonEnabled: false, // Usar botón personalizado
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
        
        // Controles personalizados
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Botón de ubicación actual
              if (widget.showCurrentLocation)
                _buildControlButton(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                  tooltip: 'Mi ubicación',
                ),
              
              const SizedBox(height: 8),
              
              // Selector de tipo de mapa
              _buildControlButton(
                icon: Icons.layers,
                onPressed: _showMapTypeDialog,
                tooltip: 'Tipo de mapa',
              ),
            ],
          ),
        ),
        
        // Indicador de selección de ubicación
        if (widget.allowLocationSelection)
          const Center(
            child: Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
              size: 40,
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
  _mapsService.setController(controller);
  widget.onMapCreated?.call(controller);
}

  void _onMapTap(LatLng location) {
    if (widget.allowLocationSelection) {
      widget.onLocationSelected?.call(location);
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await _mapsService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);
      
      await _mapsService.moveToLocation(location);
      
      setState(() {
        _currentLocation = location;
        _updateMarkers();
      });
    } catch (e) {
      if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo de mapa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapTypeOption(MapType.normal, 'Normal'),
            _buildMapTypeOption(MapType.satellite, 'Satélite'),
            _buildMapTypeOption(MapType.hybrid, 'Híbrido'),
            _buildMapTypeOption(MapType.terrain, 'Terreno'),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(MapType type, String name) {
    return ListTile(
      title: Text(name),
      leading: Radio<MapType>(
        value: type,
        groupValue: widget.mapType,
        onChanged: (value) {
          Navigator.pop(context);
          _changeMapType(value!);
        },
      ),
      onTap: () {
        Navigator.pop(context);
        _changeMapType(type);
      },
    );
  }

  void _changeMapType(MapType type) {
    // Esto requeriría un callback para notificar el cambio al widget padre
    // En una implementación completa, se manejaría con estado
  }

  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }
}