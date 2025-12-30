// lib/features/citizen/presentation/pages/enhanced_create_report_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
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
          appBar: AppBar(
            title: const Text('Nueva Denuncia'),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildBasicInfoStep(),
                    _buildLocationStep(),
                    _buildMediaStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
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
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? AppTheme.successColor 
                        : isActive 
                            ? AppTheme.primaryColor 
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted 
                        ? Icons.check 
                        : _getStepIcon(index),
                    color: isActive || isCompleted ? Colors.white : Colors.grey,
                    size: 16,
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep 
                          ? AppTheme.successColor 
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0: return Icons.description;
      case 1: return Icons.location_on;
      case 2: return Icons.attach_file;
      case 3: return Icons.preview;
      default: return Icons.circle;
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Proporciona los detalles principales de tu denuncia',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Título
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
            const SizedBox(height: 16),
            
            // Categoría
            const Text(
              'Categoría',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Descripción
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
            const SizedBox(height: 16),
            
            // Referencias
            CustomTextField(
              label: 'Referencias (Opcional)',
              hint: 'Ej: Frente al supermercado, cerca de la plaza...',
              controller: _referencesController,
              prefixIcon: Icons.place,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Prioridad
            const Text(
              'Prioridad',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Priority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                return ChoiceChip(
                  label: Text(priority.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPriority = priority;
                      });
                    }
                  },
                  selectedColor: _getPriorityColor(priority).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? _getPriorityColor(priority) 
                        : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
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
          const Text(
            'Ubicación del Problema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona dónde está ocurriendo el problema',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          LocationSelectorWidget(
            initialLocation: _selectedLocation,
            onLocationSelected: (location) {
              setState(() {
                _selectedLocation = location;
              });
            },
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
          const Text(
            'Evidencia Multimedia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega fotos o videos que ayuden a entender el problema',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          MediaAttachmentWidget(
            initialFiles: _attachedFiles,
            onFilesChanged: (files) {
              setState(() {
                _attachedFiles = files;
              });
            },
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
          const Text(
            'Revisar Denuncia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa todos los detalles antes de enviar',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Resumen
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('Título', _titleController.text),
                  _buildReviewItem('Categoría', _selectedCategory),
                  _buildReviewItem('Prioridad', _selectedPriority.displayName),
                  _buildReviewItem('Descripción', _descriptionController.text),
                  if (_referencesController.text.isNotEmpty)
                    _buildReviewItem('Referencias', _referencesController.text),
                  _buildReviewItem('Ubicación', _getLocationDisplay()),
                  _buildReviewItem('Archivos adjuntos', '${_attachedFiles.length} archivo(s)'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Términos y condiciones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Antes de enviar:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Verifica que toda la información sea correcta\n'
                  '• Las denuncias falsas pueden tener consecuencias legales\n'
                  '• Recibirás notificaciones sobre el estado de tu denuncia\n'
                  '• El municipio tiene hasta 30 días para responder',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'No especificado' : value),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Anterior',
                isOutlined: true,
                onPressed: _goToPreviousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (context, state) {
                final isLoading = state is ReportCreating;
                
                return CustomButton(
                  text: _currentStep == 3 ? 'Enviar Denuncia' : 'Siguiente',
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : _currentStep == 3 ? _submitReport : _goToNextStep,
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
        if (_selectedLocation == null) {
          _showErrorSnackBar('Debe seleccionar una ubicación');
          return false;
        }
        return true;
      case 2:
        return true; // Multimedia es opcional
      case 3:
        return true;
      default:
        return true;
    }
  }

  void _submitReport() {
    if (!_validateCurrentStep()) {
      return;
    }

    final params = CreateEnhancedReportParams(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      references: _referencesController.text.trim().isEmpty 
          ? null 
          : _referencesController.text.trim(),
      location: _selectedLocation!,
      userId: widget.userId,
      priority: _selectedPriority,
      attachments: _attachedFiles,
    );

    context.read<ReportBloc>().add(
      CreateReportEvent(params: params),
    );
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
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      case Priority.urgent:
        return Colors.purple;
    }
  }

  void _showSuccessDialog(String reportId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Denuncia Enviada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ID: $reportId',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu denuncia ha sido enviada exitosamente. Recibirás notificaciones sobre su estado.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showValidationErrors(Map<String, String> errors) {
    final errorMessage = errors.values.join('\n');
    _showErrorSnackBar(errorMessage);
  }
}