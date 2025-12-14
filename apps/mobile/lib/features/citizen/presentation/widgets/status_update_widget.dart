// lib/features/citizen/presentation/widgets/status_update_widget.dart
// CÓDIGO COMPLETO CORREGIDO - Todos los errores solucionados
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';

class StatusUpdateWidget extends StatefulWidget {
  final ReportEntity report;
  final VoidCallback? onStatusUpdated;

  const StatusUpdateWidget({
    super.key, // Corrección: usar super parámetro
    required this.report,
    this.onStatusUpdated,
  });

  @override
  State<StatusUpdateWidget> createState() => _StatusUpdateWidgetState();
}

class _StatusUpdateWidgetState extends State<StatusUpdateWidget> {
  final _commentController = TextEditingController();
  late String _selectedStatus;
  
  final Map<String, StatusInfo> _statusOptions = {
    'En Revisión': StatusInfo(
      'En Revisión',
      'La denuncia está siendo revisada por el equipo',
      Icons.visibility,
      Colors.orange,
    ),
    'En Proceso': StatusInfo(
      'En Proceso',
      'Se está trabajando en la solución del problema',
      Icons.build,
      Colors.blue,
    ),
    'Completada': StatusInfo(
      'Completada',
      'El problema ha sido solucionado',
      Icons.check_circle,
      AppTheme.successColor,
    ),
    'Rechazada': StatusInfo(
      'Rechazada',
      'La denuncia no procede o no es válida',
      Icons.cancel,
      AppTheme.errorColor,
    ),
    'Archivada': StatusInfo(
      'Archivada',
      'La denuncia ha sido archivada',
      Icons.archive,
      Colors.grey,
    ),
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportDetailLoaded) {
          Navigator.of(context).pop();
          widget.onStatusUpdated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado exitosamente'),
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
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.update, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Actualizar Estado'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
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
                          'Estado actual: ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.report.status).withValues(alpha: 0.2), // Corrección: withOpacity -> withValues
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.report.status,
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
              
              // Selector de estado
              const Text(
                'Nuevo estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Corrección: remover .toList() innecesario en spread
              ..._statusOptions.keys.map((status) => _buildStatusOption(status)),
              
              const SizedBox(height: 20),
              
              // Comentario
              const Text(
                'Comentario (opcional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Agrega un comentario sobre el cambio de estado...',
                  border: OutlineInputBorder(),
                ),
              ),
              
              // Información sobre el estado seleccionado
              if (_selectedStatus != widget.report.status) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedStatus).withValues(alpha: 0.1), // Corrección: withOpacity -> withValues
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(_selectedStatus).withValues(alpha: 0.3), // Corrección: withOpacity -> withValues
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusOptions[_selectedStatus]!.icon,
                        color: _getStatusColor(_selectedStatus),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusOptions[_selectedStatus]!.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(_selectedStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              final isLoading = state is ReportLoading;
              
              return CustomButton(
                text: 'Actualizar',
                isLoading: isLoading,
                onPressed: _updateStatus, // Corrección: siempre pasar la función
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    final info = _statusOptions[status]!;
    final isSelected = _selectedStatus == status;
    final isCurrent = widget.report.status == status;
    
    return GestureDetector(
      onTap: isCurrent ? null : () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? info.color.withValues(alpha: 0.1) // Corrección: withOpacity -> withValues
              : isCurrent
                  ? Colors.grey.shade100
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? info.color
                : isCurrent
                    ? Colors.grey.shade400
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              info.icon,
              color: isCurrent 
                  ? Colors.grey 
                  : isSelected 
                      ? info.color 
                      : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrent 
                          ? Colors.grey 
                          : isSelected 
                              ? info.color 
                              : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Actual',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              )
            else if (isSelected)
              Icon(
                Icons.radio_button_checked,
                color: info.color,
                size: 20,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return _statusOptions[status]?.color ?? Colors.grey;
  }

  void _updateStatus() {
    // Validar que se puede actualizar
    if (_selectedStatus == widget.report.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estado diferente al actual'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // En implementación real, necesitarías obtener el userId del AuthBloc
    const currentUserId = 'current_user_id';
    
    context.read<ReportBloc>().add(
      UpdateReportStatusEvent(
        reportId: widget.report.id,
        status: _selectedStatus,
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        userId: currentUserId,
      ),
    );
  }
}

class StatusInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  StatusInfo(this.name, this.description, this.icon, this.color);
}

// Evento para actualizar estado (agregar a report_event.dart)
class UpdateReportStatusEvent extends ReportEvent {
  final String reportId;
  final String status;
  final String? comment;
  final String userId;
  
  const UpdateReportStatusEvent({
    required this.reportId,
    required this.status,
    this.comment,
    required this.userId,
  });
  
  @override
  List<Object?> get props => [reportId, status, comment, userId];
}