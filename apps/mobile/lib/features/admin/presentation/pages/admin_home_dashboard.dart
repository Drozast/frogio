// lib/features/admin/presentation/pages/admin_home_dashboard.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';

class AdminHomeDashboard extends StatefulWidget {
  final UserEntity user;
  final void Function(int)? onNavigateToTab;

  const AdminHomeDashboard({super.key, required this.user, this.onNavigateToTab});

  @override
  State<AdminHomeDashboard> createState() => _AdminHomeDashboardState();
}

class _AdminHomeDashboardState extends State<AdminHomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic>? _stats;
  List<dynamic> _dailyActivity = const [];
  bool _isLoading = true;
  String? _error;

  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadStats());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/dashboard/stats'),
      );
      if (res.statusCode == 200) {
        final raw = json.decode(res.body) as Map<String, dynamic>;
        // Flatten the nested dashboard payload so widgets keep using flat keys.
        final summary = (raw['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
        final recentActivity = (raw['recentActivity'] as Map?)?.cast<String, dynamic>() ?? const {};
        final bitacora = (raw['bitacora'] as Map?)?.cast<String, dynamic>() ?? const {};

        // Convert reportsByStatus map -> list
        final reportsByStatusMap = (raw['reportsByStatus'] as Map?)?.cast<String, dynamic>() ?? const {};
        final reportsByStatusList = reportsByStatusMap.entries
            .map((e) => {'status': e.key, 'count': e.value})
            .toList();

        final infractionsByStatusMap = (raw['infractionsByStatus'] as Map?)?.cast<String, dynamic>() ?? const {};
        final infractionsByStatusList = infractionsByStatusMap.entries
            .map((e) => {'status': e.key, 'count': e.value})
            .toList();

        final flat = {
          'users': summary['totalUsers'] ?? 0,
          'infractions': summary['totalInfractions'] ?? 0,
          'reports': summary['totalReports'] ?? 0,
          'vehicles': summary['totalVehicles'] ?? 0,
          'recentReports': recentActivity['reportsLast7Days'] ?? 0,
          'recentInfractions': recentActivity['infractionsLast7Days'] ?? 0,
          'activeLogs': bitacora['activeTrips'] ?? 0,
          'completedLogsToday': bitacora['completedToday'] ?? 0,
          'totalDistanceToday': bitacora['totalKmToday'] ?? 0,
          'recentLogs': bitacora['recentLogs'] ?? const [],
          'reportsByStatus': reportsByStatusList,
          'infractionsByStatus': infractionsByStatusList,
          'infractionsByType': raw['infractionsByType'] ?? const [],
        };

        if (mounted) {
          setState(() {
            _stats = flat;
            _dailyActivity = (raw['dailyActivity'] as List?) ?? const [];
            _isLoading = false;
            _error = null;
            _lastUpdated = DateTime.now();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Error ${res.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '0') ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primary,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_isLoading && _stats == null)
                SliverToBoxAdapter(child: _buildSkeleton())
              else if (_error != null && _stats == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildError(),
                )
              else ...[
                SliverToBoxAdapter(child: _buildSectionHeader()),
                SliverToBoxAdapter(child: _buildKpiGrid()),
                SliverToBoxAdapter(child: _buildLiveStrip()),
                SliverToBoxAdapter(child: _buildChartCard()),
                SliverToBoxAdapter(child: _buildStatusBreakdown()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildRecentActivity()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Section header

  Widget _buildSectionHeader() {
    final updated = _lastUpdated != null
        ? DateFormat('HH:mm:ss').format(_lastUpdated!)
        : '--';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
              children: [
                Text('Panel de Control',
                    style: AppTheme.headlineSmall.copyWith(letterSpacing: -0.3)),
                Text('Resumen en tiempo real · actualizado $updated',
                    style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary)),
              ],
            ),
          ),
          const _LivePulse(color: AppTheme.success),
        ],
      ),
    );
  }

  // ───────────────────────────── Skeleton

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.borderLight,
        highlightColor: AppTheme.surfaceWhite,
        child: Column(
          children: [
            Row(
              children: List.generate(
                2,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8, right: i == 0 ? 8 : 0),
                    child: _skelBox(140),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                2,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8, right: i == 0 ? 8 : 0),
                    child: _skelBox(140),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _skelBox(220),
            const SizedBox(height: 16),
            _skelBox(160),
          ],
        ),
      ),
    );
  }

  Widget _skelBox(double h) => Container(
        height: h,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
      );

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.emergencyLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppTheme.emergency),
          ),
          const SizedBox(height: 16),
          Text('Sin conexión', style: AppTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── KPI grid

  Widget _buildKpiGrid() {
    final s = _stats ?? {};

    final last14Spots = _spotsForLast14();
    final reportsRecent = _toInt(s['recentReports']);
    final infractionsRecent = _toInt(s['recentInfractions']);
    final activeLogs = _toInt(s['activeLogs']);

    // Tab indices: 0=Inicio 1=Operar 2=Datos 3=Mapa 4=Flota 5=Personal 6=Perfil
    final kpis = [
      _Kpi(
        label: 'Denuncias',
        value: _toInt(s['reports']),
        delta: reportsRecent,
        deltaLabel: 'esta semana',
        icon: Icons.report_problem_rounded,
        color: AppTheme.warning,
        sparkline: last14Spots,
        onTap: () => widget.onNavigateToTab?.call(2), // Datos -> Denuncias
      ),
      _Kpi(
        label: 'Citaciones',
        value: _toInt(s['infractions']),
        delta: infractionsRecent,
        deltaLabel: 'esta semana',
        icon: Icons.assignment_rounded,
        color: AppTheme.primary,
        sparkline: last14Spots,
        isHero: true,
        onTap: () => widget.onNavigateToTab?.call(2), // Datos -> Citaciones
      ),
      _Kpi(
        label: 'Usuarios',
        value: _toInt(s['users']),
        delta: 0,
        deltaLabel: 'totales',
        icon: Icons.people_rounded,
        color: AppTheme.info,
        onTap: () => widget.onNavigateToTab?.call(5), // Personal
      ),
      _Kpi(
        label: 'Flota',
        value: _toInt(s['vehicles']),
        delta: activeLogs,
        deltaLabel: 'en ruta',
        icon: Icons.directions_car_rounded,
        color: AppTheme.accent,
        onTap: () => widget.onNavigateToTab?.call(4), // Flota
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kpis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (ctx, i) => _buildKpiCard(kpis[i], i),
      ),
    );
  }

  List<FlSpot> _spotsForLast14() {
    final now = DateTime.now();
    final map = <String, int>{};
    for (int i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      map[key] = 0;
    }
    for (final item in _dailyActivity) {
      if (item is Map) {
        final dt = DateTime.tryParse(item['date']?.toString() ?? '')?.toLocal();
        if (dt == null) continue;
        final key = DateFormat('yyyy-MM-dd').format(dt);
        if (map.containsKey(key)) {
          map[key] = _toInt(item['count']);
        }
      }
    }
    final spots = <FlSpot>[];
    int x = 0;
    for (final entry in map.entries) {
      spots.add(FlSpot(x.toDouble(), entry.value.toDouble()));
      x++;
    }
    return spots;
  }

  Widget _buildKpiCard(_Kpi kpi, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (ctx, v, child) => Opacity(
        opacity: v.clamp(0, 1).toDouble(),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 16),
          child: child,
        ),
      ),
      child: _KpiCardInner(kpi: kpi),
    );
  }

  // ───────────────────────────── Live strip (mini stats)

  Widget _buildLiveStrip() {
    final s = _stats ?? {};
    final completedToday = _toInt(s['completedLogsToday']);
    final activeLogs = _toInt(s['activeLogs']);
    final kmToday = _toDouble(s['totalDistanceToday']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryDark.withValues(alpha: 0.95),
              AppTheme.primary.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _liveItem(Icons.local_shipping_rounded, '$activeLogs', 'En ruta'),
            _vDivider(),
            _liveItem(Icons.task_alt_rounded, '$completedToday', 'Completados hoy'),
            _vDivider(),
            _liveItem(Icons.route_rounded, '${kmToday.toStringAsFixed(0)} km',
                'Distancia hoy'),
          ],
        ),
      ),
    );
  }

  Widget _liveItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        height: 38,
        width: 1,
        color: Colors.white.withValues(alpha: 0.2),
      );

  // ───────────────────────────── Chart card

  Widget _buildChartCard() {
    // Group last 14 days
    final now = DateTime.now();
    final map = <String, int>{};
    for (int i = 13; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      map[key] = 0;
    }
    for (final item in _dailyActivity) {
      if (item is Map) {
        final dt = DateTime.tryParse(item['date']?.toString() ?? '')?.toLocal();
        if (dt == null) continue;
        final key = DateFormat('yyyy-MM-dd').format(dt);
        if (map.containsKey(key)) {
          map[key] = _toInt(item['count']);
        }
      }
    }

    final spots = <FlSpot>[];
    int x = 0;
    for (final entry in map.entries) {
      spots.add(FlSpot(x.toDouble(), entry.value.toDouble()));
      x++;
    }
    final maxY = (spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b) + 2)
        .clamp(4, double.infinity);

    final total = spots.fold<double>(0, (a, b) => a + b.y);
    final avg = spots.isEmpty ? 0.0 : total / spots.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
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
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Actividad - 14 días',
                        style: AppTheme.titleSmall),
                    Text(
                      'Total: ${total.toInt()} · Promedio diario: ${avg.toStringAsFixed(1)}',
                      style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY.toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).toDouble().clamp(1, double.infinity),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY / 4).toDouble().clamp(1, double.infinity),
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= map.length) return const SizedBox.shrink();
                        final date = map.keys.elementAt(i);
                        final d = DateTime.parse(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('dd/MM').format(d),
                            style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) => AppTheme.primaryDark,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touched) => touched.map((t) {
                      final i = t.x.toInt();
                      final date = i >= 0 && i < map.length
                          ? DateFormat('dd MMM').format(DateTime.parse(map.keys.elementAt(i)))
                          : '';
                      return LineTooltipItem(
                        '${t.y.toInt()}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: date,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) {
                        // Highlight the last dot
                        if (i == spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 4.5,
                            color: AppTheme.primary,
                            strokeColor: Colors.white,
                            strokeWidth: 2,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.3),
                          AppTheme.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Status breakdown

  Widget _buildStatusBreakdown() {
    final s = _stats ?? {};
    final reportsByStatus = (s['reportsByStatus'] as List?) ?? const [];
    final infractionsByType = (s['infractionsByType'] as List?) ?? const [];

    if (reportsByStatus.isEmpty && infractionsByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.donut_large_rounded,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Distribución', style: AppTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          if (reportsByStatus.isNotEmpty) ...[
            Text('Denuncias por estado',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            ...reportsByStatus.map((e) => _statusRow(
                  label: e['status']?.toString() ?? '-',
                  count: _toInt(e['count']),
                  total: reportsByStatus.fold<int>(0, (a, b) => a + _toInt(b['count'])),
                  color: _statusColor(e['status']?.toString() ?? ''),
                )),
          ],
          if (infractionsByType.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Citaciones - top tipos',
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            ...infractionsByType.take(3).map((e) => _statusRow(
                  label: e['type']?.toString() ?? '-',
                  count: _toInt(e['count']),
                  total: infractionsByType.fold<int>(0, (a, b) => a + _toInt(b['count'])),
                  color: AppTheme.primary,
                )),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return AppTheme.warning;
      case 'en_proceso':
      case 'responding':
        return AppTheme.info;
      case 'resuelto':
      case 'emitida':
      case 'completed':
        return AppTheme.success;
      case 'rechazado':
      case 'cancelled':
        return AppTheme.emergency;
      default:
        return AppTheme.textTertiary;
    }
  }

  Widget _statusRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary)),
              ),
              Text('$count',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: color, fontSize: 13)),
              const SizedBox(width: 6),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: pct),
              builder: (ctx, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Quick actions

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Operar', Icons.work_rounded, AppTheme.primary, 1),
      _QuickAction('Datos', Icons.bar_chart_rounded, AppTheme.info, 2),
      _QuickAction('Flota', Icons.directions_car_rounded, AppTheme.accent, 3),
      _QuickAction('Personal', Icons.badge_rounded, AppTheme.warning, 4),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradientVertical,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text('Accesos rápidos', style: AppTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: actions
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: e.key == 0 ? 0 : 4,
                          right: e.key == actions.length - 1 ? 0 : 4,
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 350 + e.key * 80),
                          curve: Curves.easeOutCubic,
                          builder: (ctx, v, child) => Opacity(
                            opacity: v.clamp(0, 1).toDouble(),
                            child: Transform.translate(
                              offset: Offset(0, (1 - v) * 12),
                              child: child,
                            ),
                          ),
                          child: _buildQuickActionCard(e.value),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction a) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => widget.onNavigateToTab?.call(a.tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: a.color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      a.color.withValues(alpha: 0.18),
                      a.color.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(a.icon, color: a.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(a.label,
                  style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Recent activity

  Widget _buildRecentActivity() {
    final recent = (_stats?['recentLogs'] as List?) ?? const [];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('Últimos viajes', style: AppTheme.titleSmall)),
              if (widget.onNavigateToTab != null)
                TextButton(
                  onPressed: () => widget.onNavigateToTab!.call(3),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Ver todos',
                      style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primary, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            _emptyMini(Icons.local_shipping_outlined, 'Sin viajes recientes')
          else
            ...recent.take(5).toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final m = (entry.value as Map).cast<String, dynamic>();
              final start = DateTime.tryParse(
                      (m['startTime'] ?? m['start_time'])?.toString() ?? '')
                  ?.toLocal();
              final dist = _toDouble(m['totalDistanceKm'] ?? m['total_distance_km']);
              final plate = (m['vehiclePlate'] ?? m['plate'] ?? '').toString();
              final driver = (m['driverName'] ?? m['driver_name'] ?? '').toString();
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + idx * 70),
                curve: Curves.easeOut,
                builder: (ctx, v, child) => Opacity(
                  opacity: v.clamp(0, 1).toDouble(),
                  child: Transform.translate(
                    offset: Offset((1 - v) * 16, 0),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.15),
                              AppTheme.primary.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plate.isEmpty ? 'Sin patente' : plate,
                              style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (driver.isNotEmpty)
                              Text(driver,
                                  style: AppTheme.labelSmall.copyWith(
                                      color: AppTheme.textSecondary)),
                            if (start != null)
                              Text(
                                DateFormat('dd MMM · HH:mm').format(start),
                                style: AppTheme.labelSmall.copyWith(
                                    color: AppTheme.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySurface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                        ),
                        child: Text('${dist.toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _emptyMini(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppTheme.textTertiary.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Text(label,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KPI card with sparkline
// ═══════════════════════════════════════════════════════════════════════════

class _KpiCardInner extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCardInner({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final hero = kpi.isHero;
    return Material(
      color: AppTheme.surfaceWhite,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: kpi.onTap,
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: kpi.color.withValues(alpha: hero ? 0.4 : 0.15),
          width: hero ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kpi.color.withValues(alpha: hero ? 0.18 : 0.08),
            blurRadius: hero ? 20 : 12,
            spreadRadius: hero ? 1 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kpi.color.withValues(alpha: 0.22),
                      kpi.color.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 18),
              ),
              const Spacer(),
              if (kpi.delta > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward_rounded,
                          size: 10, color: AppTheme.success),
                      const SizedBox(width: 2),
                      Text('${kpi.delta}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Animated number
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: kpi.value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (ctx, v, _) => Text(
              v.toInt().toString(),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: hero ? 34 : 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -1.2,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(kpi.label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              )),
          if (kpi.sparkline != null && kpi.sparkline!.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: _Sparkline(spots: kpi.sparkline!, color: kpi.color),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(kpi.deltaLabel,
                style: AppTheme.labelSmall
                    .copyWith(color: AppTheme.textTertiary)),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  const _Sparkline({required this.spots, required this.color});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox.shrink();
    final maxY = spots.map((s) => s.y).fold<double>(0, math.max);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 1 : maxY * 1.2,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Live pulse indicator
// ═══════════════════════════════════════════════════════════════════════════

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: widget.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctl,
            builder: (_, __) {
              final v = (math.sin(_ctl.value * 2 * math.pi) + 1) / 2;
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4 + 0.4 * v),
                      blurRadius: 4 + 4 * v,
                      spreadRadius: 1 + v,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text('LIVE',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: widget.color,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Models
// ═══════════════════════════════════════════════════════════════════════════

class _Kpi {
  final String label;
  final int value;
  final int delta;
  final String deltaLabel;
  final IconData icon;
  final Color color;
  final List<FlSpot>? sparkline;
  final bool isHero;
  final VoidCallback? onTap;
  _Kpi({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaLabel,
    required this.icon,
    required this.color,
    this.sparkline,
    this.isHero = false,
    this.onTap,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final int tabIndex;
  _QuickAction(this.label, this.icon, this.color, this.tabIndex);
}
