// lib/features/inspector/presentation/pages/search_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../citizen/domain/entities/enhanced_report_entity.dart';
import '../../../citizen/domain/repositories/enhanced_report_repository.dart' as report_repo;
import '../../data/models/citation_model.dart';
import '../../domain/entities/citation_entity.dart';
import '../../domain/repositories/citation_repository.dart';
import '../utils/citation_ui_extensions.dart';
import 'citation_detail_screen.dart';
import '../../../citizen/presentation/pages/enhanced_report_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;

  // Results
  List<CitationEntity> _citations = [];
  List<ReportEntity> _reports = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  CitationStatus? _citationStatusFilter;
  CitationType? _citationTypeFilter;
  ReportStatus? _reportStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar todo al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _fromDate != null ||
      _toDate != null ||
      _citationStatusFilter != null ||
      _citationTypeFilter != null ||
      _reportStatusFilter != null;

  int get _activeFilterCount {
    int count = 0;
    if (_fromDate != null || _toDate != null) count++;
    if (_citationStatusFilter != null) count++;
    if (_citationTypeFilter != null) count++;
    if (_reportStatusFilter != null) count++;
    return count;
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2 && !_hasActiveFilters) {
      setState(() {
        _citations = [];
        _reports = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.length >= 2 || _hasActiveFilters) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    final citationRepo = di.sl<CitationRepository>();
    final reportRepo = di.sl<report_repo.ReportRepository>();

    // Citaciones: API soporta search + filtros directamente
    final citationFuture = citationRepo.getCitations(
      filters: CitationFilters(
        search: query.isNotEmpty ? query : null,
        status: _citationStatusFilter,
        citationType: _citationTypeFilter,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );

    // Denuncias: traer todas si no hay filtro de status, o filtradas por status
    final reportFuture = _reportStatusFilter != null
        ? reportRepo.getReportsByStatus(_reportStatusFilter!)
        : reportRepo.getReportsByUser('');

    final results = await Future.wait([citationFuture, reportFuture]);

    if (!mounted) return;

    List<CitationEntity> citations = [];
    List<ReportEntity> reports = [];

    results[0].fold((failure) {
      debugPrint('SEARCH: Citation error: ${failure.message}');
    }, (data) {
      citations = (data as List<CitationEntity>);
      debugPrint('SEARCH: Found ${citations.length} citations');
    });

    results[1].fold((failure) {
      debugPrint('SEARCH: Report error: ${failure.message}');
    }, (data) {
      var allReports = data as List<ReportEntity>;

      // Text filter (client-side for reports since API doesn't support search param)
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        allReports = allReports.where((r) {
          return r.title.toLowerCase().contains(lowerQuery) ||
              r.description.toLowerCase().contains(lowerQuery) ||
              r.category.toLowerCase().contains(lowerQuery) ||
              (r.citizenName?.toLowerCase().contains(lowerQuery) ?? false) ||
              (r.location.address?.toLowerCase().contains(lowerQuery) ?? false) ||
              (r.location.manualAddress?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      // Date filter (client-side)
      if (_fromDate != null) {
        allReports = allReports.where((r) =>
            r.createdAt.isAfter(_fromDate!) ||
            r.createdAt.isAtSameMomentAs(_fromDate!)).toList();
      }
      if (_toDate != null) {
        final endOfDay = _toDate!.add(const Duration(days: 1));
        allReports = allReports.where((r) => r.createdAt.isBefore(endOfDay)).toList();
      }

      reports = allReports;
    });

    setState(() {
      _citations = citations;
      _reports = reports;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        citationStatus: _citationStatusFilter,
        citationType: _citationTypeFilter,
        reportStatus: _reportStatusFilter,
        fromDate: _fromDate,
        toDate: _toDate,
        onApply: (citStatus, citType, repStatus, from, to) {
          setState(() {
            _citationStatusFilter = citStatus;
            _citationTypeFilter = citType;
            _reportStatusFilter = repStatus;
            _fromDate = from;
            _toDate = to;
          });
          _triggerSearch();
        },
        onClear: () {
          setState(() {
            _citationStatusFilter = null;
            _citationTypeFilter = null;
            _reportStatusFilter = null;
            _fromDate = null;
            _toDate = null;
          });
          if (_searchController.text.trim().length >= 2) {
            _triggerSearch();
          } else {
            setState(() {
              _citations = [];
              _reports = [];
              _hasSearched = false;
            });
          }
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _citationStatusFilter = null;
      _citationTypeFilter = null;
      _reportStatusFilter = null;
      _fromDate = null;
      _toDate = null;
    });
    if (_searchController.text.trim().length >= 2) {
      _triggerSearch();
    } else {
      setState(() {
        _citations = [];
        _reports = [];
        _hasSearched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Consultas',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          Badge(
            isLabelVisible: _hasActiveFilters,
            label: Text('$_activeFilterCount'),
            backgroundColor: AppTheme.primary,
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showFilterSheet,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: AppTheme.surfaceWhite,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, RUT, patente, direccion...',
                hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Active filters chips
          if (_hasActiveFilters)
            Container(
              color: AppTheme.surfaceWhite,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildActiveFiltersBar(),
            ),

          // Tabs
          if (_hasSearched) ...[
            Container(
              color: AppTheme.surfaceWhite,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: 'Citaciones (${_citations.length})'),
                  Tab(text: 'Denuncias (${_reports.length})'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCitationsList(),
                        _buildReportsList(),
                      ],
                    ),
            ),
          ] else ...[
            Expanded(child: _buildInitialState()),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    final dateFormat = DateFormat('dd/MM/yy');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_fromDate != null || _toDate != null)
            _buildFilterChip(
              Icons.date_range_rounded,
              _fromDate != null && _toDate != null
                  ? '${dateFormat.format(_fromDate!)} - ${dateFormat.format(_toDate!)}'
                  : _fromDate != null
                      ? 'Desde ${dateFormat.format(_fromDate!)}'
                      : 'Hasta ${dateFormat.format(_toDate!)}',
              () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
                _triggerSearch();
              },
            ),
          if (_citationStatusFilter != null)
            _buildFilterChip(
              Icons.gavel_rounded,
              _citationStatusFilter!.displayName,
              () {
                setState(() => _citationStatusFilter = null);
                _triggerSearch();
              },
            ),
          if (_citationTypeFilter != null)
            _buildFilterChip(
              Icons.category_outlined,
              _citationTypeFilter!.displayName,
              () {
                setState(() => _citationTypeFilter = null);
                _triggerSearch();
              },
            ),
          if (_reportStatusFilter != null)
            _buildFilterChip(
              Icons.report_problem_outlined,
              _reportStatusFilter!.name,
              () {
                setState(() => _reportStatusFilter = null);
                _triggerSearch();
              },
            ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('Limpiar'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(IconData icon, String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        avatar: Icon(icon, size: 16, color: AppTheme.primary),
        label: Text(label, style: AppTheme.labelSmall.copyWith(color: AppTheme.textPrimary)),
        onDeleted: onRemove,
        deleteIconColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_rounded,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Buscar citaciones y denuncias',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ingresa nombre, RUT, patente, direccion o usa los filtros',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Quick date shortcuts
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickDateButton('Hoy', () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                setState(() {
                  _fromDate = today;
                  _toDate = today;
                });
                _triggerSearch();
              }),
              const SizedBox(width: 8),
              _buildQuickDateButton('Esta semana', () {
                final now = DateTime.now();
                final monday = now.subtract(Duration(days: now.weekday - 1));
                setState(() {
                  _fromDate = DateTime(monday.year, monday.month, monday.day);
                  _toDate = DateTime(now.year, now.month, now.day);
                });
                _triggerSearch();
              }),
              const SizedBox(width: 8),
              _buildQuickDateButton('Este mes', () {
                final now = DateTime.now();
                setState(() {
                  _fromDate = DateTime(now.year, now.month, 1);
                  _toDate = DateTime(now.year, now.month, now.day);
                });
                _triggerSearch();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label, style: AppTheme.labelSmall),
    );
  }

  Widget _buildCitationsList() {
    if (_citations.isEmpty) {
      return _buildEmptyResults('citaciones');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _citations.length,
      itemBuilder: (context, index) {
        final citation = _citations[index];
        return _buildCitationCard(citation);
      },
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return _buildEmptyResults('denuncias');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildEmptyResults(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'Sin resultados en $type',
            style: AppTheme.titleSmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Intenta con otro termino o ajusta los filtros',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationCard(CitationEntity citation) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(citation.createdAt);
    final statusColor = citation.status.color(context);
    final statusBgColor = citation.status.backgroundColor(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CitationDetailScreen(citation: citation),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    citation.citationType == CitationType.advertencia
                        ? Icons.warning_amber_rounded
                        : Icons.gavel_rounded,
                    color: AppTheme.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        citation.citationNumber,
                        style: AppTheme.titleSmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    citation.status.displayName,
                    style: AppTheme.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (citation.targetName != null || citation.targetRut != null)
              _buildInfoRow(
                Icons.person_outline_rounded,
                [
                  if (citation.targetName != null) citation.targetName!,
                  if (citation.targetRut != null) citation.targetRut!,
                ].join(' - '),
              ),
            if (citation.targetPlate != null)
              _buildInfoRow(Icons.directions_car_outlined, citation.targetPlate!),
            if (citation.targetAddress != null || citation.locationAddress != null)
              _buildInfoRow(
                Icons.location_on_outlined,
                citation.targetAddress ?? citation.locationAddress ?? '',
              ),
            const SizedBox(height: 8),
            Text(
              citation.reason,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportEntity report) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt);
    final statusColor = _reportStatusColor(report.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: AppTheme.titleSmall.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateStr,
                        style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.name,
                    style: AppTheme.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (report.citizenName != null)
              _buildInfoRow(Icons.person_outline_rounded, report.citizenName!),
            _buildInfoRow(Icons.category_outlined, report.category),
            if (report.location.address != null)
              _buildInfoRow(Icons.location_on_outlined, report.location.address!),
            const SizedBox(height: 8),
            Text(
              report.description,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _reportStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente:
        return AppTheme.warning;
      case ReportStatus.enProceso:
        return AppTheme.info;
      case ReportStatus.resuelto:
        return AppTheme.success;
      case ReportStatus.rechazado:
        return AppTheme.emergency;
    }
  }
}

// ─── Filter Bottom Sheet ────────────────────────────────────────────

class _FilterBottomSheet extends StatefulWidget {
  final CitationStatus? citationStatus;
  final CitationType? citationType;
  final ReportStatus? reportStatus;
  final DateTime? fromDate;
  final DateTime? toDate;
  final void Function(
    CitationStatus? citStatus,
    CitationType? citType,
    ReportStatus? repStatus,
    DateTime? from,
    DateTime? to,
  ) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    this.citationStatus,
    this.citationType,
    this.reportStatus,
    this.fromDate,
    this.toDate,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late CitationStatus? _citationStatus;
  late CitationType? _citationType;
  late ReportStatus? _reportStatus;
  late DateTime? _fromDate;
  late DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _citationStatus = widget.citationStatus;
    _citationType = widget.citationType;
    _reportStatus = widget.reportStatus;
    _fromDate = widget.fromDate;
    _toDate = widget.toDate;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      locale: const Locale('es', 'CL'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onClear();
                  },
                  child: Text(
                    'Limpiar todo',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.emergency),
                  ),
                ),
              ],
            ),
          ),

          // Date range
          _buildSectionTitle('Rango de fechas'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(
                _fromDate != null && _toDate != null
                    ? '${dateFormat.format(_fromDate!)} - ${dateFormat.format(_toDate!)}'
                    : 'Seleccionar rango de fechas',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _fromDate != null ? AppTheme.primary : AppTheme.textSecondary,
                side: BorderSide(
                  color: _fromDate != null
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.border,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Citation status
          _buildSectionTitle('Estado de citacion'),
          _buildChipRow<CitationStatus>(
            values: CitationStatus.values,
            selected: _citationStatus,
            label: (s) => s.displayName,
            onSelected: (s) => setState(() => _citationStatus = _citationStatus == s ? null : s),
          ),

          const SizedBox(height: 16),

          // Citation type
          _buildSectionTitle('Tipo de citacion'),
          _buildChipRow<CitationType>(
            values: CitationType.values,
            selected: _citationType,
            label: (t) => t.displayName,
            onSelected: (t) => setState(() => _citationType = _citationType == t ? null : t),
          ),

          const SizedBox(height: 16),

          // Report status
          _buildSectionTitle('Estado de denuncia'),
          _buildChipRow<ReportStatus>(
            values: ReportStatus.values,
            selected: _reportStatus,
            label: (s) => s.name,
            onSelected: (s) => setState(() => _reportStatus = _reportStatus == s ? null : s),
          ),

          const SizedBox(height: 24),

          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(
                    _citationStatus,
                    _citationType,
                    _reportStatus,
                    _fromDate,
                    _toDate,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: const Text('Aplicar filtros', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildChipRow<T>({
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    required void Function(T) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: values.map((v) {
          final isSelected = v == selected;
          return ChoiceChip(
            label: Text(label(v)),
            selected: isSelected,
            onSelected: (_) => onSelected(v),
            selectedColor: AppTheme.primary.withValues(alpha: 0.15),
            labelStyle: AppTheme.labelSmall.copyWith(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.border,
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }
}
