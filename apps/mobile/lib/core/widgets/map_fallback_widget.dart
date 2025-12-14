// lib/core/widgets/map_fallback_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';

class MapFallbackWidget extends StatelessWidget {
  final LatLng? location;
  final String? address;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Function(LatLng)? onLocationSelected;
  final bool allowLocationSelection;

  const MapFallbackWidget({
    super.key,
    this.location,
    this.address,
    this.errorMessage,
    this.onRetry,
    this.onLocationSelected,
    this.allowLocationSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Mapa no disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'No se pudo cargar Google Maps',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            if (location != null) ...[
              const SizedBox(height: 20),
              _buildLocationInfo(),
            ],
            
            const SizedBox(height: 20),
            _buildActionButtons(context),
            
            const SizedBox(height: 16),
            _buildTroubleshootingTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ubicación seleccionada:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (address != null)
            Text(
              address!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${location!.latitude.toStringAsFixed(6)}\n'
            'Lng: ${location!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar cargar mapa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        if (allowLocationSelection)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showManualLocationDialog(context),
              icon: const Icon(Icons.edit_location),
              label: const Text('Ingresar coordenadas manualmente'),
            ),
          ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openExternalMap(),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir en Google Maps'),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingTips() {
    return ExpansionTile(
      title: const Text(
        'Consejos para solucionar',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTip('Verifica tu conexión a internet'),
              _buildTip('Recarga la página (Ctrl+F5 en web)'),
              _buildTip('Verifica que JavaScript esté habilitado'),
              _buildTip('Prueba con otro navegador'),
              _buildTip('Verifica la configuración de la API key de Google Maps'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    
    if (location != null) {
      latController.text = location!.latitude.toString();
      lngController.text = location!.longitude.toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar coordenadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Latitud',
                hintText: 'Ej: -37.0636',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Longitud',
                hintText: 'Ej: -72.7306',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Puedes obtener estas coordenadas desde Google Maps copiando y pegando desde la URL.',
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
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              
              if (lat != null && lng != null && 
                  lat >= -90 && lat <= 90 && 
                  lng >= -180 && lng <= 180) {
                Navigator.pop(context);
                onLocationSelected?.call(LatLng(lat, lng));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coordenadas inválidas'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _openExternalMap() {
    if (location != null) {
      final url = 'https://www.google.com/maps?q=${location!.latitude},${location!.longitude}';
      // En una implementación real, usar url_launcher para abrir el enlace
      debugPrint('Abrir enlace: $url');
    }
  }
}