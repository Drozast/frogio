// lib/features/citizen/presentation/pages/enhanced_my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frogio_santa_juana/features/citizen/presentation/pages/report_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container.dart' as di;
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
        appBar: AppBar(
          title: const Text('Mis Denuncias'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            PopupMenuButton<String>(
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
                      ),
                      const SizedBox(width: 8),
                      Text(_useRealTimeUpdates 
                          ? 'Desactivar tiempo real' 
                          : 'Activar tiempo real'),
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
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Lista'),
              Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () => _navigateToCreateReport(),
          icon: const Icon(Icons.add),
          label: const Text('Nueva Denuncia'),
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
            color: AppTheme.primaryColor,
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
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentFilter = filter;
                        });
                        _reportBloc.add(FilterReportsEvent(filter: filter));
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buscando: "$_searchQuery"',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.blue),
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
            showActions: widget.userRole == 'admin' || widget.userRole == 'inspector',
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
          
          const Text(
            'Estadísticas por Estado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusChart(stats),
          
          const SizedBox(height: 24),
          
          const Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(reports),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(Map<String, int> stats) {
    final total = stats.values.fold(0, (sum, value) => sum + value);
    
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Sin denuncias para mostrar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: stats.entries.map((entry) {
            final percentage = (entry.value / total * 100).round();
            final color = _getStatusColor(entry.key);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_getStatusDisplayName(entry.key)),
                  ),
                  Text(
                    '${entry.value} ($percentage%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<ReportEntity> reports) {
    final recentReports = reports
        .where((r) => DateTime.now().difference(r.updatedAt).inDays <= 7)
        .take(3)
        .toList();
    
    if (recentReports.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Sin actividad reciente',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: recentReports.map((report) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
               backgroundColor: _getStatusColor(report.status.name).withValues(alpha: 0.2),
                child: Icon(
                  _getStatusIcon(report.status),
                  color: _getStatusColor(report.status.name),
                  size: 20,
                ),
              ),
              title: Text(
                report.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${report.status.displayName} • ${_timeAgo(report.updatedAt)}',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => _navigateToReportDetail(report.id),
            );
          }).toList(),
        ),
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
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.report_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No se encontraron denuncias'
                : _currentFilter == 'Todas'
                    ? 'No tienes denuncias'
                    : 'No tienes denuncias con estado "$_currentFilter"',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Crear Nueva Denuncia'),
            onPressed: _navigateToCreateReport,
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
    
    final pending = (stats['submitted'] ?? 0) + (stats['reviewing'] ?? 0);
    
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
      case ReportStatus.submitted:
        return Icons.send;
      case ReportStatus.reviewing:
        return Icons.visibility;
      case ReportStatus.inProgress:
        return Icons.build;
      case ReportStatus.resolved:
        return Icons.check_circle;
      case ReportStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.info;
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