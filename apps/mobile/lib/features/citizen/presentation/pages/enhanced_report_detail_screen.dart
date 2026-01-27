// lib/features/citizen/presentation/pages/enhanced_report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Detalle de Denuncia'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadReportDetails,
        ),
        BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoaded) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, state.report),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Compartir'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'directions',
                    child: Row(
                      children: [
                        Icon(Icons.directions),
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
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Detalles'),
            Tab(icon: Icon(Icons.forum), text: 'Respuestas'),
            Tab(icon: Icon(Icons.track_changes), text: 'Seguimiento'),
          ],
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
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.location.address!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${report.id.length > 8 ? report.id.substring(0, 8) : report.id}',
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

  Widget _buildHistoryTab(ReportEntity report) {
    // Estados en orden de progreso
    final statusOrder = [
      ReportStatus.submitted,
      ReportStatus.reviewing,
      ReportStatus.inProgress,
      ReportStatus.resolved,
    ];

    final currentStatusIndex = statusOrder.indexOf(report.status);
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
          Card(
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
                        'Estado Actual',
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
          ),

          const SizedBox(height: 16),

          // Timeline de historial
          Card(
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
                        'Historial de Cambios',
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
                      final isLastItem = index == historyItems.length - 1;
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
                                    color: isLastItem ? color : color.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color,
                                      width: 2,
                                    ),
                                  ),
                                  child: isLastItem
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                                if (!isLastItem)
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
                                  color: isLastItem ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isLastItem ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
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
                                              color: isLastItem ? color : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isLastItem)
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
                                      DateFormat('dd/MM/yyyy HH:mm').format(historyItem.timestamp),
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
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  images[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
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
              color: Colors.grey,
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
                border: Border.all(color: Colors.grey.shade300),
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
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildResponseCard(ReportResponse response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    response.responderName.isNotEmpty
                        ? response.responderName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(response.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
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
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
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
            Text(response.message),
          ],
        ),
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
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin respuestas aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las respuestas del municipio aparecerán aquí',
            style: TextStyle(color: Colors.grey),
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
            onPressed: _loadReportDetails,
            child: const Text('Reintentar'),
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
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
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: AppTheme.primaryColor,
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
        return Colors.grey.shade600;
      case ReportStatus.duplicate:
        return Colors.amber;
      case ReportStatus.cancelled:
        return Colors.grey.shade500;
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
              color: Colors.white,
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
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    color: AppTheme.primaryColor,
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
                child: const Icon(Icons.add, color: AppTheme.primaryColor),
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
                child: const Icon(Icons.remove, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
