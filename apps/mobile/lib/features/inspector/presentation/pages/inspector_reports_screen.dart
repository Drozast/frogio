// lib/features/inspector/presentation/pages/inspector_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../citizen/domain/entities/enhanced_report_entity.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_bloc.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_event.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_state.dart';
import 'create_citation_screen.dart';
import 'inspector_map_screen.dart';

class InspectorReportsScreen extends StatefulWidget {
  const InspectorReportsScreen({super.key});

  @override
  State<InspectorReportsScreen> createState() => _InspectorReportsScreenState();
}

class _InspectorReportsScreenState extends State<InspectorReportsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  late TabController _tabController;
  String? _selectedCategory;

  final List<String> _categories = [
    'Todas',
    'Infraestructura',
    'Aseo',
    'Seguridad',
    'Medio Ambiente',
    'Otros',
  ];

  // Mapeo de tabs a status del backend
  static const List<String> _tabStatuses = ['submitted', 'inProgress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ReportBloc>()..add(const GetReportsByStatusEvent(status: 'submitted')),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Denuncias'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Pendientes'),
              Tab(text: 'En Proceso'),
              Tab(text: 'Resueltas'),
            ],
            onTap: (index) {
              context.read<ReportBloc>().add(
                    GetReportsByStatusEvent(status: _tabStatuses[index]),
                  );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InspectorMapScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReportsList(context, 'submitted'),
            _buildReportsList(context, 'inProgress'),
            _buildReportsList(context, 'resolved'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(BuildContext context, String status) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportError) {
          return _buildErrorWidget(context, state.message, status);
        }

        if (state is ReportsLoaded) {
          final reports = state.reports;

          if (reports.isEmpty) {
            return _buildEmptyState(status);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReportBloc>().add(
                    GetReportsByStatusEvent(status: status),
                  );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportCard(context, report);
              },
            ),
          );
        }

        return const Center(child: Text('Cargando denuncias...'));
      },
    );
  }

  Widget _buildReportCard(BuildContext context, ReportEntity report) {
    final imageUrls = report.attachments
        .where((a) => a.type == MediaType.image)
        .map((a) => a.url)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetail(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(report.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(report.category),
                      color: _getCategoryColor(report.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.category,
                          style: TextStyle(
                            color: _getCategoryColor(report.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(report.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location.address ?? 'Sin dirección',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length > 3 ? 3 : imageUrls.length,
                    itemBuilder: (context, index) {
                      if (index == 2 && imageUrls.length > 3) {
                        return Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${imageUrls.length - 2}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    String text;

    switch (status) {
      case ReportStatus.draft:
        color = Colors.grey;
        text = 'Borrador';
      case ReportStatus.submitted:
        color = Colors.orange;
        text = 'Pendiente';
      case ReportStatus.reviewing:
        color = Colors.purple;
        text = 'En Revisión';
      case ReportStatus.inProgress:
        color = Colors.blue;
        text = 'En Proceso';
      case ReportStatus.resolved:
        color = Colors.green;
        text = 'Resuelta';
      case ReportStatus.rejected:
        color = Colors.red;
        text = 'Rechazada';
      case ReportStatus.archived:
        color = Colors.grey;
        text = 'Archivada';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'submitted':
        message = 'No hay denuncias pendientes';
        icon = Icons.check_circle_outline;
      case 'inProgress':
        message = 'No hay denuncias en proceso';
        icon = Icons.hourglass_empty;
      case 'resolved':
        message = 'No hay denuncias resueltas';
        icon = Icons.assignment_turned_in_outlined;
      default:
        message = 'No hay denuncias';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message, String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar denuncias',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ReportBloc>().add(
                      GetReportsByStatusEvent(status: status),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetail(BuildContext context, ReportEntity report) {
    final imageUrls = report.attachments
        .where((a) => a.type == MediaType.image)
        .map((a) => a.url)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(report.category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(report.category),
                      color: _getCategoryColor(report.category),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(report.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Descripción
              _buildDetailSection('Descripción', report.description),

              // Categoría
              _buildDetailSection('Categoría', report.category),

              // Ubicación
              _buildDetailSection(
                'Ubicación',
                report.location.address ?? 'Sin dirección',
              ),

              // Coordenadas
              _buildDetailSection(
                'Coordenadas',
                '${report.location.latitude.toStringAsFixed(6)}, ${report.location.longitude.toStringAsFixed(6)}',
              ),

              // Fecha
              _buildDetailSection('Fecha de reporte', _formatDateTime(report.createdAt)),

              // Imágenes
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Evidencia fotográfica',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullImage(context, imageUrls[index]),
                        child: Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(imageUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final authState = context.read<AuthBloc>().state;
                        final inspectorId = authState is Authenticated ? authState.user.id : '';

                        if (inspectorId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error: No se pudo obtener el inspector')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateCitationScreen(inspectorId: inspectorId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_add),
                      label: const Text('Crear Citación'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectorMapScreen(
                              initialLocation: LatLng(
                                report.location.latitude,
                                report.location.longitude,
                              ),
                              highlightReportId: report.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Ver en Mapa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por Categoría',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category ||
                    (_selectedCategory == null && category == 'Todas');
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: _primaryGreen.withValues(alpha: 0.2),
                  checkmarkColor: _primaryGreen,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category == 'Todas' ? null : category;
                    });
                    Navigator.pop(context);
                    // Recargar reportes (el filtro se aplica localmente en el build)
                    context.read<ReportBloc>().add(
                      GetReportsByStatusEvent(status: _getStatusFromTab(_tabController.index)),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'infraestructura':
        return Colors.orange;
      case 'aseo':
        return Colors.green;
      case 'seguridad':
        return Colors.red;
      case 'medio ambiente':
        return Colors.teal;
      case 'iluminación':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'infraestructura':
        return Icons.construction;
      case 'aseo':
        return Icons.cleaning_services;
      case 'seguridad':
        return Icons.security;
      case 'medio ambiente':
        return Icons.eco;
      case 'iluminación':
        return Icons.lightbulb_outline;
      default:
        return Icons.report_problem_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusFromTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'submitted';
      case 1:
        return 'inProgress';
      case 2:
        return 'resolved';
      default:
        return 'submitted';
    }
  }
}
