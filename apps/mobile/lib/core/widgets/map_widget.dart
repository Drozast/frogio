// lib/core/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/maps_service.dart';
import '../theme/app_theme.dart';

class MapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final Function(LatLng)? onLocationSelected;
  final Function(MapController)? onMapCreated;
  final bool showCurrentLocation;
  final bool allowLocationSelection;
  final double zoom;

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
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapsService _mapsService = MapsService();
  late final MapController _mapController;
  LatLng? _currentLocation;
  List<Marker> _markers = [];
  bool _isLoading = true;

  static const LatLng _defaultLocation = LatLng(-37.0636, -72.7306); // Santa Juana, Chile

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.showCurrentLocation) {
      try {
        final position = await _mapsService.getCurrentLocation();
        _currentLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        // Usar ubicacion por defecto si falla
        _currentLocation = _defaultLocation;
      }
    } else {
      _currentLocation = widget.initialLocation ?? _defaultLocation;
    }

    _updateMarkers();
    setState(() {
      _isLoading = false;
    });

    // Notify that map was created
    widget.onMapCreated?.call(_mapController);
    _mapsService.setController(_mapController);
  }

  void _updateMarkers() {
    _markers = List.from(widget.markers ?? []);

    // Agregar marcador de ubicacion actual si esta habilitado
    if (widget.showCurrentLocation && _currentLocation != null) {
      _markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 30,
          ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _defaultLocation,
              initialZoom: widget.zoom,
              onTap: widget.allowLocationSelection
                  ? (tapPosition, point) => widget.onLocationSelected?.call(point)
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.frogio.santajuana',
              ),
              if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
              if (widget.polylines != null && widget.polylines!.isNotEmpty)
                PolylineLayer(polylines: widget.polylines!),
            ],
          ),
        ),

        // Controles personalizados
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Boton de ubicacion actual
              if (widget.showCurrentLocation)
                _buildControlButton(
                  icon: Icons.my_location,
                  onPressed: _goToCurrentLocation,
                  tooltip: 'Mi ubicacion',
                ),
            ],
          ),
        ),

        // Indicador de seleccion de ubicacion
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

  Future<void> _goToCurrentLocation() async {
    try {
      final position = await _mapsService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      _mapController.move(location, widget.zoom);

      setState(() {
        _currentLocation = location;
        _updateMarkers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener ubicacion: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapsService.dispose();
    super.dispose();
  }
}
