// lib/features/citizen/presentation/pages/enhanced_create_report_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/enhanced_report_entity.dart';
import '../../domain/usecases/reports/enhanced_report_use_cases.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';
import '../widgets/location_selector_widget.dart';
import '../widgets/media_attachment_widget.dart';

class CreateReportScreen extends StatefulWidget {
  final String userId;

  const CreateReportScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referencesController = TextEditingController();
  final _pageController = PageController();

  late TabController _tabController;
  late ReportBloc _reportBloc;

  String _selectedCategory = '';
  Priority _selectedPriority = Priority.medium;
  LocationData? _selectedLocation;
  // GPS fallback used when user doesn't pick a location on the map
  Position? _gpsPosition;
  List<File> _attachedFiles = [];
  int _currentStep = 0;

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
    _tabController = TabController(length: 4, vsync: this);
    _reportBloc = di.sl<ReportBloc>();
    _selectedCategory = _categories.first;
    _fetchGpsPosition();
  }

  /// Silently fetch GPS so we have coordinates ready when the report is submitted.
  Future<void> _fetchGpsPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _gpsPosition = position);
      }
    } catch (_) {
      // Non-critical — user can still pick location manually on the map
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _referencesController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _reportBloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportCreated) {
            _showSuccessDialog(state.reportId);
          } else if (state is ReportError) {
            _showErrorSnackBar(state.message);
          } else if (state is ReportValidationError) {
            _showValidationErrors(state.errors);
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Nueva Denuncia'),
            backgroundColor: AppTheme.surfaceWhite,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
          ),
          body: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildBasicInfoStep(),
                    _buildLocationStep(),
                    _buildMediaStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                _buildStepCircle(index, isActive, isCompleted),
                if (index < 3)
                  Expanded(
                    child: _buildStepConnector(isCompleted: index < _currentStep),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepCircle(int index, bool isActive, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive || isCompleted
            ? AppTheme.primary.withValues(alpha: 0.15)
            : AppTheme.borderLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive || isCompleted ? AppTheme.primary : AppTheme.border,
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Icon(
        isCompleted ? Icons.check : _getStepIcon(index),
        color: isActive || isCompleted ? AppTheme.primary : AppTheme.textTertiary,
        size: 16,
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.primary : AppTheme.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.description;
      case 1:
        return Icons.location_on;
      case 2:
        return Icons.attach_file;
      case 3:
        return Icons.preview;
      default:
        return Icons.circle;
    }
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTheme.bodyMedium),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepTitle(
              'Información Básica',
              'Proporciona los detalles principales de tu denuncia',
            ),
            const SizedBox(height: 24),

            // Título
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Título de la denuncia',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'Título de la denuncia',
                    hint: 'Ej: Luminaria dañada en calle Principal',
                    controller: _titleController,
                    prefixIcon: Icons.title,
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Categoría
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categoría',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    dropdownColor: AppTheme.surfaceWhite,
                    style: AppTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category, style: AppTheme.bodyLarge),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedCategory = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Descripción
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Descripción detallada',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'Descripción detallada',
                    hint: 'Describe el problema con el mayor detalle posible...',
                    controller: _descriptionController,
                    prefixIcon: Icons.description,
                    maxLines: 5,
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
            ),
            const SizedBox(height: 16),

            // Referencias
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referencias (Opcional)',
                      style: AppTheme.labelLarge.copyWith(color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'Referencias (Opcional)',
                    hint: 'Ej: Frente al supermercado, cerca de la plaza...',
                    controller: _referencesController,
                    prefixIcon: Icons.place,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Prioridad
            Container(
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
                      final pColor = _getPriorityColor(priority);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPriority = priority),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: pColor.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            priority.displayName,
                            style: TextStyle(
                              color: isSelected ? pColor : AppTheme.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Ubicación del Problema',
            'Selecciona dónde está ocurriendo el problema',
          ),
          const SizedBox(height: 24),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(12),
            child: LocationSelectorWidget(
              initialLocation: _selectedLocation,
              onLocationSelected: (location) {
                setState(() => _selectedLocation = location);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Evidencia Multimedia',
            'Agrega fotos o videos que ayuden a entender el problema',
          ),
          const SizedBox(height: 24),
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(12),
            child: MediaAttachmentWidget(
              initialFiles: _attachedFiles,
              onFilesChanged: (files) {
                setState(() => _attachedFiles = files);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'Revisar Denuncia',
            'Revisa todos los detalles antes de enviar',
          ),
          const SizedBox(height: 24),

          // Resumen card
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Resumen',
                        style:
                            AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.divider),
                _buildReviewItem(Icons.title, 'Título', _titleController.text),
                _buildReviewItem(Icons.category, 'Categoría', _selectedCategory),
                _buildReviewItem(
                    Icons.flag, 'Prioridad', _selectedPriority.displayName),
                _buildReviewItem(
                    Icons.description, 'Descripción', _descriptionController.text),
                if (_referencesController.text.isNotEmpty)
                  _buildReviewItem(
                      Icons.place, 'Referencias', _referencesController.text),
                _buildReviewItem(
                    Icons.location_on, 'Ubicación', _getLocationDisplay()),
                _buildReviewItem(Icons.attach_file, 'Archivos adjuntos',
                    '${_attachedFiles.length} archivo(s)'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notice card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.info, size: 18),
                    const SizedBox(width: 8),
                    Text('Antes de enviar:',
                        style: AppTheme.titleSmall
                            .copyWith(color: AppTheme.info)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• Verifica que toda la información sea correcta\n'
                  '• Las denuncias falsas pueden tener consecuencias legales\n'
                  '• Recibirás notificaciones sobre el estado de tu denuncia\n'
                  '• El municipio tiene hasta 30 días para responder',
                  style: AppTheme.bodySmall.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary.withValues(alpha: 0.6), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _goToPreviousStep,
                icon: const Icon(Icons.chevron_left, size: 20),
                label: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (context, state) {
                final isLoading = state is ReportCreating;
                final isLastStep = _currentStep == 3;

                return ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : isLastStep
                          ? _submitReport
                          : _goToNextStep,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isLastStep ? Icons.send : Icons.chevron_right),
                  label: Text(isLoading
                      ? 'Enviando...'
                      : isLastStep
                          ? 'Enviar Denuncia'
                          : 'Siguiente'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextStep() {
    if (_validateCurrentStep()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        if (_selectedLocation == null && _gpsPosition == null) {
          _showErrorSnackBar('Debe seleccionar una ubicación');
          return false;
        }
        return true;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return true;
    }
  }

  void _submitReport() {
    if (!_validateCurrentStep()) return;

    // Use map-selected location, falling back to GPS if available
    final location = _selectedLocation ??
        (_gpsPosition != null
            ? LocationData(
                latitude: _gpsPosition!.latitude,
                longitude: _gpsPosition!.longitude,
                source: LocationSource.gps,
              )
            : null);

    if (location == null) {
      _showErrorSnackBar('No se pudo obtener la ubicación. Selecciona una en el mapa.');
      return;
    }

    final params = CreateEnhancedReportParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      references: _referencesController.text.trim().isEmpty
          ? null
          : _referencesController.text.trim(),
      location: location,
      userId: widget.userId,
      priority: _selectedPriority,
      attachments: _attachedFiles,
    );

    context.read<ReportBloc>().add(CreateReportEvent(params: params));
  }

  String _getLocationDisplay() {
    if (_selectedLocation == null) return 'No seleccionada';

    switch (_selectedLocation!.source) {
      case LocationSource.gps:
        return _selectedLocation!.address ?? 'Ubicación GPS';
      case LocationSource.map:
        return _selectedLocation!.address ?? 'Seleccionada en mapa';
      case LocationSource.manual:
        return _selectedLocation!.manualAddress ?? 'Dirección manual';
    }
  }

  Color _getPriorityColor(Priority priority) {
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 56,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text('¡Denuncia Enviada!', style: AppTheme.headlineSmall),
              const SizedBox(height: 10),
              Text('ID: $reportId', style: AppTheme.bodySmall),
              const SizedBox(height: 12),
              Text(
                'Tu denuncia ha sido enviada exitosamente. Recibirás notificaciones sobre su estado.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
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

  void _showValidationErrors(Map<String, String> errors) {
    final errorMessage = errors.values.join('\n');
    _showErrorSnackBar(errorMessage);
  }
}
