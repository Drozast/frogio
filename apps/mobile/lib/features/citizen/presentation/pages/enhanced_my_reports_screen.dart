// lib/features/citizen/presentation/pages/enhanced_my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frogio_mobile/features/citizen/presentation/pages/report_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';
import '../widgets/enhanced_report_list_item.dart';
import 'enhanced_create_report_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final String userId;
  final String? userRole;

  const MyReportsScreen({
    super.key,
    required this.userId,
    this.userRole,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late ReportBloc _reportBloc;
  late TabController _tabController;
  final _searchController = TextEditingController();

  bool _useRealTimeUpdates = true;
  String _currentFilter = 'Todas';
  String _searchQuery = '';

  final List<String> _statusFilters = [
    'Todas',
    'Enviada',
    'En Revisión',
    'En Proceso',
    'Resuelta',
    'Rechazada',
  ];

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadReports() {
    if (_useRealTimeUpdates) {
      _reportBloc.add(StartWatchingUserReportsEvent(userId: widget.userId));
    } else {
      _reportBloc.add(LoadReportsEvent(userId: widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _reportBloc,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Mis Denuncias'),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _showSearchDialog,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: AppTheme.surfaceWhite,
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'realtime',
                        child: Row(
                          children: [
                            Icon(
                              _useRealTimeUpdates
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _useRealTimeUpdates
                                  ? 'Desactivar tiempo real'
                                  : 'Activar tiempo real',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('Actualizar',
                                style:
                                    TextStyle(color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                color: AppTheme.surfaceWhite,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textTertiary,
                  indicatorColor: AppTheme.primary,
                  dividerColor: AppTheme.border,
                  tabs: const [
                    Tab(icon: Icon(Icons.list), text: 'Lista'),
                    Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          onPressed: () => _navigateToCreateReport(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Denuncia',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildReportsListTab(),
            _buildSummaryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsListTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadReports(),
            color: AppTheme.primary,
            backgroundColor: AppTheme.surfaceWhite,
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (context, state) {
                if (state is ReportLoading) {
                  return _buildLoadingList();
                } else if (state is ReportsLoaded) {
                  return _buildReportsList(state.filteredReports);
                } else if (state is ReportsStreaming) {
                  return _buildReportsList(state.reports);
                } else if (state is ReportError) {
                  return _buildErrorState(state.message);
                } else {
                  return _buildLoadingList();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        List<ReportEntity> reports = [];

        if (state is ReportsLoaded) {
          reports = state.reports;
        } else if (state is ReportsStreaming) {
          reports = state.reports;
        }

        return _buildSummaryContent(reports);
      },
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentFilter = filter;
                        });
                        _reportBloc
                            .add(FilterReportsEvent(filter: filter));
                      }
                    },
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primarySurface,
                    checkmarkColor: AppTheme.primary,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.6)
                          : AppTheme.border,
                      width: isSelected ? 1.2 : 1.0,
                    ),
                    shadowColor: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    elevation: isSelected ? 2 : 0,
                  ),
                );
              }).toList(),
            ),
          ),

          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscando: "$_searchQuery"',
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.primary),
                    onPressed: _clearSearch,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsList(List<ReportEntity> reports) {
    if (reports.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: EnhancedReportListItem(
            report: report,
            onTap: () => _navigateToReportDetail(report.id),
            showActions: widget.userRole == 'admin' ||
                widget.userRole == 'inspector',
          ),
        );
      },
    );
  }

  Widget _buildSummaryContent(List<ReportEntity> reports) {
    final stats = _calculateStats(reports);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${reports.length}',
                  Icons.list_alt,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Resueltas',
                  '${stats['resolved'] ?? 0}',
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'En Proceso',
                  '${stats['inProgress'] ?? 0}',
                  Icons.build,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '${stats['pending'] ?? 0}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Estadísticas por Estado',
            style: AppTheme.titleMedium
                .copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildStatusChart(stats),

          const SizedBox(height: 24),

          Text(
            'Actividad Reciente',
            style: AppTheme.titleMedium
                .copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(reports),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
          ...AppTheme.shadowSmall,
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, int> stats) {
    final total = stats.values.fold(0, (sum, value) => sum + value);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text(
            'Sin denuncias para mostrar',
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: stats.entries.map((entry) {
          final percentage = (entry.value / total * 100).round();
          final color = _getStatusColor(entry.key);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getStatusDisplayName(entry.key),
                    style: AppTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${entry.value} ($percentage%)',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(List<ReportEntity> reports) {
    final recentReports = reports
        .where(
            (r) => DateTime.now().difference(r.updatedAt).inDays <= 7)
        .take(3)
        .toList();

    if (recentReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text(
            'Sin actividad reciente',
            style: TextStyle(color: AppTheme.textTertiary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: recentReports.map((report) {
          final statusColor = _getStatusColor(report.status.name);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.12),
              child: Icon(
                _getStatusIcon(report.status),
                color: statusColor,
                size: 20,
              ),
            ),
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.titleSmall,
            ),
            subtitle: Text(
              '${report.status.displayName} • ${_timeAgo(report.updatedAt)}',
              style: AppTheme.bodySmall,
            ),
            onTap: () => _navigateToReportDetail(report.id),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: AppTheme.borderLight,
            highlightColor: AppTheme.primarySurface,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BouncingIcon(
              icon: Icons.report_off,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron denuncias'
                  : _currentFilter == 'Todas'
                      ? 'No tienes denuncias'
                      : 'No tienes denuncias con estado "$_currentFilter"',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateReport,
              icon: const Icon(Icons.add),
              label: const Text('Crear Nueva Denuncia'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppTheme.errorColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReports,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Helper methods

  Map<String, int> _calculateStats(List<ReportEntity> reports) {
    final stats = <String, int>{};

    for (final report in reports) {
      final status = report.status.name;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    final pending =
        (stats['submitted'] ?? 0) + (stats['reviewing'] ?? 0);

    return {
      'pending': pending,
      'inProgress': stats['inProgress'] ?? 0,
      'resolved': stats['resolved'] ?? 0,
      'rejected': stats['rejected'] ?? 0,
    };
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'inProgress':
        return Colors.purple;
      case 'resolved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pendientes';
      case 'inProgress':
        return 'En Proceso';
      case 'resolved':
        return 'Resueltas';
      case 'rejected':
        return 'Rechazadas';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return Icons.send;
      case ReportStatus.enProceso:
        return Icons.build;
      case ReportStatus.resuelto:
        return Icons.check_circle;
      case ReportStatus.rechazado:
        return Icons.cancel;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'hace un momento';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar denuncias'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Título, descripción o categoría...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _performSearch(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _reportBloc.add(SearchReportsEvent(query: query));
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
    });
    _searchController.clear();
    _reportBloc.add(const SearchReportsEvent(query: ''));
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'realtime':
        setState(() {
          _useRealTimeUpdates = !_useRealTimeUpdates;
        });
        _loadReports();
        break;
      case 'refresh':
        _loadReports();
        break;
    }
  }

  void _navigateToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReportScreen(userId: widget.userId),
      ),
    ).then((_) => _loadReports());
  }

  void _navigateToReportDetail(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailScreen(
          reportId: reportId,
          currentUserRole: widget.userRole,
        ),
      ),
    ).then((_) => _loadReports());
  }
}

/// Bouncing icon widget used in the empty state.
class _BouncingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _BouncingIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _bounce = Tween<double>(begin: 0, end: -12)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: 60,
          color: widget.color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
