// lib/features/citizen/presentation/widgets/enhanced_response_input_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';

class EnhancedResponseInputWidget extends StatefulWidget {
  final String reportId;
  final String currentUserRole;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback? onResponseAdded;

  const EnhancedResponseInputWidget({
    super.key,
    required this.reportId,
    required this.currentUserRole,
    required this.currentUserId,
    required this.currentUserName,
    this.onResponseAdded,
  });

  @override
  State<EnhancedResponseInputWidget> createState() => _EnhancedResponseInputWidgetState();
}

class _EnhancedResponseInputWidgetState extends State<EnhancedResponseInputWidget>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<File> _attachments = [];
  bool _isPublic = true;
  bool _isExpanded = false;
  bool _requiresFollowUp = false;
  String _responseType = 'Información';
  String _urgency = 'Normal';
  
  final List<String> _responseTypes = [
    'Información',
    'Actualización',
    'Solicitud de datos',
    'Confirmación',
    'Cierre',
  ];
  
  final List<String> _urgencyLevels = [
    'Baja',
    'Normal',
    'Alta',
    'Urgente',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportDetailLoaded) {
          _clearForm();
          widget.onResponseAdded?.call();
          _showSuccessSnackBar('Respuesta agregada exitosamente');
        } else if (state is ReportError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isExpanded ? null : 0,
              child: _isExpanded ? _buildExpandedContent() : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.reply,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Responder denuncia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _isExpanded 
                      ? 'Completar respuesta'
                      : 'Tocar para responder esta denuncia',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!_isExpanded)
            TextButton(
              onPressed: _toggleExpanded,
              child: const Text('Responder'),
            )
          else
            IconButton(
              onPressed: _toggleExpanded,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de respuesta y urgencia
              Row(
                children: [
                  Expanded(child: _buildResponseTypeDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUrgencyDropdown()),
                ],
              ),
              const SizedBox(height: 16),
              
              // Mensaje principal
              _buildMessageField(),
              const SizedBox(height: 16),
              
              // Archivos adjuntos
              _buildAttachmentsSection(),
              const SizedBox(height: 16),
              
              // Opciones avanzadas
              _buildAdvancedOptions(),
              const SizedBox(height: 24),
              
              // Botones de acción
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de respuesta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _responseType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _responseTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getResponseTypeIcon(type), size: 16),
                  const SizedBox(width: 8),
                  Text(type, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _responseType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildUrgencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Urgencia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _urgency,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _urgencyLevels.map((urgency) {
            return DropdownMenuItem(
              value: urgency,
              child: Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: _getUrgencyColor(urgency),
                  ),
                  const SizedBox(width: 8),
                  Text(urgency, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _urgency = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mensaje',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: _getMessageHint(),
            border: const OutlineInputBorder(),
            helperText: 'Mínimo 10 caracteres',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El mensaje es requerido';
            }
            if (value.trim().length < 10) {
              return 'El mensaje debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Archivos adjuntos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            if (_attachments.length < 3) ...[
              IconButton(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 20),
                tooltip: 'Tomar foto',
              ),
              IconButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 20),
                tooltip: 'Seleccionar imagen',
              ),
            ],
          ],
        ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                return _buildAttachmentPreview(index);
              },
            ),
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(Icons.attachment, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Opcional: agregar fotos de evidencia',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentPreview(int index) {
    final file = _attachments[index];
    
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeAttachment(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opciones adicionales',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Visibilidad
          Row(
            children: [
              Switch(
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPublic ? 'Respuesta pública' : 'Respuesta privada',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      _isPublic
                          ? 'Visible para el ciudadano'
                          : 'Solo visible para el equipo municipal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Seguimiento
          CheckboxListTile(
            title: const Text('Requiere seguimiento'),
            subtitle: const Text('Programar revisión posterior'),
            value: _requiresFollowUp,
            onChanged: (value) {
              setState(() {
                _requiresFollowUp = value!;
              });
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearForm,
            child: const Text('Limpiar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              final isLoading = state is ReportLoading;
              return CustomButton(
                text: 'Enviar Respuesta',
                isLoading: isLoading,
                onPressed: isLoading ? () {} : _submitResponse,
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMessageHint() {
    switch (_responseType) {
      case 'Información':
        return 'Proporciona información sobre el estado actual...';
      case 'Actualización':
        return 'Describe los avances realizados...';
      case 'Solicitud de datos':
        return 'Especifica qué información adicional necesitas...';
      case 'Confirmación':
        return 'Confirma la recepción o completación...';
      case 'Cierre':
        return 'Explica la resolución del problema...';
      default:
        return 'Escribe tu respuesta...';
    }
  }

  IconData _getResponseTypeIcon(String type) {
    switch (type) {
      case 'Información': return Icons.info;
      case 'Actualización': return Icons.update;
      case 'Solicitud de datos': return Icons.help;
      case 'Confirmación': return Icons.check;
      case 'Cierre': return Icons.close;
      default: return Icons.message;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Baja': return Colors.green;
      case 'Normal': return Colors.blue;
      case 'Alta': return Colors.orange;
      case 'Urgente': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _attachments.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _submitResponse() {
    if (_formKey.currentState!.validate()) {
      context.read<ReportBloc>().add(
        AddReportResponseEvent(
          reportId: widget.reportId,
          responderId: widget.currentUserId,
          responderName: widget.currentUserName,
          message: _messageController.text.trim(),
          attachments: _attachments.isEmpty ? null : _attachments,
          isPublic: _isPublic,
        ),
      );
    }
  }

  void _clearForm() {
    _messageController.clear();
    setState(() {
      _attachments.clear();
      _isPublic = true;
      _requiresFollowUp = false;
      _responseType = 'Información';
      _urgency = 'Normal';
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
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
}