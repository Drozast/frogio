// lib/features/citizen/presentation/pages/enhanced_report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frogio_santa_juana/core/services/maps_service.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';

class EnhancedReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String? currentUserRole;
  final String? currentUserId;

  const EnhancedReportDetailScreen({
    super.key,
    required this.reportId,
    this.currentUserRole,
    this.currentUserId,
  });

  @override
  State<EnhancedReportDetailScreen> createState() => _EnhancedReportDetailScreenState();
}

class _EnhancedReportDetailScreenState extends State<EnhancedReportDetailScreen>
    with SingleTickerProviderStateMixin {
  late ReportBloc _reportBloc;
  late TabController _tabController;
  final MapController _mapController = MapController();

  /// Capitaliza la primera letra de cada palabra
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReportDetails() {
    _reportBloc.add(GetReportByIdEvent(reportId: widget.reportId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportBloc,
      child: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportError) {
            _showErrorSnackBar(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAF8),
          appBar: _buildAppBar(),
          body: BlocBuilder<ReportBloc, ReportState>(
            builder: (context, state) {
              if (state is ReportLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ReportLoaded) {
                return _buildReportDetail(state.report);
              } else if (state is ReportError) {
                return _buildErrorState(state.message);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceWhite,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      title: const Text('Detalle de Denuncia'),

      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.primary),
          onPressed: _loadReportDetails,
        ),
        BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoaded) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, state.report),
                color: AppTheme.surfaceWhite,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Compartir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'directions',
                    child: Row(
                      children: [
                        Icon(Icons.directions, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Cómo llegar'),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildReportDetail(ReportEntity report) {
    return Column(
      children: [
        // Header con información básica
        _buildReportHeader(report),

        // Tabs
        Container(
          color: AppTheme.surfaceWhite,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 2,
            tabs: const [
              Tab(icon: Icon(Icons.info), text: 'Detalles'),
              Tab(icon: Icon(Icons.forum), text: 'Respuestas'),
              Tab(icon: Icon(Icons.track_changes), text: 'Seguimiento'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(report),
              _buildResponsesTab(report),
              _buildHistoryTab(report),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportHeader(ReportEntity report) {
    final statusColor = _getStatusColor(report.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 8)],
        border: Border(
          bottom: BorderSide(color: statusColor.withValues(alpha: 0.35), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(report.title),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusBadge(report.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCategoryChip(_capitalize(report.category)),
              const SizedBox(width: 8),
              if (report.location.address != null)
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.location.address!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${report.id.length > 8 ? report.id.substring(0, 8) : report.id}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ReportEntity report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          _buildSection(
            'Descripción',
            Icons.description,
            Text(
              report.description,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Multimedia
          if (report.attachments.isNotEmpty)
            _buildSection(
              'Evidencia Fotográfica',
              Icons.photo_library,
              _buildPhotoGallery(report.attachments),
            ),

          // Ubicación
          _buildSection(
            'Ubicación',
            Icons.location_on,
            _buildLocationSection(report),
          ),

          // Información adicional (sin prioridad)
          _buildSection(
            'Información Adicional',
            Icons.info,
            Column(
              children: [
                _buildInfoRow('Categoría', _capitalize(report.category)),
                _buildInfoRow('Estado', report.status.displayName),
                _buildInfoRow(
                  'Última actualización',
                  DateFormat('dd/MM/yyyy HH:mm').format(report.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesTab(ReportEntity report) {
    if (report.responses.isEmpty) {
      return _buildEmptyResponses();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: report.responses.length,
      itemBuilder: (context, index) {
        final response = report.responses[index];
        return _buildResponseCard(response);
      },
    );
  }

  /// Verifica si el reporte es una emergencia SOS
  bool _isEmergencyReport(ReportEntity report) {
    return report.category.toLowerCase() == 'emergencia';
  }

  Widget _buildHistoryTab(ReportEntity report) {
    final isEmergency = _isEmergencyReport(report);
    final isRejected = report.status == ReportStatus.rejected;

    // Ordenar historial por fecha
    final historyItems = report.statusHistory.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracker visual de progreso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isEmergency ? AppTheme.emergency : AppTheme.primary).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEmergency ? Icons.sos_rounded : Icons.track_changes,
                      color: isEmergency ? AppTheme.emergency : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEmergency ? 'Seguimiento de Emergencia' : 'Estado Actual',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isRejected)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.emergency.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cancel, color: AppTheme.emergency),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este reporte ha sido rechazado',
                            style: TextStyle(color: AppTheme.emergency, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isEmergency)
                  _buildEmergencyProgressTracker(report)
                else
                  _buildNormalProgressTracker(report),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timeline de historial
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Historial de Cambios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (historyItems.isEmpty)
                  const Text(
                    'Sin historial de cambios',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  ...historyItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final historyItem = entry.value;
                    final isLastItem = index == historyItems.length - 1;
                    final color = _getStatusColor(historyItem.status);

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline visual — colored left border indicator
                          Column(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isLastItem
                                      ? color.withValues(alpha: 0.2)
                                      : const Color(0xFFF0F7F0),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 2),
                                  boxShadow: isLastItem
                                      ? [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 14, spreadRadius: 3)]
                                      : null,
                                ),
                                child: isLastItem
                                    ? Icon(Icons.check, size: 14, color: color)
                                    : null,
                              ),
                              if (!isLastItem)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    color: color.withValues(alpha: 0.25),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Contenido — dark card with colored left border
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(color: color, width: 3),
                                  top: BorderSide(color: color.withValues(alpha: 0.15)),
                                  right: BorderSide(color: color.withValues(alpha: 0.15)),
                                  bottom: BorderSide(color: color.withValues(alpha: 0.15)),
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
                                            color: isLastItem ? color : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isLastItem)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: color.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            'Actual',
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(historyItem.timestamp),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  if (historyItem.comment != null && historyItem.comment!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: color.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.comment, size: 14, color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              historyItem.comment!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: AppTheme.textPrimary,
                                              ),
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
                                        const Icon(Icons.person, size: 12, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          historyItem.userName!,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
        ],
      ),
    );
  }

  /// Tracker de progreso para emergencias SOS: Enviado → En camino → Finalizado
  Widget _buildEmergencyProgressTracker(ReportEntity report) {
    // Pasos de emergencia SOS
    final sosSteps = [
      {'label': 'Enviado', 'icon': Icons.send_rounded, 'status': ReportStatus.submitted},
      {'label': 'En camino', 'icon': Icons.directions_run_rounded, 'status': ReportStatus.inProgress},
      {'label': 'Finalizado', 'icon': Icons.check_circle_rounded, 'status': ReportStatus.resolved},
    ];

    // Determinar el paso actual basado en el estado del reporte
    int currentStep;
    switch (report.status) {
      case ReportStatus.submitted:
      case ReportStatus.reviewing:
        currentStep = 0;
        break;
      case ReportStatus.inProgress:
        currentStep = 1;
        break;
      case ReportStatus.resolved:
      case ReportStatus.archived:
        currentStep = 2;
        break;
      default:
        currentStep = 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(sosSteps.length, (index) {
          final step = sosSteps[index];
          final isCompleted = index <= currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == sosSteps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isCurrent ? 44 : 36,
                        height: isCurrent ? 44 : 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.emergency.withValues(alpha: 0.18)
                              : Colors.white,
                          border: Border.all(
                            color: isCompleted ? AppTheme.emergency : AppTheme.border,
                            width: isCurrent ? 2.5 : 1.5,
                          ),
                          boxShadow: isCurrent ? [BoxShadow(color: AppTheme.emergency.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 2)] : null,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: isCurrent ? 22 : 18,
                          color: isCompleted ? AppTheme.emergency : AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? AppTheme.emergency : AppTheme.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 24,
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: index < currentStep
                          ? AppTheme.emergency.withValues(alpha: 0.6)
                          : AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Tracker de progreso para reportes normales: Enviado → Revisión → En Proceso → Resuelto
  Widget _buildNormalProgressTracker(ReportEntity report) {
    final statusOrder = [
      ReportStatus.submitted,
      ReportStatus.reviewing,
      ReportStatus.inProgress,
      ReportStatus.resolved,
    ];

    final currentStatusIndex = statusOrder.indexOf(report.status);

    return Row(
      children: statusOrder.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = currentStatusIndex >= index;
        final isCurrent = currentStatusIndex == index;
        final isLast = index == statusOrder.length - 1;
        final color = isCompleted ? _getStatusColor(status) : AppTheme.textTertiary;

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
                        color: isCompleted
                            ? color.withValues(alpha: 0.18)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted ? color : AppTheme.border,
                          width: isCurrent ? 2.5 : 1.5,
                        ),
                        boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 10, spreadRadius: 2)] : null,
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        size: isCurrent ? 20 : 16,
                        color: isCompleted ? color : AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Etiqueta
                    Text(
                      _getShortStatusName(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? color : AppTheme.textTertiary,
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
                          ? _getStatusColor(statusOrder[index + 1]).withValues(alpha: 0.6)
                          : AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
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
      case ReportStatus.duplicate:
        return Icons.content_copy;
      case ReportStatus.cancelled:
        return Icons.block;
    }
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
      case ReportStatus.duplicate:
        return 'Duplicada';
      case ReportStatus.cancelled:
        return 'Cancelada';
    }
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<MediaAttachment> attachments) {
    final images = attachments.where((a) => a.type == MediaType.image).toList();

    if (images.isEmpty) {
      return const Text('Sin imágenes');
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(images[index].url),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF0F7F0),
                    child: const Icon(Icons.error, color: AppTheme.emergency),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFFF0F7F0),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection(ReportEntity report) {
    final location = report.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dirección
        if (location.address != null)
          Text(location.address!)
        else
          const Text('Dirección no disponible'),

        const SizedBox(height: 8),

        // Coordenadas
        if (location.latitude != 0 && location.longitude != 0) ...[
          Text(
            'Coordenadas: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Mapa interactivo (click para expandir)
          GestureDetector(
            onTap: () => _showFullscreenMap(LatLng(location.latitude, location.longitude), location.address),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(location.latitude, location.longitude),
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
                            point: LatLng(location.latitude, location.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
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
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 16, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Ampliar',
                            style: TextStyle(fontSize: 12, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(ReportResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Text(
                  response.responderName.isNotEmpty
                      ? response.responderName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.responderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(response.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!response.isPublic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Privado',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            response.message,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResponses() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            'Sin respuestas aún',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las respuestas del municipio aparecerán aquí',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
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
            size: 64,
            color: AppTheme.emergency,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.20), blurRadius: 12, spreadRadius: 2)],
            ),
            child: ElevatedButton(
              onPressed: _loadReportDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8)],
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
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
        return const Color(0xFF556677);
      case ReportStatus.duplicate:
        return Colors.amber;
      case ReportStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  void _handleMenuAction(String action, ReportEntity report) {
    switch (action) {
      case 'share':
        _shareReport(report);
        break;
      case 'directions':
        _openInMaps(report);
        break;
    }
  }

  void _shareReport(ReportEntity report) {
    final shareText = 'Denuncia FROGIO: ${report.title}\nID: ${report.id}\nEstado: ${report.status.displayName}';

    Clipboard.setData(ClipboardData(text: shareText)).then((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información copiada al portapapeles'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  void _openInMaps(ReportEntity report) {
    final url = 'https://www.google.com/maps/search/?api=1&query=${report.location.latitude},${report.location.longitude}';
    launchUrl(Uri.parse(url));
  }

  void _openPhotoViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(imageUrl: imageUrl),
        fullscreenDialog: true,
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

  void _showFullscreenMap(LatLng location, String? address) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ubicación del Reporte',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ),
            SizedBox(
              height: 400,
              child: _FullscreenMapWidget(
                location: location,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _PhotoViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.error,
              color: AppTheme.emergency,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenMapWidget extends StatefulWidget {
  final LatLng location;

  const _FullscreenMapWidget({required this.location});

  @override
  State<_FullscreenMapWidget> createState() => _FullscreenMapWidgetState();
}

class _FullscreenMapWidgetState extends State<_FullscreenMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.location,
            initialZoom: 16,
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
                  point: widget.location,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primary,
                    size: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Botones de zoom
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: 'fullscreen_zoom_in',
                backgroundColor: Colors.white,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom + 1);
                },
                child: const Icon(Icons.add, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                mini: true,
                heroTag: 'fullscreen_zoom_out',
                backgroundColor: Colors.white,
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currentZoom - 1);
                },
                child: const Icon(Icons.remove, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
