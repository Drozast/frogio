// lib/features/citizen/presentation/widgets/enhanced_status_update_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/report_entity.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';

class EnhancedStatusUpdateWidget extends StatefulWidget {
  final ReportEntity report;
  final String currentUserRole;
  final String currentUserId;
  final VoidCallback? onStatusUpdated;

  const EnhancedStatusUpdateWidget({
    super.key,
    required this.report,
    required this.currentUserRole,
    required this.currentUserId,
    this.onStatusUpdated,
  });

  @override
  State<EnhancedStatusUpdateWidget> createState() =>
      _EnhancedStatusUpdateWidgetState();
}

class _EnhancedStatusUpdateWidgetState extends State<EnhancedStatusUpdateWidget>
    with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late String _selectedStatus;
  DateTime? _estimatedCompletion;
  String _priority = 'Normal';
  bool _notifyCitizen = true;
  bool _requiresInspection = false;

  final Map<String, StatusInfo> _statusOptions = {
    'Recibida': StatusInfo(
      'Recibida',
      'La denuncia ha sido recibida y registrada',
      Icons.inbox,
      Colors.blue,
      ['admin', 'inspector'],
    ),
    'En Revisión': StatusInfo(
      'En Revisión',
      'La denuncia está siendo evaluada por el equipo técnico',
      Icons.visibility,
      Colors.orange,
      ['admin', 'inspector'],
    ),
    'Asignada': StatusInfo(
      'Asignada',
      'La denuncia ha sido asignada a un inspector',
      Icons.person_add,
      Colors.purple,
      ['admin'],
    ),
    'En Proceso': StatusInfo(
      'En Proceso',
      'Se está trabajando activamente en la solución',
      Icons.build,
      Colors.blue,
      ['admin', 'inspector'],
    ),
    'Pendiente de Materiales': StatusInfo(
      'Pendiente de Materiales',
      'En espera de materiales o recursos necesarios',
      Icons.inventory,
      Colors.amber,
      ['admin', 'inspector'],
    ),
    'Requiere Inspección': StatusInfo(
      'Requiere Inspección',
      'Necesita inspección técnica adicional',
      Icons.search,
      Colors.indigo,
      ['admin', 'inspector'],
    ),
    'Completada': StatusInfo(
      'Completada',
      'El problema ha sido solucionado exitosamente',
      Icons.check_circle,
      AppTheme.successColor,
      ['admin', 'inspector'],
    ),
    'Rechazada': StatusInfo(
      'Rechazada',
      'La denuncia no procede según normativas',
      Icons.cancel,
      AppTheme.errorColor,
      ['admin'],
    ),
    'Derivada': StatusInfo(
      'Derivada',
      'Derivada a otra entidad competente',
      Icons.forward,
      Colors.teal,
      ['admin'],
    ),
    'Archivada': StatusInfo(
      'Archivada',
      'La denuncia ha sido archivada',
      Icons.archive,
      Colors.grey,
      ['admin'],
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedStatus = widget.report.status;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportBloc, ReportState>(
      listener: (context, state) {
        if (state is ReportDetailLoaded) {
          Navigator.of(context).pop();
          widget.onStatusUpdated?.call();
          _showSuccessSnackBar('Estado actualizado exitosamente');
        } else if (state is ReportError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildReportInfo(),
              const SizedBox(height: 16),
              _buildTabBar(),
              Expanded(child: _buildTabView()),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.update,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actualizar Estado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cambia el estado y agrega comentarios',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildReportInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.report.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.report.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.report.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(widget.report.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.report.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${widget.report.id.substring(0, 8)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryColor,
      tabs: const [
        Tab(text: 'Estado', icon: Icon(Icons.update)),
        Tab(text: 'Detalles', icon: Icon(Icons.settings)),
      ],
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildStatusTab(),
        _buildDetailsTab(),
      ],
    );
  }

  Widget _buildStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar nuevo estado:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ..._getAvailableStatuses()
              .map((status) => _buildStatusOption(status))
              ,
          const SizedBox(height: 24),
          const Text(
            'Comentario:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Agrega detalles sobre el cambio de estado...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedStatus != widget.report.status &&
                    (value == null || value.trim().isEmpty)) {
                  return 'El comentario es requerido al cambiar el estado';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prioridad
          const Text(
            'Prioridad:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: ['Baja', 'Normal', 'Alta', 'Urgente'].map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      color: _getPriorityColor(priority),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(priority),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _priority = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Fecha estimada de finalización
          const Text(
            'Fecha estimada de finalización:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectEstimatedCompletion,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    _estimatedCompletion != null
                        ? DateFormat('dd/MM/yyyy').format(_estimatedCompletion!)
                        : 'Seleccionar fecha',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Opciones adicionales
          CheckboxListTile(
            title: const Text('Notificar al ciudadano'),
            subtitle: const Text('Enviar notificación sobre el cambio'),
            value: _notifyCitizen,
            onChanged: (value) {
              setState(() {
                _notifyCitizen = value!;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),

          CheckboxListTile(
            title: const Text('Requiere inspección adicional'),
            subtitle: const Text('Programar visita técnica'),
            value: _requiresInspection,
            onChanged: (value) {
              setState(() {
                _requiresInspection = value!;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    final info = _statusOptions[status]!;
    final isSelected = _selectedStatus == status;
    final isCurrent = widget.report.status == status;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrent
              ? null
              : () {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? info.color.withValues(alpha: 0.1)
                  : isCurrent
                      ? Colors.grey.shade100
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    info.icon,
                    color: info.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              final isLoading = state is ReportLoading;
              return CustomButton(
                text: 'Actualizar Estado',
                isLoading: isLoading,
                onPressed:
                    (isLoading || _selectedStatus == widget.report.status)
                        ? () {} // ✅ Correcto - función vacía
                        : _updateStatus,
              );
            },
          ),
        ),
      ],
    );
  }

  List<String> _getAvailableStatuses() {
    return _statusOptions.entries
        .where((entry) =>
            entry.value.allowedRoles.contains(widget.currentUserRole))
        .map((entry) => entry.key)
        .toList();
  }

  Color _getStatusColor(String status) {
    return _statusOptions[status]?.color ?? Colors.grey;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Baja':
        return Colors.green;
      case 'Normal':
        return Colors.blue;
      case 'Alta':
        return Colors.orange;
      case 'Urgente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Baja':
        return Icons.arrow_downward;
      case 'Normal':
        return Icons.remove;
      case 'Alta':
        return Icons.arrow_upward;
      case 'Urgente':
        return Icons.priority_high;
      default:
        return Icons.help;
    }
  }

  Future<void> _selectEstimatedCompletion() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _estimatedCompletion ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _estimatedCompletion = picked;
      });
    }
  }

  void _updateStatus() {
    if (_formKey.currentState!.validate()) {
      context.read<ReportBloc>().add(
            UpdateReportStatusEvent(
              reportId: widget.report.id,
              status: _selectedStatus,
              comment: _commentController.text.trim().isEmpty
                  ? null
                  : _commentController.text.trim(),
              userId: widget.currentUserId,
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

class StatusInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> allowedRoles;

  StatusInfo(
      this.name, this.description, this.icon, this.color, this.allowedRoles);
}
