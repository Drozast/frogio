// lib/features/citizen/presentation/widgets/enhanced_report_list_item.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/enhanced_report_entity.dart';

class EnhancedReportListItem extends StatelessWidget {
  final ReportEntity report;
  final VoidCallback onTap;
  final bool showActions;

  const EnhancedReportListItem({
    super.key,
    required this.report,
    required this.onTap,
    this.showActions = false,
  });

  /// Capitaliza la primera letra de cada palabra
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _capitalize(report.title),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 8),
              
              // Categoría y prioridad
              Row(
                children: [
                  _buildCategoryChip(),
                  const SizedBox(width: 8),
                  _buildPriorityChip(),
                ],
              ),
              const SizedBox(height: 8),
              
              // Descripción
              Text(
                report.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer con fecha y acciones
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (report.attachments.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${report.attachments.length}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (report.assignedToId != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.assignedToName ?? 'Inspector asignado',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  
                  if (showActions) ...[
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showActionMenu(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final color = _getStatusColor(report.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        report.status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        _capitalize(report.category),
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip() {
    final color = _getPriorityColor(report.priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        report.priority.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
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
        return Colors.grey.shade600;
      case ReportStatus.duplicate:
        return Colors.amber;
      case ReportStatus.cancelled:
        return Colors.grey.shade500;
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'hace ${difference.inMinutes}m';
      }
      return 'hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                // Navegar a detalles
              },
            ),
            if (report.status == ReportStatus.submitted ||
                report.status == ReportStatus.reviewing) ...[
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Asignar inspector'),
                onTap: () {
                  Navigator.pop(context);
                  // Mostrar diálogo de asignación
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Cambiar estado'),
                onTap: () {
                  Navigator.pop(context);
                  // Mostrar diálogo de cambio de estado
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(context);
                // Mostrar diálogo de respuesta
              },
            ),
          ],
        ),
      ),
    );
  }
}