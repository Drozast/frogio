// lib/features/admin/presentation/pages/admin_data_explorer.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../citizen/presentation/pages/enhanced_report_detail_screen.dart';
import '../../../inspector/data/models/citation_model.dart';
import '../../../inspector/presentation/pages/citation_detail_screen.dart';
import '../../../panic/presentation/pages/panic_alert_detail_screen.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import 'route_playback_screen.dart';

/// Admin-only screen for exploring, exporting and importing
/// large datasets across the app's modules.
class AdminDataExplorer extends StatefulWidget {
  final UserEntity user;

  const AdminDataExplorer({super.key, required this.user});

  @override
  State<AdminDataExplorer> createState() => _AdminDataExplorerState();
}

class _AdminDataExplorerState extends State<AdminDataExplorer>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  static const _tabs = <String>[
    'Citaciones',
    'Denuncias',
    'SOS',
    'Vehiculos',
    'Bitacoras',
    'Usuarios',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSectionHeader(),
            _buildTabBar(),
            const SizedBox(height: AppTheme.spacing8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CitationsTab(user: widget.user),
                  _ReportsTab(user: widget.user),
                  _SosTab(user: widget.user),
                  _VehiclesTab(user: widget.user),
                  _VehicleLogsTab(user: widget.user),
                  _UsersTab(user: widget.user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradientVertical,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Explorador de Datos', style: AppTheme.headlineSmall),
                Text(
                  'Filtra, exporta e importa registros del municipio',
                  style: AppTheme.labelSmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'ADMIN',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final icons = <IconData>[
      Icons.assignment_rounded,
      Icons.report_problem_rounded,
      Icons.warning_amber_rounded,
      Icons.directions_car_rounded,
      Icons.route_rounded,
      Icons.people_rounded,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _tabs.length,
        itemBuilder: (ctx, i) {
          return AnimatedBuilder(
            animation: _tabController.animation ?? _tabController,
            builder: (_, __) {
              final isSelected = _tabController.index == i;
              return _PillTab(
                label: _tabs[i],
                icon: icons[i],
                selected: isSelected,
                onTap: () => _tabController.animateTo(i),
              );
            },
          );
        },
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppTheme.border.withValues(alpha: 0.6),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generic tab scaffold — handles filters, fetching, list and action row.
// ═══════════════════════════════════════════════════════════════════════════

abstract class _DatasetTab<T> extends StatefulWidget {
  final UserEntity user;
  const _DatasetTab({required this.user});
}

abstract class _DatasetTabState<T, W extends _DatasetTab<T>> extends State<W>
    with AutomaticKeepAliveClientMixin {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String? _status;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  bool get wantKeepAlive => true;

  AuthHttpClient get _client => di.sl<AuthHttpClient>();

  // Hooks to be overridden
  String get title;
  String get subtitle;
  String get filenamePrefix;
  List<String>? get statusOptions => null;
  ImportDataset? get importDataset;
  List<String> get csvHeaders;
  List<dynamic> csvRow(Map<String, dynamic> item);
  Widget buildItemCard(Map<String, dynamic> item);

  Future<List<Map<String, dynamic>>> fetch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await fetch();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppTheme.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _range = picked);
      _load();
    }
  }

  Future<void> _onExportCsv() async {
    if (_items.isEmpty) {
      _snack('No hay registros para exportar');
      return;
    }
    try {
      final rows = _items.map(csvRow).toList();
      await ExportService.exportCsv(
        filenamePrefix: filenamePrefix,
        headers: csvHeaders,
        rows: rows,
      );
    } catch (e) {
      _snack('Error al exportar CSV: $e');
    }
  }

  Future<void> _onExportPdf() async {
    if (_items.isEmpty) {
      _snack('No hay registros para exportar');
      return;
    }
    _snack('Generando PDF...');
    try {
      final rows = _items
          .map((i) => csvRow(i).map((e) => (e ?? '').toString()).toList())
          .toList();
      await ExportService.exportPdf(
        title: title,
        subtitle: subtitle,
        headers: csvHeaders,
        rows: rows,
        generatedBy: widget.user.displayName,
      );
    } catch (e) {
      _snack('Error al exportar PDF: $e');
    }
  }

  Future<void> _onImport() async {
    final ds = importDataset;
    if (ds == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Importar ${ds.label}',
                  textAlign: TextAlign.center,
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing8),
                const Text(
                  'Elige una opción',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacing20),
                _ImportOptionTile(
                  icon: Icons.download_rounded,
                  color: AppTheme.info,
                  title: 'Descargar plantilla',
                  subtitle: 'Obtén el CSV con los campos requeridos',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await ImportService.shareTemplate(ds);
                    } catch (e) {
                      _snack('Error: $e');
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacing12),
                _ImportOptionTile(
                  icon: Icons.upload_file_rounded,
                  color: AppTheme.primary,
                  title: 'Subir archivo',
                  subtitle: 'Selecciona un CSV y súbelo al servidor',
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _uploadFlow(ds);
                  },
                ),
                const SizedBox(height: AppTheme.spacing8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadFlow(ImportDataset ds) async {
    try {
      final file = await ImportService.pickCsv();
      if (file == null) return;
      final rows = await ImportService.parseCsv(file);
      if (rows.isEmpty) {
        _snack('El archivo está vacío');
        return;
      }
      _snack('Subiendo ${rows.length} registros...');
      final summary = await ImportService.uploadRows(
        dataset: ds,
        rows: rows,
      );
      _snack(
        'Importados: ${summary.inserted} · Fallidos: ${summary.failed}',
      );
      _load();
    } catch (e) {
      _snack('Error al importar: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildFilters(),
          const SizedBox(height: AppTheme.spacing12),
          _buildActions(),
          const SizedBox(height: AppTheme.spacing16),
          _buildResultHeader(),
          const SizedBox(height: AppTheme.spacing8),
          if (_loading)
            _buildSkeletonList()
          else if (_error != null)
            _errorBox(_error!)
          else if (_items.isEmpty)
            _emptyBox()
          else
            ..._items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 320 + (idx * 50).clamp(0, 500)),
                curve: Curves.easeOutCubic,
                builder: (ctx, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 14),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
                  child: buildItemCard(item),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    if (_loading || _error != null) return const SizedBox.shrink();
    final count = _items.length;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(
        children: [
          Text('$count',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
          const SizedBox(width: 6),
          Text(count == 1 ? 'registro' : 'registros',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('Actualizado',
                      style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.success, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final df = DateFormat('dd MMM');
    final opts = statusOptions;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: _pickRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          size: 14, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rango',
                              style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.textTertiary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${df.format(_range.start)} - ${df.format(_range.end)}',
                            style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (opts != null) ...[
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            flex: 2,
            child: _StatusDropdownChip(
              value: _status,
              options: opts,
              onChanged: (v) {
                setState(() => _status = v);
                _load();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    final buttons = <Widget>[
      _ActionButton(
        icon: Icons.grid_on_rounded,
        label: 'CSV',
        color: AppTheme.info,
        onTap: _onExportCsv,
      ),
      _ActionButton(
        icon: Icons.picture_as_pdf_rounded,
        label: 'PDF',
        color: AppTheme.emergency,
        onTap: _onExportPdf,
      ),
    ];
    if (importDataset != null) {
      buttons.add(
        _ActionButton(
          icon: Icons.upload_rounded,
          label: 'Importar',
          color: AppTheme.primary,
          onTap: _onImport,
          highlighted: true,
        ),
      );
    }
    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: buttons[i]),
          if (i < buttons.length - 1) const SizedBox(width: AppTheme.spacing8),
        ],
      ],
    );
  }

  Widget _buildSkeletonList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.borderLight,
      highlightColor: AppTheme.surfaceWhite,
      child: Column(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.3)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.emergencyLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 36, color: AppTheme.emergency),
          ),
          const SizedBox(height: 12),
          const Text('Error al cargar', style: AppTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            msg,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.15),
                  AppTheme.accent.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 46, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('Sin registros', style: AppTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'No hay datos para los filtros seleccionados.\nAjusta el rango de fechas o el estado.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Ajustar filtros'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers for subclasses
  String fmtDate(dynamic iso) {
    if (iso == null) return '-';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(d);
    } catch (_) {
      return iso.toString();
    }
  }

  String get fromIso => _range.start.toUtc().toIso8601String();
  String get toIso => _range.end
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1))
      .toUtc()
      .toIso8601String();

  String? get statusFilter => _status;

  /// Show a generic details modal with all key/value pairs of [item].
  /// Used when no dedicated detail screen exists for that dataset.
  void _showItemDetails(
      BuildContext context, String typeLabel, Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Detalle · $typeLabel',
                  style: AppTheme.titleLarge
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...item.entries
                  .where((e) => e.value != null && e.value.toString().isNotEmpty)
                  .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                e.key,
                                style: AppTheme.labelSmall
                                    .copyWith(color: AppTheme.textTertiary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value.toString(),
                                style: AppTheme.bodySmall
                                    .copyWith(color: AppTheme.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }

  /// Filter a list of items to those whose [dateField] falls within [_range].
  /// Items without a parseable date are kept.
  List<Map<String, dynamic>> _filterByDate(
    List<Map<String, dynamic>> items,
    String dateField,
  ) {
    final start = _range.start;
    final end = _range.end.add(const Duration(days: 1));
    return items.where((i) {
      final raw = i[dateField];
      if (raw == null) return true;
      try {
        final d = DateTime.parse(raw.toString()).toLocal();
        return !d.isBefore(start) && d.isBefore(end);
      } catch (_) {
        return true;
      }
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Citations Tab
// ═══════════════════════════════════════════════════════════════════════════

class _CitationsTab extends _DatasetTab<Map<String, dynamic>> {
  const _CitationsTab({required super.user});

  @override
  State<_CitationsTab> createState() => _CitationsTabState();
}

class _CitationsTabState
    extends _DatasetTabState<Map<String, dynamic>, _CitationsTab> {
  @override
  String get title => 'Reporte de Citaciones';
  @override
  String get subtitle =>
      'Del ${DateFormat('dd/MM/yyyy').format(_range.start)} al ${DateFormat('dd/MM/yyyy').format(_range.end)}';
  @override
  String get filenamePrefix => 'citaciones';
  @override
  ImportDataset? get importDataset => ImportDataset.citations;
  @override
  List<String>? get statusOptions =>
      const ['pendiente', 'pagada', 'vencida', 'anulada'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Numero',
        'Tipo',
        'Infractor',
        'RUT',
        'Motivo',
        'Fecha',
        'Estado',
        'Direccion',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['citation_number'] ?? '',
        item['citation_type'] ?? '',
        item['target_name'] ?? '',
        item['target_rut'] ?? '',
        item['reason'] ?? '',
        fmtDate(item['created_at']),
        item['status'] ?? '',
        item['location_address'] ?? '',
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final uri = Uri.parse(
        '${ApiConfig.activeBaseUrl}/api/citations?from=$fromIso&to=$toIso');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? (body['citations'] as List?) ?? const [];
    var items = list.whereType<Map<String, dynamic>>().toList();
    // Client-side date filter since /api/citations ignores query params
    items = _filterByDate(items, 'created_at');
    if (statusFilter != null) {
      items = items
          .where((i) =>
              (i['status'] ?? '').toString().toLowerCase() ==
              statusFilter!.toLowerCase())
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    return _ItemCard(
      title:
          '${item['citation_number'] ?? 'Sin número'} · ${item['citation_type'] ?? ''}',
      subtitle: (item['target_name'] ?? '').toString(),
      meta: [
        if ((item['target_rut'] ?? '').toString().isNotEmpty)
          'RUT: ${item['target_rut']}',
        if ((item['location_address'] ?? '').toString().isNotEmpty)
          item['location_address'].toString(),
        fmtDate(item['created_at']),
      ],
      description: (item['reason'] ?? '').toString(),
      status: status,
      onTap: () {
        try {
          final citation = CitationModel.fromJson(item).toEntity();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CitationDetailScreen(citation: citation),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo abrir la citación: $e')),
          );
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reports (Denuncias) Tab
// ═══════════════════════════════════════════════════════════════════════════

class _ReportsTab extends _DatasetTab<Map<String, dynamic>> {
  const _ReportsTab({required super.user});

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState
    extends _DatasetTabState<Map<String, dynamic>, _ReportsTab> {
  @override
  String get title => 'Reporte de Denuncias';
  @override
  String get subtitle =>
      'Del ${DateFormat('dd/MM/yyyy').format(_range.start)} al ${DateFormat('dd/MM/yyyy').format(_range.end)}';
  @override
  String get filenamePrefix => 'denuncias';
  @override
  ImportDataset? get importDataset => ImportDataset.reports;
  @override
  List<String>? get statusOptions =>
      const ['pending', 'in_progress', 'resolved', 'rejected'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Título',
        'Categoría',
        'Prioridad',
        'Estado',
        'Ciudadano',
        'Dirección',
        'Fecha',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['title'] ?? '',
        item['category'] ?? '',
        item['priority'] ?? '',
        item['status'] ?? '',
        item['citizen_name'] ?? '',
        item['address'] ?? '',
        fmtDate(item['created_at']),
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final qp = <String, String>{'from': fromIso, 'to': toIso};
    if (statusFilter != null) qp['status'] = statusFilter!;
    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/api/reports')
        .replace(queryParameters: qp);
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List?) ?? (body['reports'] as List?) ?? const [];
    var items = list.whereType<Map<String, dynamic>>().toList();
    items = _filterByDate(items, 'created_at');
    if (statusFilter != null) {
      items = items
          .where((i) =>
              (i['status'] ?? '').toString().toLowerCase() ==
              statusFilter!.toLowerCase())
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    final id = (item['id'] ?? '').toString();
    return _ItemCard(
      title: (item['title'] ?? 'Denuncia').toString(),
      subtitle: (item['category'] ?? '').toString(),
      meta: [
        if ((item['citizen_name'] ?? '').toString().isNotEmpty)
          item['citizen_name'].toString(),
        if ((item['address'] ?? '').toString().isNotEmpty)
          item['address'].toString(),
        fmtDate(item['created_at']),
        if ((item['priority'] ?? '').toString().isNotEmpty)
          'Prioridad: ${item['priority']}',
      ],
      status: (item['status'] ?? '').toString(),
      onTap: id.isEmpty
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnhancedReportDetailScreen(
                    reportId: id,
                    currentUserRole: 'admin',
                  ),
                ),
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SOS Tab (no import)
// ═══════════════════════════════════════════════════════════════════════════

class _SosTab extends _DatasetTab<Map<String, dynamic>> {
  const _SosTab({required super.user});

  @override
  State<_SosTab> createState() => _SosTabState();
}

class _SosTabState extends _DatasetTabState<Map<String, dynamic>, _SosTab> {
  @override
  String get title => 'Reporte de Alertas SOS';
  @override
  String get subtitle =>
      'Del ${DateFormat('dd/MM/yyyy').format(_range.start)} al ${DateFormat('dd/MM/yyyy').format(_range.end)}';
  @override
  String get filenamePrefix => 'sos_alertas';
  @override
  ImportDataset? get importDataset => null;
  @override
  List<String>? get statusOptions =>
      const ['active', 'responding', 'resolved', 'cancelled'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Nombre',
        'Apellido',
        'Teléfono',
        'Dirección',
        'Estado',
        'Fecha',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['first_name'] ?? '',
        item['last_name'] ?? '',
        item['contact_phone'] ?? '',
        item['address'] ?? '',
        item['status'] ?? '',
        fmtDate(item['created_at']),
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['data'] as List?) ?? (decoded['alerts'] as List?) ?? const [];
    } else {
      list = const [];
    }
    var items = list.whereType<Map<String, dynamic>>().toList();
    items = _filterByDate(items, 'created_at');

    if (statusFilter != null) {
      items = items
          .where((i) =>
              (i['status'] ?? '').toString().toLowerCase() ==
              statusFilter!.toLowerCase())
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    final name =
        '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim();
    return _ItemCard(
      leading: const Icon(Icons.warning_amber_rounded,
          color: AppTheme.emergency, size: 28),
      title: name.isEmpty ? 'Alerta SOS' : name,
      subtitle: (item['contact_phone'] ?? '').toString(),
      meta: [
        if ((item['address'] ?? '').toString().isNotEmpty)
          item['address'].toString(),
        fmtDate(item['created_at']),
      ],
      status: (item['status'] ?? '').toString(),
      statusColorOverride: AppTheme.emergency,
      onTap: () {
        final id = (item['id'] ?? '').toString();
        final lat = (item['latitude'] as num?)?.toDouble();
        final lng = (item['longitude'] as num?)?.toDouble();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PanicAlertDetailScreen(
              alertId: id.isEmpty ? null : id,
              latitude: lat,
              longitude: lng,
              message: (item['message'] ?? '').toString(),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Vehicles Tab
// ═══════════════════════════════════════════════════════════════════════════

class _VehiclesTab extends _DatasetTab<Map<String, dynamic>> {
  const _VehiclesTab({required super.user});

  @override
  State<_VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState
    extends _DatasetTabState<Map<String, dynamic>, _VehiclesTab> {
  @override
  String get title => 'Flota Municipal';
  @override
  String get subtitle =>
      'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  @override
  String get filenamePrefix => 'vehiculos';
  @override
  ImportDataset? get importDataset => null;
  @override
  List<String>? get statusOptions =>
      const ['available', 'in_use', 'maintenance', 'out_of_service'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Placa',
        'Marca',
        'Modelo',
        'Año',
        'Estado',
        'Kilometraje',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['plate'] ?? '',
        item['brand'] ?? '',
        item['model'] ?? '',
        item['year'] ?? '',
        item['status'] ?? '',
        item['currentKm'] ?? item['current_km'] ?? '',
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['data'] as List?) ?? (decoded['vehicles'] as List?) ?? const [];
    } else {
      list = const [];
    }
    var items = list.whereType<Map<String, dynamic>>().toList();
    if (statusFilter != null) {
      items = items
          .where((i) {
            final s = (i['status'] ??
                    (i['is_active'] == true ? 'available' : 'out_of_service'))
                .toString()
                .toLowerCase();
            return s == statusFilter!.toLowerCase();
          })
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    return _ItemCard(
      leading: const Icon(Icons.directions_car_rounded,
          color: AppTheme.primary, size: 28),
      title: (item['plate'] ?? 'Sin placa').toString(),
      subtitle:
          '${item['brand'] ?? ''} ${item['model'] ?? ''} ${item['year'] ?? ''}'
              .trim(),
      meta: [
        if ((item['currentKm'] ?? item['current_km']) != null)
          'Kilometraje: ${item['currentKm'] ?? item['current_km']} km',
      ],
      status: (item['status'] ?? '').toString(),
      onTap: () => _showItemDetails(context, 'Vehículo', item),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Vehicle Logs (Bitacoras) Tab
// ═══════════════════════════════════════════════════════════════════════════

class _VehicleLogsTab extends _DatasetTab<Map<String, dynamic>> {
  const _VehicleLogsTab({required super.user});

  @override
  State<_VehicleLogsTab> createState() => _VehicleLogsTabState();
}

class _VehicleLogsTabState
    extends _DatasetTabState<Map<String, dynamic>, _VehicleLogsTab> {
  @override
  String get title => 'Bitácoras de Vehículos';
  @override
  String get subtitle =>
      'Del ${DateFormat('dd/MM/yyyy').format(_range.start)} al ${DateFormat('dd/MM/yyyy').format(_range.end)}';
  @override
  String get filenamePrefix => 'bitacoras';
  @override
  ImportDataset? get importDataset => null;
  @override
  List<String>? get statusOptions =>
      const ['active', 'completed', 'cancelled'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Placa',
        'Conductor',
        'Inicio',
        'Fin',
        'Km Inicial',
        'Km Final',
        'Distancia',
        'Estado',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['vehicle_plate'] ?? '',
        item['driver_name'] ?? '',
        fmtDate(item['start_time']),
        fmtDate(item['end_time']),
        item['start_km'] ?? '',
        item['end_km'] ?? '',
        item['total_distance_km'] ?? '',
        item['status'] ?? '',
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/logs');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['data'] as List?) ?? (decoded['logs'] as List?) ?? const [];
    } else {
      list = const [];
    }
    var items = list.whereType<Map<String, dynamic>>().toList();
    items = _filterByDate(items, 'start_time');
    if (statusFilter != null) {
      items = items
          .where((i) =>
              (i['status'] ?? '').toString().toLowerCase() ==
              statusFilter!.toLowerCase())
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    final logId = (item['id'] ?? '').toString();
    return _ItemCard(
      leading: const Icon(Icons.route_rounded,
          color: AppTheme.info, size: 28),
      title:
          '${item['vehicle_plate'] ?? 'Sin placa'} · ${item['driver_name'] ?? ''}',
      subtitle:
          'Inicio: ${fmtDate(item['start_time'])}  ·  Fin: ${fmtDate(item['end_time'])}',
      meta: [
        if (item['start_km'] != null) 'Km inicial: ${item['start_km']}',
        if (item['end_km'] != null) 'Km final: ${item['end_km']}',
        if (item['total_distance_km'] != null)
          'Distancia: ${item['total_distance_km']} km',
      ],
      status: (item['status'] ?? '').toString(),
      onTap: logId.isEmpty
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutePlaybackScreen(
                    vehicleLogId: logId,
                    plate: (item['vehicle_plate'] ?? '').toString(),
                    driverName: (item['driver_name'] ?? '').toString(),
                  ),
                ),
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Users Tab
// ═══════════════════════════════════════════════════════════════════════════

class _UsersTab extends _DatasetTab<Map<String, dynamic>> {
  const _UsersTab({required super.user});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends _DatasetTabState<Map<String, dynamic>, _UsersTab> {
  @override
  String get title => 'Usuarios';
  @override
  String get subtitle =>
      'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
  @override
  String get filenamePrefix => 'usuarios';
  @override
  ImportDataset? get importDataset => ImportDataset.users;
  @override
  List<String>? get statusOptions =>
      const ['admin', 'inspector', 'citizen', 'vehicle_user'];

  @override
  List<String> get csvHeaders => const [
        'ID',
        'Email',
        'Nombre',
        'Apellido',
        'Rol',
        'Activo',
      ];

  @override
  List<dynamic> csvRow(Map<String, dynamic> item) => [
        item['id'] ?? '',
        item['email'] ?? '',
        item['firstName'] ?? item['first_name'] ?? '',
        item['lastName'] ?? item['last_name'] ?? '',
        item['role'] ?? '',
        (item['isActive'] ?? item['is_active'] ?? true).toString(),
      ];

  @override
  Future<List<Map<String, dynamic>>> fetch() async {
    final uri = Uri.parse('${ApiConfig.activeBaseUrl}/api/users');
    final res = await _client.get(uri);
    if (res.statusCode >= 400) {
      throw Exception('Error ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['data'] as List?) ?? (decoded['users'] as List?) ?? const [];
    } else {
      list = const [];
    }
    var items = list.whereType<Map<String, dynamic>>().toList();
    if (statusFilter != null) {
      items = items
          .where((i) =>
              (i['role'] ?? '').toString().toLowerCase() ==
              statusFilter!.toLowerCase())
          .toList();
    }
    return items;
  }

  @override
  Widget buildItemCard(Map<String, dynamic> item) {
    // API may return camelCase (firstName/isActive) or snake_case
    final first = (item['firstName'] ?? item['first_name'] ?? '').toString();
    final last = (item['lastName'] ?? item['last_name'] ?? '').toString();
    final name = '$first $last'.trim();
    final active = item['isActive'] ?? item['is_active'] ?? true;
    return _ItemCard(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primarySurface,
        child: Text(
          (name.isNotEmpty ? name[0] : '?').toUpperCase(),
          style: AppTheme.titleMedium.copyWith(color: AppTheme.primary),
        ),
      ),
      title: name.isEmpty ? (item['email'] ?? 'Usuario').toString() : name,
      subtitle: (item['email'] ?? '').toString(),
      meta: [
        'Rol: ${item['role'] ?? '-'}',
        active == true ? 'Activo' : 'Inactivo',
      ],
      status: (item['role'] ?? '').toString(),
      statusColorOverride:
          active == true ? AppTheme.success : AppTheme.textTertiary,
      onTap: () => _showItemDetails(context, 'Usuario', item),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Reusable UI building blocks
// ═══════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: highlighted
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.95),
                      color,
                    ],
                  )
                : null,
            color: highlighted ? null : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: highlighted
                  ? Colors.transparent
                  : color.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: highlighted ? Colors.white : color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelSmall.copyWith(
                    fontSize: 12,
                    color: highlighted ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDropdownChip extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _StatusDropdownChip({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: hasValue
              ? AppTheme.primary.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.filter_alt_rounded,
                    size: 14, color: AppTheme.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Estado',
                        style: AppTheme.labelSmall.copyWith(
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w600)),
                    Text('Todos',
                        style: AppTheme.labelMedium.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppTheme.textSecondary),
          style: AppTheme.labelMedium.copyWith(color: AppTheme.textPrimary),
          selectedItemBuilder: (ctx) => [
            _selectedLabel(null, '— —'),
            ...options.map((o) => _selectedLabel(o, o)),
          ],
          onChanged: onChanged,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos'),
            ),
            ...options.map(
              (o) => DropdownMenuItem<String?>(
                value: o,
                child: Text(o),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedLabel(String? v, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.filter_alt_rounded,
              size: 14, color: AppTheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Estado',
                  style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.textTertiary,
                      fontWeight: FontWeight.w600)),
              Text(v == null ? 'Todos' : label,
                  style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<String> meta;
  final String? description;
  final String status;
  final Color? statusColorOverride;
  final VoidCallback? onTap;

  const _ItemCard({
    this.leading,
    required this.title,
    this.subtitle,
    this.meta = const [],
    this.description,
    required this.status,
    this.statusColorOverride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = statusColorOverride ?? AppTheme.getStatusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onTap,
          child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            // Left accent strip tied to status
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: statusColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: leading!,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTheme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            if (status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusRound),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      status,
                                      style: AppTheme.labelSmall.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacing8),
                          Text(
                            description!,
                            style: AppTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacing8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: meta
                                .map(
                                  (m) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                      border: Border.all(
                                          color: AppTheme.border
                                              .withValues(alpha: 0.6)),
                                    ),
                                    child: Text(
                                      m,
                                      style: AppTheme.labelSmall.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleSmall.copyWith(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
