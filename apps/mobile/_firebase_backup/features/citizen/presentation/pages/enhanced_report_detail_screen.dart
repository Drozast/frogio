// lib/features/citizen/presentation/pages/enhanced_report_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/report_entity.dart';
import '../bloc/report/report_bloc.dart';
import '../bloc/report/report_event.dart';
import '../bloc/report/report_state.dart';
import '../widgets/response_input_widget.dart';
import '../widgets/status_update_widget.dart';

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
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

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
    _mapController?.dispose();
    super.dispose();
  }

  void _loadReportDetails() {
    _reportBloc.add(LoadReportDetailsEvent(reportId: widget.reportId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _reportBloc,
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
              } else if (state is ReportDetailLoaded) {
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
        BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportDetailLoaded) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, state.report),
                itemBuilder: (context) => [
                  if (_canUpdateStatus())
                    const PopupMenuItem(
                      value: 'update_status',
                      child: Row(
                        children: [
                          Icon(Icons.update),
                          SizedBox(width: 8),
                          Text('Actualizar Estado'),
                        ],
                      ),
                    ),
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
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Actualizar'),
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
    _setupMapMarker(report);
    
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
            Tab(icon: Icon(Icons.history), text: 'Historial'),
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
                  report.title,
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
              _buildCategoryChip(report.category),
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
                'ID: ${report.id.substring(0, 8)}',
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
          if (report.imageUrls.isNotEmpty)
            _buildSection(
              'Evidencia Fotográfica',
              Icons.photo_library,
              _buildPhotoGallery(report.imageUrls),
            ),
          
          // Ubicación
          _buildSection(
            'Ubicación',
            Icons.location_on,
            _buildLocationSection(report),
          ),
          
          // Información adicional
          _buildSection(
            'Información Adicional',
            Icons.info,
            Column(
              children: [
                _buildInfoRow('Categoría', report.category),
                _buildInfoRow('Estado', report.status),
                _buildInfoRow(
                  'Última actualización',
                  DateFormat('dd/MM/yyyy HH:mm').format(report.updatedAt),
                ),
                _buildInfoRow(
                  'Historial de cambios',
                  '${report.historyLog.length} evento(s)',
                ),
              ],
            ),
          ),
          
          // Acciones rápidas
          if (_canUpdateStatus())
            _buildSection(
              'Acciones',
              Icons.settings,
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(report),
                      icon: const Icon(Icons.update),
                      label: const Text('Actualizar Estado'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openInMaps(report),
                      icon: const Icon(Icons.directions),
                      label: const Text('Cómo llegar'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesTab(ReportEntity report) {
    // Simular respuestas (en implementación real vendrían del reporte)
    final responses = <Map<String, dynamic>>[];
    
    return Column(
      children: [
        // Lista de respuestas
        Expanded(
          child: responses.isEmpty
              ? _buildEmptyResponses()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: responses.length,
                  itemBuilder: (context, index) {
                    return _buildResponseCard(responses[index]);
                  },
                ),
        ),
        
        // Widget para agregar respuesta (solo para inspectores/admin)
        if (_canRespond())
          ResponseInputWidget(
            reportId: report.id,
            onResponseAdded: () => _loadReportDetails(),
          ),
      ],
    );
  }

  Widget _buildHistoryTab(ReportEntity report) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: report.historyLog.length,
      itemBuilder: (context, index) {
        final historyItem = report.historyLog[index];
        final isFirst = index == 0;
        final isLast = index == report.historyLog.length - 1;
        
        return TimelineTile(
          alignment: TimelineAlign.start,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 24,
            height: 24,
            indicator: Container(
              decoration: BoxDecoration(
                color: _getStatusColor(historyItem.status),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(historyItem.status),
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          endChild: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      historyItem.status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(historyItem.status),
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM HH:mm').format(historyItem.timestamp),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (historyItem.userId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Por: ${historyItem.userId}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (historyItem.comment != null) ...[
                  const SizedBox(height: 8),
                  Text(historyItem.comment!),
                ],
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildPhotoGallery(List<String> imageUrls) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(imageUrls, index),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.error),
                  ),
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
          
          // Mapa
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 15,
              ),
              markers: _markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
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

  Widget _buildResponseCard(Map<String, dynamic> response) {
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
                    (response['responderName'] as String).substring(0, 1).toUpperCase(),
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
                        response['responderName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(response['createdAt']),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!(response['isPublic'] as bool))
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
            Text(response['message']),
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

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods

  void _setupMapMarker(ReportEntity report) {
    if (report.location.latitude != 0 && report.location.longitude != 0) {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId(report.id),
          position: LatLng(
            report.location.latitude,
            report.location.longitude,
          ),
          infoWindow: InfoWindow(
            title: report.title,
            snippet: report.location.address,
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Proceso':
        return Colors.blue;
      case 'Completada':
        return AppTheme.successColor;
      case 'Rechazada':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Enviada':
        return Icons.send;
      case 'Revisada':
        return Icons.visibility;
      case 'En Proceso':
        return Icons.build;
      case 'Completada':
        return Icons.check_circle;
      case 'Rechazada':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Alumbrado Público':
        return Colors.amber;
      case 'Basura':
        return Colors.brown;
      case 'Calles y Veredas':
        return Colors.grey;
      case 'Seguridad':
        return Colors.red;
      case 'Áreas Verdes':
        return AppTheme.primaryColor;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alumbrado Público':
        return Icons.lightbulb;
      case 'Basura':
        return Icons.delete;
      case 'Calles y Veredas':
        return Icons.directions_walk;
      case 'Seguridad':
        return Icons.security;
      case 'Áreas Verdes':
        return Icons.park;
      default:
        return Icons.help;
    }
  }

  bool _canUpdateStatus() {
    return widget.currentUserRole == 'inspector' || 
           widget.currentUserRole == 'admin';
  }

  bool _canRespond() {
    return widget.currentUserRole == 'inspector' || 
           widget.currentUserRole == 'admin';
  }

  void _handleMenuAction(String action, ReportEntity report) {
    switch (action) {
      case 'update_status':
        _showStatusUpdateDialog(report);
        break;
      case 'share':
        _shareReport(report);
        break;
      case 'directions':
        _openInMaps(report);
        break;
      case 'refresh':
        _loadReportDetails();
        break;
    }
  }

  void _showStatusUpdateDialog(ReportEntity report) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _reportBloc,
        child: StatusUpdateWidget(
          report: report,
          onStatusUpdated: () => _loadReportDetails(),
        ),
      ),
    );
  }

  void _shareReport(ReportEntity report) {
    // Implementar sharing usando el portapapeles
    final shareText = 'Denuncia FROGIO: ${report.title}\nID: ${report.id}\nEstado: ${report.status}';
    
    // Copiar al portapapeles
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

  void _openPhotoViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
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
}

// Screen para visualizar fotos en pantalla completa
class PhotoViewerScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${initialIndex + 1} de ${imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}