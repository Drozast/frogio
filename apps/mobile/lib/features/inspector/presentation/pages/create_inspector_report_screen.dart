// lib/features/inspector/presentation/pages/create_inspector_report_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../citizen/domain/entities/enhanced_report_entity.dart';
import '../../../citizen/domain/usecases/reports/enhanced_report_use_cases.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_bloc.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_event.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_state.dart';
import '../../../citizen/presentation/widgets/location_selector_widget.dart';
import '../../../citizen/presentation/widgets/media_attachment_widget.dart';

/// Simplified report creation screen for inspectors.
/// Unlike the citizen stepper, this is a single scrollable form with
/// GPS auto-loaded, priority defaulting to high, and inspector context.
class CreateInspectorReportScreen extends StatefulWidget {
  final String inspectorId;

  const CreateInspectorReportScreen({
    super.key,
    required this.inspectorId,
  });

  @override
  State<CreateInspectorReportScreen> createState() =>
      _CreateInspectorReportScreenState();
}

class _CreateInspectorReportScreenState
    extends State<CreateInspectorReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referencesController = TextEditingController();
  final _addressController = TextEditingController();

  late ReportBloc _reportBloc;

  String _selectedCategory = 'Seguridad Pública';
  Priority _selectedPriority = Priority.high;
  LocationData? _selectedLocation;
  Position? _gpsPosition;
  bool _gpsLoading = true;
  List<File> _attachedFiles = [];

  final List<String> _categories = [
    'Alumbrado Público',
    'Basura y Limpieza',
    'Calles y Veredas',
    'Seguridad Pública',
    'Áreas Verdes',
    'Tránsito',
    'Ruido',
    'Animales',
    'Infraestructura',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _fetchGpsPosition();
  }

  Future<void> _fetchGpsPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gpsLoading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _gpsPosition = position;
          _gpsLoading = false;
          // Auto-select GPS location so the inspector doesn't have to pick manually
          _selectedLocation = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            source: LocationSource.gps,
          );
        });
      }
    } catch (_) {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referencesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _reportBloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportCreated) {
            _showSuccessDialog(state.reportId);
          } else if (state is ReportError) {
            _showErrorSnackBar(state.message);
          } else if (state is ReportValidationError) {
            _showErrorSnackBar(state.errors.values.join('\n'));
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Nueva Denuncia', style: TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            actions: [
              BlocBuilder<ReportBloc, ReportState>(
                builder: (context, state) {
                  final isLoading = state is ReportCreating;
                  return TextButton.icon(
                    onPressed: isLoading ? null : _submitReport,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                    label: Text(
                      isLoading ? 'Enviando...' : 'Enviar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInspectorBadge(),
                  const SizedBox(height: 16),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildCategoryField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildReferencesField(),
                  const SizedBox(height: 16),
                  _buildPriorityField(),
                  const SizedBox(height: 16),
                  _buildLocationSection(),
                  const SizedBox(height: 16),
                  _buildMediaSection(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: const Color(0xFF1B5E20).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_rounded, color: Color(0xFF1B5E20), size: 18),
          const SizedBox(width: 10),
          Text(
            'Denuncia de Inspector',
            style: AppTheme.labelMedium.copyWith(color: const Color(0xFF1B5E20)),
          ),
          const Spacer(),
          _buildGpsIndicator(),
        ],
      ),
    );
  }

  Widget _buildGpsIndicator() {
    if (_gpsLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Text('GPS...', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
        ],
      );
    }
    if (_gpsPosition != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, color: AppTheme.success, size: 14),
          const SizedBox(width: 4),
          Text('GPS activo', style: AppTheme.labelSmall.copyWith(color: AppTheme.success)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_off, color: AppTheme.textTertiary, size: 14),
        const SizedBox(width: 4),
        Text('Sin GPS', style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary)),
      ],
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Título *',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Título de la denuncia',
            hint: 'Ej: Luminaria dañada en calle Principal',
            controller: _titleController,
            prefixIcon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'El título es requerido';
              if (value.trim().length < 5) return 'Mínimo 5 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categoría *',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            dropdownColor: AppTheme.surfaceWhite,
            style: AppTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTheme.bodyLarge)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descripción *',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Descripción detallada',
            hint: 'Describe el problema con detalle...',
            controller: _descriptionController,
            prefixIcon: Icons.description,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'La descripción es requerida';
              if (value.trim().length < 20) return 'Mínimo 20 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReferencesField() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Referencias (Opcional)',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 8),
          CustomTextField(
            label: 'Referencias',
            hint: 'Ej: Frente al supermercado, cerca de la plaza...',
            controller: _referencesController,
            prefixIcon: Icons.place,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityField() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prioridad',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Priority.values.map((priority) {
              final isSelected = _selectedPriority == priority;
              final pColor = _priorityColor(priority);
              return GestureDetector(
                onTap: () => setState(() => _selectedPriority = priority),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? pColor.withValues(alpha: 0.12)
                        : AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? pColor.withValues(alpha: 0.7)
                          : AppTheme.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    priority.displayName,
                    style: TextStyle(
                      color: isSelected ? pColor : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
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
          Row(
            children: [
              Text('Ubicación *',
                  style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
              const Spacer(),
              if (_gpsPosition != null && _selectedLocation?.source == LocationSource.gps)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.success, size: 12),
                      const SizedBox(width: 4),
                      Text('GPS',
                          style: AppTheme.labelSmall
                              .copyWith(color: AppTheme.success)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LocationSelectorWidget(
            initialLocation: _selectedLocation,
            onLocationSelected: (location) {
              setState(() => _selectedLocation = location);
              if (location.address != null && _addressController.text.isEmpty) {
                _addressController.text = location.address!;
              }
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Direccion',
            hint: 'Ej: Calle Principal 123, Santa Juana',
            controller: _addressController,
            prefixIcon: Icons.edit_location_alt_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidencia (Opcional)',
              style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 12),
          MediaAttachmentWidget(
            initialFiles: _attachedFiles,
            onFilesChanged: (files) {
              setState(() => _attachedFiles = files);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        final isLoading = state is ReportCreating;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isLoading ? null : _submitReport,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(isLoading ? 'Enviando...' : 'Enviar Denuncia'),
          ),
        );
      },
    );
  }

  void _submitReport() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    var location = _selectedLocation ??
        (_gpsPosition != null
            ? LocationData(
                latitude: _gpsPosition!.latitude,
                longitude: _gpsPosition!.longitude,
                source: LocationSource.gps,
              )
            : null);

    if (location == null) {
      _showErrorSnackBar('Selecciona una ubicación en el mapa');
      return;
    }

    // Add address if provided
    final addressText = _addressController.text.trim();
    if (addressText.isNotEmpty && location.address == null) {
      location = LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: addressText,
        source: location.source,
      );
    }

    final params = CreateEnhancedReportParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      references: _referencesController.text.trim().isEmpty
          ? null
          : _referencesController.text.trim(),
      location: location,
      userId: widget.inspectorId,
      priority: _selectedPriority,
      attachments: _attachedFiles,
    );

    context.read<ReportBloc>().add(CreateReportEvent(params: params));
  }

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppTheme.success;
      case Priority.medium:
        return AppTheme.warning;
      case Priority.high:
        return AppTheme.emergency;
      case Priority.urgent:
        return AppTheme.emergencyDark;
    }
  }

  void _showSuccessDialog(String reportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Denuncia Registrada', style: AppTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('ID: $reportId',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              const Text(
                'La denuncia ha sido creada y asignada a tu perfil de inspector.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to reports list
                  },
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.emergency,
      ),
    );
  }
}
