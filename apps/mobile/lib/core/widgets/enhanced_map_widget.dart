// lib/core/widgets/enhanced_map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

class EnhancedMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final Function(LatLng)? onLocationSelected;
  final Function(MapController)? onMapCreated;
  final bool showCurrentLocation;
  final bool allowLocationSelection;
  final double zoom;
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
    this.errorMessage,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  late final MapController _mapController;
  bool _isLoading = true;

  static const LatLng _defaultLocation = LatLng(-37.0636, -72.7306); // Santa Juana, Chile

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Simular carga
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onMapCreated?.call(_mapController);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
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

  Widget _buildMap() {
    final initialCenter = widget.initialLocation ?? _defaultLocation;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
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
          if (widget.markers != null && widget.markers!.isNotEmpty)
            MarkerLayer(markers: widget.markers!),
          if (widget.polylines != null && widget.polylines!.isNotEmpty)
            PolylineLayer(polylines: widget.polylines!),
        ],
      ),
    );
  }
}
