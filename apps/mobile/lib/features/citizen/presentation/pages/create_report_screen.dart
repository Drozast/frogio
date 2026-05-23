// lib/features/citizen/presentation/pages/create_report_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/enhanced_report_entity.dart';
import '../../domain/usecases/reports/enhanced_report_use_cases.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';

class CreateReportScreen extends StatefulWidget {
  final String userId;

  const CreateReportScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referencesController = TextEditingController();

  String _selectedCategory = 'Infraestructura';
  LocationData? _selectedLocation;
  final List<File> _selectedImages = [];

  late ReportBloc _reportBloc;

  final List<String> _categories = [
    'Infraestructura',
    'Seguridad',
    'Medio Ambiente',
    'Servicios Públicos',
    'Transporte',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportBloc,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Nueva Denuncia'),
          backgroundColor: AppTheme.surfaceWhite,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: BlocListener<ReportBloc, ReportState>(
          listener: (context, state) {
            if (state is ReportCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Denuncia creada exitosamente'),
                  backgroundColor: AppTheme.success,
                ),
              );
              Navigator.pop(context, true);
            } else if (state is ReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.emergency,
                ),
              );
            }
          },
          child: BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfo(),
                            const SizedBox(height: 24),
                            _buildCategorySection(),
                            const SizedBox(height: 24),
                            _buildLocationSection(),
                            const SizedBox(height: 24),
                            _buildImagesSection(),
                            const SizedBox(height: 24),
                            _buildReferencesSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButtons(state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTheme.titleMedium.copyWith(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Básica'),
          CustomTextField(
            label: 'Título',
            hint: 'Resumen breve del problema',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es requerido';
              }
              if (value.trim().length < 5) {
                return 'El título debe tener al menos 5 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Descripción',
            hint: 'Describe el problema en detalle',
            controller: _descriptionController,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La descripción es requerida';
              }
              if (value.trim().length < 20) {
                return 'La descripción debe tener al menos 20 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Categoría'),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            dropdownColor: AppTheme.surfaceWhite,
            style: AppTheme.bodyLarge,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category, style: AppTheme.bodyLarge),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ubicación'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedLocation != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Ubicación seleccionada:',
                        style: AppTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLocation!.address ??
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: AppTheme.bodySmall,
                  ),
                ] else
                  Text(
                    'No se ha seleccionado ubicación',
                    style: AppTheme.bodyMedium,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _selectLocation,
                    icon: const Icon(Icons.map),
                    label: Text(_selectedLocation != null
                        ? 'Cambiar ubicación'
                        : 'Seleccionar ubicación'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imágenes (Opcional)'),
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.emergency,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferencesSection() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Referencias Adicionales (Opcional)'),
          CustomTextField(
            label: 'Referencias',
            hint: 'Información adicional, números de ordenanza, etc.',
            controller: _referencesController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ReportState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: const Border(
          top: BorderSide(color: AppTheme.border, width: 1),
        ),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: state is ReportCreating
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state is ReportCreating ? null : _submitReport,
              icon: state is ReportCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(
                  state is ReportCreating ? 'Enviando...' : 'Crear Denuncia'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation() async {
    await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          onLocationSelected: (location, address) {
            setState(() {
              _selectedLocation = LocationData(
                latitude: location.latitude,
                longitude: location.longitude,
                address: address,
                source: LocationSource.map,
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: AppTheme.emergency,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final params = CreateEnhancedReportParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      references: _referencesController.text.trim().isNotEmpty
          ? _referencesController.text.trim()
          : null,
      location: _selectedLocation!,
      userId: widget.userId,
      priority: Priority.medium,
      attachments: _selectedImages,
    );

    _reportBloc.add(CreateReportEvent(params: params));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referencesController.dispose();
    super.dispose();
  }
}
