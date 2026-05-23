// lib/features/citizen/presentation/pages/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frogio_mobile/core/services/maps_service.dart';

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
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Detalle de Denuncia'),
          backgroundColor: AppTheme.surfaceWhite,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            } else if (state is ReportLoaded) {
              return _buildReportDetail(state.report);
            } else if (state is ReportError) {
              return _buildErrorState(state.message);
            } else {
              return Center(
                child: Text(
                  'No se pudo cargar la información',
                  style: AppTheme.bodyMedium,
                ),
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(ReportEntity report) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: AppTheme.titleLarge.copyWith(color: AppTheme.primary),
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
              const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Creado: ${_formatDate(report.createdAt)}',
                style: AppTheme.bodySmall,
              ),
              if (report.assignedToName != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Asignado a: ${report.assignedToName}',
                    style: AppTheme.bodySmall,
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
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descripción',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
          const Divider(color: AppTheme.divider),
          Text(report.description, style: AppTheme.bodyLarge),
          if (report.references != null) ...[
            const SizedBox(height: 16),
            Text('Referencias',
                style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
            const SizedBox(height: 8),
            Text(report.references!, style: AppTheme.bodyLarge),
          ],
        ],
      ),
    );
  }

  Widget _buildLocation(ReportEntity report) {
    final location = LatLng(report.location.latitude, report.location.longitude);

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Ubicación',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
            ],
          ),
          const Divider(color: AppTheme.divider),
          if (report.location.address != null)
            Text(report.location.address!, style: AppTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            'Lat: ${report.location.latitude.toStringAsFixed(6)}, '
            'Lng: ${report.location.longitude.toStringAsFixed(6)}',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullscreenMap(location, report.location.address),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.shadowSmall,
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
                          urlTemplate: MapsService.tileServerUrl,
                          tileProvider: MapsService.tileProvider,
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
                                color: AppTheme.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, size: 16, color: AppTheme.primary),
                            SizedBox(width: 4),
                            Text('Ampliar',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.primary)),
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
    );
  }

  void _showFullscreenMap(LatLng location, String? address) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Ubicación del Reporte', style: AppTheme.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (address != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppTheme.surface,
                child: Text(address, style: AppTheme.bodyMedium),
              ),
            SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(initialCenter: location, initialZoom: 16),
                children: [
                  TileLayer(
                    urlTemplate: MapsService.tileServerUrl,
                    tileProvider: MapsService.tileProvider,
                    userAgentPackageName: 'com.frogio.santajuana',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on, color: AppTheme.primary, size: 50),
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
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Archivos Adjuntos',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
            ],
          ),
          const Divider(color: AppTheme.divider),
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
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: attachment.type == MediaType.image
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                attachment.url,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: AppTheme.emergency),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.play_circle_filled,
                                  size: 40, color: AppTheme.primary),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponses(ReportEntity report) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.reply, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Respuestas',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
            ],
          ),
          const Divider(color: AppTheme.divider),
          ...report.responses.map((response) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(response.responderName, style: AppTheme.titleSmall),
                          const Spacer(),
                          Text(_formatDate(response.createdAt), style: AppTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(response.message, style: AppTheme.bodyMedium),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(ReportEntity report) {
    final historyItems = report.statusHistory.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Historial de Estados',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
            ],
          ),
          const Divider(color: AppTheme.divider),
          if (historyItems.isEmpty)
            Text('Sin historial de cambios', style: AppTheme.bodyMedium)
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
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isLast
                                ? color.withValues(alpha: 0.15)
                                : AppTheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                            boxShadow: isLast
                                ? [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.25),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                          child: isLast
                              ? Icon(Icons.check, size: 14, color: color)
                              : null,
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: AppTheme.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isLast
                              ? color.withValues(alpha: 0.06)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isLast
                                ? color.withValues(alpha: 0.25)
                                : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_getStatusIcon(historyItem.status),
                                    size: 16, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    historyItem.status.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isLast ? color : AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isLast)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Actual',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_formatDate(historyItem.timestamp),
                                style: AppTheme.bodySmall),
                            if (historyItem.comment != null &&
                                historyItem.comment!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceWhite,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.comment,
                                        size: 14, color: AppTheme.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        historyItem.comment!,
                                        style: AppTheme.bodySmall.copyWith(
                                            fontStyle: FontStyle.italic),
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
                                  const Icon(Icons.person,
                                      size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(historyItem.userName!,
                                      style: AppTheme.labelSmall),
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
    );
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return Icons.send;
      case ReportStatus.enProceso:
        return Icons.engineering;
      case ReportStatus.resuelto:
        return Icons.check_circle;
      case ReportStatus.rechazado:
        return Icons.cancel;
    }
  }

  Widget _buildStatusTracker(ReportEntity report) {
    final statusOrder = [
      ReportStatus.pendiente,
      ReportStatus.enProceso,
      ReportStatus.resuelto,
    ];

    final currentStatusIndex = statusOrder.indexOf(report.status);
    final isRejected = report.status == ReportStatus.rechazado;

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Seguimiento',
                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
            ],
          ),
          const Divider(color: AppTheme.divider),
          if (isRejected)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.emergencyLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: AppTheme.emergency),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este reporte ha sido rechazado',
                      style: TextStyle(
                          color: AppTheme.emergency, fontWeight: FontWeight.bold),
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
                final color = isCompleted
                    ? _getStatusColor(status)
                    : AppTheme.textTertiary;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isCurrent ? 40 : 32,
                              height: isCurrent ? 40 : 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? color.withValues(alpha: 0.12)
                                    : AppTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color,
                                  width: isCurrent ? 2.5 : 1.5,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.25),
                                          blurRadius: 8,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                size: isCurrent ? 20 : 16,
                                color: isCompleted
                                    ? color
                                    : AppTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getShortStatusName(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCompleted
                                    ? color
                                    : AppTheme.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: currentStatusIndex > index
                                  ? _getStatusColor(statusOrder[index])
                                  : AppTheme.border,
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
    );
  }

  String _getShortStatusName(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return 'Pendiente';
      case ReportStatus.enProceso:
        return 'En Proceso';
      case ReportStatus.resuelto:
        return 'Resuelto';
      case ReportStatus.rechazado:
        return 'Rechazado';
    }
  }

  Widget _buildStatusChip(ReportStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.infoLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppTheme.info,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.emergencyLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 56, color: AppTheme.emergency),
          ),
          const SizedBox(height: 16),
          Text('Error: $message', style: AppTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _reportBloc.add(GetReportByIdEvent(reportId: widget.reportId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return AppTheme.info;
      case ReportStatus.enProceso:
        return const Color(0xFF8E24AA);
      case ReportStatus.resuelto:
        return AppTheme.success;
      case ReportStatus.rechazado:
        return AppTheme.emergency;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAttachment(MediaAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(attachment.fileName),
        content: attachment.type == MediaType.image
            ? Image.network(attachment.url)
            : Text('Vista previa de video no disponible', style: AppTheme.bodyMedium),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
