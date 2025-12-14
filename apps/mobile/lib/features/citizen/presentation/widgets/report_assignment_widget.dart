// lib/features/citizen/presentation/widgets/report_assignment_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';

class ReportAssignmentWidget extends StatefulWidget {
  final ReportEntity report;
  final List<Inspector> availableInspectors;
  final VoidCallback onAssigned;

  const ReportAssignmentWidget({
    super.key,
    required this.report,
    required this.availableInspectors,
    required this.onAssigned,
  });

  @override
  State<ReportAssignmentWidget> createState() => _ReportAssignmentWidgetState();
}

class _ReportAssignmentWidgetState extends State<ReportAssignmentWidget> {
  String? _selectedInspectorId;
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportAssigned) {
          Navigator.of(context).pop();
          widget.onAssigned();
          _showSuccessSnackBar('Reporte asignado exitosamente');
        } else if (state is ReportError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Asignar Reporte'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del reporte
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Estado: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.report.status).withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.report.status.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(widget.report.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Selector de inspector
              const Text(
                'Seleccionar inspector:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedInspectorId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un inspector',
                ),
                items: widget.availableInspectors.map((inspector) {
                  return DropdownMenuItem<String>(
                    value: inspector.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withAlpha(50),
                          child: Text(
                            inspector.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(inspector.name),
                              Text(
                                '${inspector.reportsCount} reportes activos',
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
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un inspector';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedInspectorId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Nota de asignación
              const Text(
                'Nota (opcional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Agregar instrucciones para el inspector...',
                  border: OutlineInputBorder(),
                ),
              ),
              
              // Información sobre el inspector seleccionado
              if (_selectedInspectorId != null) ...[
                const SizedBox(height: 16),
                _buildInspectorInfo(_getSelectedInspector()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              final isLoading = state is ReportAssigning;
              return CustomButton(
                text: 'Asignar',
                isLoading: isLoading,
                onPressed: isLoading || _selectedInspectorId == null
                    ? () {} // Función vacía que no hace nada cuando está deshabilitado
                    : _submitAssignment,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorInfo(Inspector? inspector) {
    if (inspector == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(75),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspector: ${inspector.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Área: ${inspector.area}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Carga actual: ${inspector.reportsCount} reportes activos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Colors.grey;
      case ReportStatus.submitted:
        return Colors.blue;
      case ReportStatus.reviewing:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.purple;
      case ReportStatus.resolved:
        return AppTheme.successColor;
      case ReportStatus.rejected:
        return AppTheme.errorColor;
      case ReportStatus.archived:
        return Colors.grey;
    }
  }

  Inspector? _getSelectedInspector() {
    if (_selectedInspectorId == null) return null;
    return widget.availableInspectors.firstWhere(
      (inspector) => inspector.id == _selectedInspectorId,
      orElse: () => Inspector.empty(),
    );
  }

  void _submitAssignment() {
    if (_formKey.currentState!.validate() && _selectedInspectorId != null) {
      // Obtener el ID del usuario actual desde el AuthBloc
      const currentUserId = 'current_admin_id'; // En implementación real, obtener del AuthBloc
      
      context.read<ReportBloc>().add(
        AssignReportEvent(
          reportId: widget.report.id,
          assignedToId: _selectedInspectorId!,
          assignedById: currentUserId,
          note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        ),
      );
    }
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

// Evento de asignación (que debe estar en el archivo report_event.dart)
class AssignReportEvent extends ReportEvent {
  final String reportId;
  final String assignedToId;
  final String assignedById;
  final String? note;
  
  const AssignReportEvent({
    required this.reportId,
    required this.assignedToId,
    required this.assignedById,
    this.note,
  });
  
  @override
  List<Object?> get props => [reportId, assignedToId, assignedById, note];
}

// Modelo de inspector para la UI
class Inspector {
  final String id;
  final String name;
  final String area;
  final int reportsCount;

  const Inspector({
    required this.id,
    required this.name,
    required this.area,
    required this.reportsCount,
  });

  factory Inspector.empty() {
    return const Inspector(
      id: '',
      name: '',
      area: '',
      reportsCount: 0,
    );
  }
}