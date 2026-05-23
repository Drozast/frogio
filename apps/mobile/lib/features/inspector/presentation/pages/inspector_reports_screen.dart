// lib/features/inspector/presentation/pages/inspector_reports_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../citizen/domain/entities/enhanced_report_entity.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_bloc.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_event.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_state.dart';
import 'create_inspector_report_screen.dart';
import '../../../citizen/presentation/pages/enhanced_report_detail_screen.dart';

class InspectorReportsScreen extends StatefulWidget {
  const InspectorReportsScreen({super.key});

  @override
  State<InspectorReportsScreen> createState() => _InspectorReportsScreenState();
}

// Sub-tab statuses matching backend 4-state enum
const List<String> _subTabStatuses = ['pendiente', 'en_proceso', 'resuelto'];

class _InspectorReportsScreenState extends State<InspectorReportsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  late TabController _tabController;
  Timer? _autoRefreshTimer;
  ReportBloc? _reportBloc;
  String? _inspectorId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadCurrentTab();
    }
  }

  void _loadCurrentTab() {
    if (_reportBloc == null) return;
    final status = _subTabStatuses[_tabController.index];
    _reportBloc!.add(GetReportsByStatusEvent(status: status));
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadCurrentTab();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _reportBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _inspectorId = authState.user.id;
    }

    if (_reportBloc == null) {
      _reportBloc = di.sl<ReportBloc>()
        ..add(const GetReportsByStatusEvent(status: 'pendiente'));
      _startAutoRefresh();
    }

    return BlocProvider.value(
      value: _reportBloc!,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSubTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _subTabStatuses
                    .map((status) => _ReportsTabView(
                          status: status,
                          inspectorId: _inspectorId,
                          onRefresh: _loadCurrentTab,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreateReport,
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Denuncia'),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Denuncias', style: TextStyle(color: Colors.white)),
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      color: _primaryGreen.withValues(alpha: 0.9),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Pendientes'),
          Tab(text: 'En Proceso'),
          Tab(text: 'Resueltas'),
        ],
      ),
    );
  }

  void _navigateToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInspectorReportScreen(inspectorId: _inspectorId ?? ''),
      ),
    ).then((_) => _loadCurrentTab());
  }
}

// ---------------------------------------------------------------------------
// Per-tab view — stateless, receives its status + segment
// ---------------------------------------------------------------------------

class _ReportsTabView extends StatelessWidget {
  final String status;
  final String? inspectorId;
  final VoidCallback onRefresh;

  const _ReportsTabView({
    required this.status,
    required this.inspectorId,
    required this.onRefresh,
  });

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        if (state is ReportLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportError) {
          return _buildError(context, state.message);
        }

        if (state is ReportsLoaded) {
          final reports = state.reports;
          if (reports.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReportBloc>().add(GetReportsByStatusEvent(status: status));
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: reports.length,
              itemBuilder: (context, index) =>
                  _ReportCard(report: reports[index]),
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmpty() {
    final (IconData icon, String msg) = switch (status) {
      'pendiente' => (Icons.check_circle_outline, 'No hay denuncias pendientes'),
      'en_proceso' => (Icons.hourglass_empty, 'No hay denuncias en proceso'),
      'resuelto' => (Icons.assignment_turned_in_outlined, 'No hay denuncias resueltas'),
      _ => (Icons.inbox_outlined, 'No hay denuncias'),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: AppTheme.textTertiary),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text(
            'Usa el botón + para crear una nueva',
            style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.emergency),
            const SizedBox(height: 12),
            const Text('Error al cargar denuncias',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
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
}

// ---------------------------------------------------------------------------
// Report card
// ---------------------------------------------------------------------------

class _ReportCard extends StatelessWidget {
  final ReportEntity report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final imageUrls = report.attachments
        .where((a) => a.type == MediaType.image)
        .map((a) => a.url)
        .toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_categoryIcon, color: _categoryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.category,
                            style: TextStyle(
                                color: _categoryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: report.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                // Footer row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.location.address ?? 'Sin dirección',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textTertiary, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.calendar_today,
                        size: 13, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(report.createdAt),
                      style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
                // Thumbnail strip
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ThumbnailStrip(imageUrls: imageUrls),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedReportDetailScreen(
          reportId: report.id,
          currentUserRole: 'inspector',
        ),
      ),
    );
  }

  Color get _categoryColor {
    switch (report.category.toLowerCase()) {
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

  IconData get _categoryIcon {
    switch (report.category.toLowerCase()) {
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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

// ---------------------------------------------------------------------------
// Status badge using new 4-state enum
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      ReportStatus.pendiente => (Colors.orange, 'Pendiente'),
      ReportStatus.enProceso => (Colors.blue, 'En Proceso'),
      ReportStatus.resuelto => (Colors.green, 'Resuelta'),
      ReportStatus.rechazado => (Colors.red, 'Rechazada'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thumbnail strip
// ---------------------------------------------------------------------------

class _ThumbnailStrip extends StatelessWidget {
  final List<String> imageUrls;

  const _ThumbnailStrip({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length > 3 ? 3 : imageUrls.length;

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        itemBuilder: (context, i) {
          final isOverflow = i == 2 && imageUrls.length > 3;

          if (isOverflow) {
            return Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+${imageUrls.length - 2}',
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrls[i]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
