// lib/features/inspector/presentation/pages/create_citation_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as path;

import '../../../../core/config/api_config.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/models/citation_model.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';

class CreateCitationScreen extends StatefulWidget {
  final String inspectorId;

  const CreateCitationScreen({super.key, required this.inspectorId});

  @override
  State<CreateCitationScreen> createState() => _CreateCitationScreenState();
}

class _CreateCitationScreenState extends State<CreateCitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryGreen = Color(0xFF1B5E20);

  // Controllers
  final _targetNameController = TextEditingController();
  final _targetRutController = TextEditingController();
  final _targetAddressController = TextEditingController();
  final _targetPhoneController = TextEditingController();
  final _targetPlateController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  // Controllers para número de citación
  final _folioController = TextEditingController();

  // State
  CitationType _selectedCitationType = CitationType.citacion;
  TargetType _selectedTargetType = TargetType.persona;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Photos
  final List<File> _photos = [];
  static const int _maxPhotos = 5;
  bool _isProcessingPhoto = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _targetNameController.dispose();
    _targetRutController.dispose();
    _targetAddressController.dispose();
    _targetPhoneController.dispose();
    _targetPlateController.dispose();
    _locationAddressController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _folioController.dispose();
    super.dispose();
  }

  // Generar número de citación con formato: DD-MM-YYYY-FOLIO
  String _generateCitationNumber() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final folio = _folioController.text.trim();

    if (folio.isEmpty) {
      return '$day-$month-$year-';
    }
    return '$day-$month-$year-$folio';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _locationAddressController.text =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        }
      } catch (_) {}
    } catch (_) {}

    setState(() => _isLoadingLocation = false);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      _showError('Máximo $_maxPhotos fotos permitidas');
      return;
    }

    setState(() => _isProcessingPhoto = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // Max 10MB
        if (fileSize > 10 * 1024 * 1024) {
          _showError('La imagen es demasiado grande. Máximo 10MB.');
          return;
        }

        setState(() {
          _photos.add(file);
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: ${e.toString()}');
    } finally {
      setState(() => _isProcessingPhoto = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primaryGreen),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primaryGreen),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CitationBloc>(),
      child: BlocConsumer<CitationBloc, CitationState>(
        listener: (context, state) {
          if (state is CitationCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is CitationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CitationCreating;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Nueva Citación'),
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Número de citación
                    _buildCitationNumberSection(),
                    const SizedBox(height: 24),

                    // Tipo de citación
                    _buildSectionTitle('Tipo de Citación'),
                    const SizedBox(height: 12),
                    _buildCitationTypeSelector(),
                    const SizedBox(height: 24),

                    // Tipo de objetivo
                    _buildSectionTitle('Tipo de Objetivo'),
                    const SizedBox(height: 12),
                    _buildTargetTypeSelector(),
                    const SizedBox(height: 24),

                    // Datos del objetivo
                    _buildSectionTitle('Datos del Objetivo'),
                    const SizedBox(height: 12),
                    _buildTargetFields(),
                    const SizedBox(height: 24),

                    // Ubicación
                    _buildSectionTitle('Ubicación'),
                    const SizedBox(height: 12),
                    _buildLocationSection(),
                    const SizedBox(height: 24),

                    // Motivo
                    _buildSectionTitle('Motivo de la Citación'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Describe el motivo de la citación...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El motivo es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Fotos de evidencia
                    _buildSectionTitle('Fotos de Evidencia (opcional)'),
                    const SizedBox(height: 12),
                    _buildPhotosSection(),
                    const SizedBox(height: 24),

                    // Notas adicionales
                    _buildSectionTitle('Notas Adicionales (opcional)'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Notas adicionales...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submitForm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Crear Citación',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_camera, color: _primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Fotos adjuntas',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_photos.length}/$_maxPhotos',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de fotos
          if (_photos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoItem(_photos[index], index);
              },
            ),
            const SizedBox(height: 12),
          ],

          // Botón agregar foto
          if (_photos.length < _maxPhotos)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isProcessingPhoto ? null : _showPhotoOptions,
                icon: _isProcessingPhoto
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                label: Text(_isProcessingPhoto ? 'Procesando...' : 'Agregar foto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // Ayuda
          if (_photos.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las fotos ayudan a documentar la situación y sirven como evidencia',
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
      ),
    );
  }

  Widget _buildPhotoItem(File photo, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _previewPhoto(photo),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                photo,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _previewPhoto(File photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              path.basename(photo.path),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(photo, fit: BoxFit.contain),
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildCitationNumberSection() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.numbers, color: _primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                'Número de Citación',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Fecha automática (no editable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '$day-$month-$year-',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Folio editable
              Expanded(
                child: TextFormField(
                  controller: _folioController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'N° Folio',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _primaryGreen, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el N° de folio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ingrese el número de folio del papel de citación',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCitationTypeSelector() {
    return Row(
      children: CitationType.values.map((type) {
        final isSelected = _selectedCitationType == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCitationType = type),
            child: Container(
              margin: EdgeInsets.only(
                right: type == CitationType.values.first ? 8 : 0,
                left: type == CitationType.values.last ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? _primaryGreen : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _primaryGreen : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    type == CitationType.advertencia
                        ? Icons.warning_amber
                        : Icons.assignment,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TargetType.values.map((type) {
        final isSelected = _selectedTargetType == type;
        return ChoiceChip(
          label: Text(type.displayName),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedTargetType = type),
          selectedColor: _primaryGreen,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetFields() {
    return Column(
      children: [
        // Nombre (siempre visible)
        TextFormField(
          controller: _targetNameController,
          decoration: InputDecoration(
            labelText: _getTargetNameLabel(),
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // RUT (para persona)
        if (_selectedTargetType == TargetType.persona) ...[
          TextFormField(
            controller: _targetRutController,
            decoration: const InputDecoration(
              labelText: 'RUT',
              hintText: '12.345.678-9',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final formatted = _formatRut(value);
              if (formatted != value) {
                _targetRutController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],

        // Patente (para vehículo)
        if (_selectedTargetType == TargetType.vehiculo) ...[
          TextFormField(
            controller: _targetPlateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Patente',
              hintText: 'ABCD12',
              prefixIcon: Icon(Icons.directions_car_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Dirección del objetivo
        TextFormField(
          controller: _targetAddressController,
          decoration: InputDecoration(
            labelText: _selectedTargetType == TargetType.domicilio ||
                    _selectedTargetType == TargetType.comercio
                ? 'Dirección'
                : 'Dirección (opcional)',
            prefixIcon: const Icon(Icons.home_outlined),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Teléfono
        TextFormField(
          controller: _targetPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono (opcional)',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        // Botones de opciones de ubicación
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'Obteniendo...' : 'Usar GPS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map),
                label: const Text('Buscar en Mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  side: const BorderSide(color: _primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Campo de dirección
        TextFormField(
          controller: _locationAddressController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Dirección de la fiscalización',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
            hintText: 'Escriba la dirección o use las opciones de arriba',
          ),
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordenadas GPS capturadas',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
                  onPressed: () {
                    setState(() {
                      _latitude = null;
                      _longitude = null;
                    });
                  },
                  tooltip: 'Limpiar ubicación',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _openMapPicker() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => _MapPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
        if (result['address'] != null) {
          _locationAddressController.text = result['address'] as String;
        }
      });
    }
  }

  String _getTargetNameLabel() {
    switch (_selectedTargetType) {
      case TargetType.persona:
        return 'Nombre completo';
      case TargetType.domicilio:
        return 'Nombre del residente/propietario';
      case TargetType.vehiculo:
        return 'Nombre del conductor (opcional)';
      case TargetType.comercio:
        return 'Nombre del comercio';
      case TargetType.otro:
        return 'Identificación';
    }
  }

  String _formatRut(String rut) {
    String clean = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return '';

    String body = clean.length > 1 ? clean.substring(0, clean.length - 1) : '';
    String dv = clean.isNotEmpty ? clean[clean.length - 1] : '';

    String formatted = '';
    for (int i = body.length - 1, count = 0; i >= 0; i--, count++) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = body[i] + formatted;
    }

    return dv.isNotEmpty ? '$formatted-$dv' : formatted;
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que el folio esté ingresado
    if (_folioController.text.trim().isEmpty) {
      _showError('Por favor ingrese el número de folio de la citación');
      return;
    }

    final citationNumber = _generateCitationNumber();

    final dto = CreateCitationDto(
      citationType: _selectedCitationType,
      targetType: _selectedTargetType,
      targetName: _targetNameController.text.isNotEmpty
          ? _targetNameController.text
          : null,
      targetRut: _targetRutController.text.isNotEmpty
          ? _targetRutController.text
          : null,
      targetAddress: _targetAddressController.text.isNotEmpty
          ? _targetAddressController.text
          : null,
      targetPhone: _targetPhoneController.text.isNotEmpty
          ? _targetPhoneController.text
          : null,
      targetPlate: _targetPlateController.text.isNotEmpty
          ? _targetPlateController.text.toUpperCase()
          : null,
      locationAddress: _locationAddressController.text.isNotEmpty
          ? _locationAddressController.text
          : null,
      latitude: _latitude,
      longitude: _longitude,
      citationNumber: citationNumber,
      reason: _reasonController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    context.read<CitationBloc>().add(CreateCitationEvent(
      dto: dto,
      photos: _photos.isNotEmpty ? _photos : null,
    ));
  }
}

// Widget para seleccionar ubicación en mapa
class _MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const _MapPickerScreen({
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  late double _latitude;
  late double _longitude;
  String? _address;
  bool _isLoadingAddress = false;
  bool _isGettingLocation = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final MapController _mapController = MapController();
  double _currentZoom = 16;

  @override
  void initState() {
    super.initState();
    // Santa Juana como ubicación por defecto
    _latitude = widget.initialLatitude ?? -37.1769;
    _longitude = widget.initialLongitude ?? -72.9467;
    _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(_latitude, _longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _address = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        });
      }
    } catch (_) {}
    setState(() => _isLoadingAddress = false);
  }

  Future<void> _searchLocation(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress('$query, Santa Juana, Chile');
      final results = <Map<String, dynamic>>[];

      for (final location in locations.take(5)) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          results.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
            'address': '${place.street ?? ''}, ${place.locality ?? ''}',
          });
        }
      }

      setState(() => _searchResults = results);
    } catch (_) {
      setState(() => _searchResults = []);
    }
    setState(() => _isSearching = false);
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(1.0, 18.0);
    _mapController.move(LatLng(_latitude, _longitude), newZoom);
    setState(() => _currentZoom = newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
    _mapController.move(LatLng(_latitude, _longitude), newZoom);
    setState(() => _currentZoom = newZoom);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servicios de ubicación desactivados')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permiso de ubicación denegado')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _mapController.move(LatLng(_latitude, _longitude), _currentZoom);
      _getAddressFromCoordinates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'latitude': _latitude,
                'longitude': _longitude,
                'address': _address,
              });
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar dirección...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _searchLocation,
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(
                            result['address'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            setState(() {
                              _latitude = result['latitude'];
                              _longitude = result['longitude'];
                              _address = result['address'];
                              _searchResults = [];
                              _searchController.clear();
                            });
                            _mapController.move(
                              LatLng(_latitude, _longitude),
                              _currentZoom,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Mapa
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_latitude, _longitude),
                    initialZoom: _currentZoom,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _latitude = point.latitude;
                        _longitude = point.longitude;
                      });
                      _getAddressFromCoordinates();
                    },
                    onPositionChanged: (position, hasGesture) {
                      if (position.zoom != null) {
                        _currentZoom = position.zoom!;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: '${ApiConfig.tileServerUrl}/styles/osm-bright/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.frogio.santa_juana',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_latitude, _longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Botones de zoom y mi ubicación
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      // Botón Mi Ubicación
                      FloatingActionButton.small(
                        heroTag: 'my_location',
                        onPressed: _isGettingLocation ? null : _goToMyLocation,
                        backgroundColor: Colors.white,
                        child: _isGettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: _primaryGreen),
                      ),
                      const SizedBox(height: 8),
                      // Botón Zoom In
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        onPressed: _zoomIn,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.add, color: _primaryGreen),
                      ),
                      const SizedBox(height: 8),
                      // Botón Zoom Out
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        onPressed: _zoomOut,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.remove, color: _primaryGreen),
                      ),
                    ],
                  ),
                ),
                // Indicador de carga
                if (_isLoadingAddress)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Obteniendo dirección...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info de ubicación seleccionada
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubicación seleccionada:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _address ?? 'Toca en el mapa para seleccionar una ubicación',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
