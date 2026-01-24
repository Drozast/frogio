// lib/features/citizen/presentation/pages/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String? currentUserRole;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
    this.currentUserRole,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late ReportBloc _reportBloc;

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _reportBloc.add(GetReportByIdEvent(reportId: widget.reportId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Denuncia'),
          elevation: 0,
        ),
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ReportLoaded) {
              return _buildReportDetail(state.report);
            } else if (state is ReportError) {
              return _buildErrorState(state.message);
            } else {
              return const Center(
                child: Text('No se pudo cargar la información'),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportDetail(ReportEntity report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(report),
          const SizedBox(height: 24),
          // Seguimiento visual del estado
          _buildStatusTracker(report),
          const SizedBox(height: 24),
          _buildBasicInfo(report),
          const SizedBox(height: 24),
          _buildLocation(report),
          if (report.attachments.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAttachments(report),
          ],
          if (report.responses.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildResponses(report),
          ],
          const SizedBox(height: 24),
          _buildStatusHistory(report),
        ],
      ),
    );
  }

  Widget _buildHeader(ReportEntity report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              _buildStatusChip(report.status),
            ],
          ),
          const SizedBox(height: 8),
          _buildCategoryChip(report.category),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Creado: ${_formatDate(report.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (report.assignedToName != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asignado a: ${report.assignedToName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(ReportEntity report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: const TextStyle(fontSize: 14),
            ),
            if (report.references != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Referencias',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                report.references!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocation(ReportEntity report) {
    final location = LatLng(report.location.latitude, report.location.longitude);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Ubicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (report.location.address != null)
              Text(
                report.location.address!,
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 4),
            Text(
              'Lat: ${report.location.latitude.toStringAsFixed(6)}, '
              'Lng: ${report.location.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            // Mapa interactivo
            GestureDetector(
              onTap: () => _showFullscreenMap(location, report.location.address),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: location,
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.frogio.santajuana',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: location,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryColor,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Indicador para expandir
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fullscreen, size: 16, color: AppTheme.primaryColor),
                              SizedBox(width: 4),
                              Text(
                                'Ampliar',
                                style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenMap(LatLng location, String? address) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ubicación del Reporte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (address != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade100,
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.frogio.santajuana',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(ReportEntity report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_file, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Archivos Adjuntos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: report.attachments.length,
                itemBuilder: (context, index) {
                  final attachment = report.attachments[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _showAttachment(attachment),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: attachment.type == MediaType.image
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  attachment.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.play_circle_filled, size: 40),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponses(ReportEntity report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.reply, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Respuestas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...report.responses.map((response) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          response.responderName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(response.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(response.message),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistory(ReportEntity report) {
    final historyItems = report.statusHistory.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Historial de Estados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (historyItems.isEmpty)
              const Text(
                'Sin historial de cambios',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...historyItems.asMap().entries.map((entry) {
                final index = entry.key;
                final historyItem = entry.value;
                final isLast = index == historyItems.length - 1;
                final color = _getStatusColor(historyItem.status);

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline visual
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isLast ? color : color.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color,
                                width: 2,
                              ),
                            ),
                            child: isLast
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: color.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Contenido
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isLast ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLast ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(historyItem.status),
                                    size: 16,
                                    color: color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      historyItem.status.displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLast ? color : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (isLast)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Actual',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(historyItem.timestamp),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              if (historyItem.comment != null && historyItem.comment!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          historyItem.comment!,
                                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (historyItem.userName != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      historyItem.userName!,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return Icons.edit_note;
      case ReportStatus.submitted:
        return Icons.send;
      case ReportStatus.reviewing:
        return Icons.search;
      case ReportStatus.inProgress:
        return Icons.engineering;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
      case ReportStatus.archived:
        return Icons.archive;
    }
  }

  Widget _buildStatusTracker(ReportEntity report) {
    // Estados en orden de progreso
    final statusOrder = [
      ReportStatus.submitted,
      ReportStatus.reviewing,
      ReportStatus.inProgress,
      ReportStatus.resolved,
    ];

    final currentStatusIndex = statusOrder.indexOf(report.status);
    final isRejected = report.status == ReportStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.track_changes, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Seguimiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isRejected)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este reporte ha sido rechazado',
                        style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: statusOrder.asMap().entries.map((entry) {
                  final index = entry.key;
                  final status = entry.value;
                  final isCompleted = currentStatusIndex >= index;
                  final isCurrent = currentStatusIndex == index;
                  final isLast = index == statusOrder.length - 1;
                  final color = isCompleted ? _getStatusColor(status) : Colors.grey.shade300;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              // Círculo de estado
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isCurrent ? 40 : 32,
                                height: isCurrent ? 40 : 32,
                                decoration: BoxDecoration(
                                  color: isCompleted ? color : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color,
                                    width: isCurrent ? 3 : 2,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  size: isCurrent ? 20 : 16,
                                  color: isCompleted ? Colors.white : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Etiqueta
                              Text(
                                _getShortStatusName(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: isCompleted ? color : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        // Línea conectora
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: currentStatusIndex > index
                                    ? _getStatusColor(statusOrder[index + 1])
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _getShortStatusName(ReportStatus status) {
    switch (status) {
      case ReportStatus.draft:
        return 'Borrador';
      case ReportStatus.submitted:
        return 'Enviado';
      case ReportStatus.reviewing:
        return 'Revisión';
      case ReportStatus.inProgress:
        return 'En Proceso';
      case ReportStatus.resolved:
        return 'Resuelto';
      case ReportStatus.rejected:
        return 'Rechazado';
      case ReportStatus.archived:
        return 'Archivado';
    }
  }

  Widget _buildStatusChip(ReportStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.blue.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _reportBloc.add(GetReportByIdEvent(reportId: widget.reportId));
            },
            child: const Text('Reintentar'),
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
        return Colors.grey.shade600;
    }
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAttachment(MediaAttachment attachment) {
    // Implementar visualización de archivos adjuntos
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attachment.fileName),
        content: attachment.type == MediaType.image
            ? Image.network(attachment.url)
            : const Text('Vista previa de video no disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}