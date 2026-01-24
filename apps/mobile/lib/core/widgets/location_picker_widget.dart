// lib/core/widgets/location_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/maps_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class LocationPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String?) onLocationSelected;
  final String title;
  final String confirmButtonText;

  const LocationPickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
    this.title = 'Seleccionar ubicacion',
    this.confirmButtonText = 'Confirmar ubicacion',
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final MapsService _mapsService = MapsService();
  late final MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _isLoadingCurrentLocation = false;

  static const LatLng _defaultLocation = LatLng(-37.0636, -72.7306);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _loadAddress(_selectedLocation!);
    } else {
      // Obtener ubicación actual automáticamente al iniciar
      _loadCurrentLocationOnStart();
    }
  }

  Future<void> _loadCurrentLocationOnStart() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final position = await _mapsService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
        _isLoadingCurrentLocation = false;
      });

      _loadAddress(location);

      // Mover el mapa a la ubicación actual después de que el widget esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(location, 15);
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCurrentLocation = false;
      });
      // Si falla, se mantiene la ubicación por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Informacion de ubicacion seleccionada
          _buildLocationInfo(),

          // Mapa
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? _defaultLocation,
                    initialZoom: 15,
                    onTap: (tapPosition, point) => _onLocationSelected(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.frogio.santajuana',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Controles de zoom
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_in',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                        child: const Icon(Icons.add, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        mini: true,
                        heroTag: 'zoom_out',
                        backgroundColor: Colors.white,
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                        child: const Icon(Icons.remove, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controles inferiores
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Toca en el mapa para seleccionar ubicacion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingCurrentLocation)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Obteniendo tu ubicación actual...',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            )
          else if (_selectedLocation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryColor, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Ubicacion seleccionada:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Obteniendo direccion...'),
                      ],
                    )
                  else if (_selectedAddress != null)
                    Text(_selectedAddress!)
                  else
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Ninguna ubicacion seleccionada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi ubicacion'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddressDialog,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar direccion'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: widget.confirmButtonText,
              onPressed: _selectedLocation != null ? _confirmLocation : () {},
            ),
          ),
        ],
      ),
    );
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = null;
    });
    _loadAddress(location);
  }

  Future<void> _loadAddress(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await _mapsService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedAddress = address;
        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await _mapsService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      _onLocationSelected(location);
      _mapController.move(location, 15);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicacion: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showAddressDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar direccion'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingresa una direccion...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _searchAddress(controller.text);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    try {
      final location = await _mapsService.getCoordinatesFromAddress(address);

      if (!mounted) return;

      if (location != null) {
        _onLocationSelected(location);
        _mapController.move(location, 15);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar la direccion'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en busqueda: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(_selectedLocation!, _selectedAddress);
      Navigator.pop(context);
    }
  }
}
