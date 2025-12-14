// lib/features/citizen/presentation/widgets/location_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../domain/entities/enhanced_report_entity.dart';

class LocationSelectorWidget extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const LocationSelectorWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  LocationData? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de ubicación actual
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: _selectedLocation != null 
                ? AppTheme.primaryColor.withValues(alpha: 0.05)
                : Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _selectedLocation != null 
                        ? AppTheme.primaryColor 
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedLocation != null 
                        ? 'Ubicación seleccionada' 
                        : 'No se ha seleccionado ubicación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedLocation != null 
                          ? AppTheme.primaryColor 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              
              if (_selectedLocation != null) ...[
                const SizedBox(height: 8),
                Text(
                  _getLocationDisplayText(),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Opciones de selección de ubicación
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectLocationFromMap,
                icon: const Icon(Icons.map),
                label: Text(_selectedLocation != null 
                    ? 'Cambiar ubicación' 
                    : 'Seleccionar en mapa'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Mi ubicación'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Opción manual
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _enterManualAddress,
            icon: const Icon(Icons.edit_location),
            label: const Text('Ingresar dirección manualmente'),
          ),
        ),
        
        if (_selectedLocation != null && _selectedLocation!.source == LocationSource.manual) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ubicación ingresada manualmente. Para mayor precisión, selecciona en el mapa.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getLocationDisplayText() {
    if (_selectedLocation == null) return '';
    
    switch (_selectedLocation!.source) {
      case LocationSource.gps:
        return _selectedLocation!.address ?? 'Ubicación GPS obtenida';
      case LocationSource.map:
        return _selectedLocation!.address ?? 'Ubicación seleccionada en mapa';
      case LocationSource.manual:
        return _selectedLocation!.manualAddress ?? 'Dirección ingresada manualmente';
    }
  }

  Future<void> _selectLocationFromMap() async {
    await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          initialLocation: _selectedLocation != null
              ? LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude)
              : null,
          onLocationSelected: (location, address) {
            final locationData = LocationData(
              latitude: location.latitude,
              longitude: location.longitude,
              address: address,
              source: LocationSource.map,
            );
            
            setState(() {
              _selectedLocation = locationData;
            });
            
            widget.onLocationSelected(locationData);
          },
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Obteniendo ubicación...'),
            ],
          ),
        ),
      );
      
      // Simular obtención de ubicación GPS
      await Future.delayed(const Duration(seconds: 2));
      
      // Cerrar loading
      if (mounted) Navigator.pop(context);
      
      // Crear ubicación de ejemplo (en implementación real, usar Geolocator)
      const locationData = LocationData(
        latitude: -37.0636, // Santa Juana, Chile
        longitude: -72.7306,
        address: 'Santa Juana, Región del Bío Bío, Chile',
        source: LocationSource.gps,
      );
      
      setState(() {
        _selectedLocation = locationData;
      });
      
      widget.onLocationSelected(locationData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (mounted) Navigator.pop(context);
      
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

  Future<void> _enterManualAddress() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar dirección'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ej: Calle Principal 123, Santa Juana',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nota: Coordenadas aproximadas serán asignadas automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      // En implementación real, usar geocoding para obtener coordenadas
      final locationData = LocationData(
        latitude: -37.0636 + (DateTime.now().millisecond / 100000), // Variación mínima
        longitude: -72.7306 + (DateTime.now().millisecond / 100000),
        manualAddress: result,
        source: LocationSource.manual,
      );
      
      setState(() {
        _selectedLocation = locationData;
      });
      
      widget.onLocationSelected(locationData);
    }
  }
}