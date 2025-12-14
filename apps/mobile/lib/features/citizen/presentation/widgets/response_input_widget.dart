// lib/features/citizen/presentation/widgets/response_input_widget.dart
// CÓDIGO COMPLETO CORREGIDO - Todos los errores solucionados
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';

class ResponseInputWidget extends StatefulWidget {
  final String reportId;
  final VoidCallback? onResponseAdded;

  const ResponseInputWidget({
    super.key,
    required this.reportId,
    this.onResponseAdded,
  });

  @override
  State<ResponseInputWidget> createState() => _ResponseInputWidgetState();
}

class _ResponseInputWidgetState extends State<ResponseInputWidget> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  final List<File> _attachments = [];
  bool _isPublic = true;
  bool _isExpanded = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportDetailLoaded) {
          _clearForm();
          widget.onResponseAdded?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Respuesta agregada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else if (state is ReportError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2), // Corrección: withOpacity -> withValues
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.reply,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Responder denuncia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isExpanded 
                          ? Icons.keyboard_arrow_down 
                          : Icons.keyboard_arrow_up,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ],
              ),
              
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message input
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu respuesta...',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 16),
                      
                      // Attachments
                      if (_attachments.isNotEmpty) ...[
                        const Text(
                          'Archivos adjuntos:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_attachments.length, (index) {
                            return _buildAttachmentChip(index);
                          }),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Action buttons
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Cámara'),
                          ),
                          TextButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galería'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Privacy toggle
                      Row(
                        children: [
                          Switch(
                            value: _isPublic,
                            onChanged: (value) {
                              setState(() {
                                _isPublic = value;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPublic ? 'Respuesta pública' : 'Respuesta privada',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                      const SizedBox(height: 16),
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: BlocBuilder<ReportBloc, ReportState>(
                          builder: (context, state) {
                            final isLoading = state is ReportLoading;
                            return CustomButton(
                              text: 'Enviar Respuesta',
                              isLoading: isLoading,
                              onPressed: _submitResponse, // Corrección: directamente la función
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Collapsed view
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Toca para responder esta denuncia...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(int index) {
    final file = _attachments[index];
    final fileName = file.path.split('/').last;
    
    return Chip(
      label: Text(
        fileName.length > 20 
            ? '${fileName.substring(0, 20)}...' 
            : fileName,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _attachments.removeAt(index);
        });
      },
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), // Corrección: withOpacity -> withValues
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _attachments.add(File(image.path));
        });
      }
    } catch (e) {
      // Corrección: Verificar mounted antes de usar BuildContext
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _submitResponse() {
    if (_formKey.currentState!.validate()) {
      // En implementación real, obtener del AuthBloc
      const currentUserId = 'current_user_id';
      const currentUserName = 'Inspector/Admin';
      
      context.read<ReportBloc>().add(
        AddReportResponseEvent(
          reportId: widget.reportId,
          responderId: currentUserId,
          responderName: currentUserName,
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
      _isExpanded = false;
    });
  }
}

// Eventos adicionales para report_event.dart
class AddReportResponseEvent extends ReportEvent {
  final String reportId;
  final String responderId;
  final String responderName;
  final String message;
  final List<File>? attachments;
  final bool isPublic;
  
  const AddReportResponseEvent({
    required this.reportId,
    required this.responderId,
    required this.responderName,
    required this.message,
    this.attachments,
    this.isPublic = true,
  });
  
  @override
  List<Object?> get props => [reportId, responderId, responderName, message, attachments, isPublic];
}