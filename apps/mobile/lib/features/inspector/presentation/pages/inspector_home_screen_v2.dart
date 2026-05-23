// lib/features/inspector/presentation/pages/inspector_home_screen_v2.dart

import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_manager.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../panic/presentation/pages/panic_alert_detail_screen.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/profile/profile_bloc.dart';
import '../../../panic/domain/repositories/panic_repository.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../../vehicles/presentation/widgets/active_trip_banner.dart';
import '../../../vehicles/presentation/pages/vehicle_selection_page.dart';
import '../../../vehicles/presentation/pages/vehicle_logs_screen.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_bloc.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_event.dart';
import '../../../citizen/presentation/bloc/report/enhanced_report_state.dart';
import '../../../citizen/presentation/pages/enhanced_report_detail_screen.dart';
import '../../../citizen/domain/entities/enhanced_report_entity.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import 'citation_detail_screen.dart';
import 'create_citation_screen.dart';
import 'create_inspector_report_screen.dart';
import 'inspector_map_screen.dart';
import 'search_screen.dart';

/// Pantalla principal del Inspector - Diseno Moderno Minimalista
///
/// Enfoque principal: Gestion de Citaciones
/// - CTA prominente para crear citaciones
/// - Lista de citaciones recientes
/// - Accesos secundarios a mapa y denuncias
class InspectorHomeScreenV2 extends StatefulWidget {
  final UserEntity user;
  final void Function(int)? onNavigateToTab;

  const InspectorHomeScreenV2({super.key, required this.user, this.onNavigateToTab});

  @override
  State<InspectorHomeScreenV2> createState() => _InspectorHomeScreenV2State();
}

class _InspectorHomeScreenV2State extends State<InspectorHomeScreenV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _panicCount = 0;
  int _cancelledPanicCount = 0;
  Map<String, dynamic>? _activeAlert;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _loadPanicCount();
    _setupPanicListener();

    // Iniciar auto-refresh después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoRefresh();
    });
  }

  void _setupPanicListener() {
    NotificationManager().onPanicAlertReceived = (data) {
      if (!mounted) return;
      setState(() => _panicCount++);
      _checkActiveAlerts();
    };
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await Future.wait([_loadPanicCount(), _checkActiveAlerts()]);
    if (mounted) {
      try {
        context.read<CitationBloc>().add(LoadMyCitationsEvent());
        context.read<ReportBloc>().add(const GetReportsByStatusEvent(status: 'pendiente'));
      } catch (e) {
        debugPrint('Error accessing CitationBloc: $e');
      }
    }
  }

  Future<void> _loadPanicCount() async {
    final panicRepository = di.sl<PanicRepository>();
    final results = await Future.wait([
      panicRepository.getTodayPanicCount(),
      panicRepository.getCancelledPanicCount(),
    ]);
    if (mounted) {
      results[0].fold((_) {}, (count) => setState(() => _panicCount = count));
      results[1].fold((_) {}, (count) => setState(() => _cancelledPanicCount = count));
    }
  }

  Future<void> _checkActiveAlerts() async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/active'),
      );
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> alerts = json.decode(response.body);
        setState(() {
          _activeAlert = alerts.isNotEmpty ? alerts.first as Map<String, dynamic> : null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _refreshTimer?.cancel();
    NotificationManager().onPanicAlertReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<ReportBloc>()
            ..add(const GetReportsByStatusEvent(status: 'pendiente')),
        ),
        BlocProvider(create: (_) => di.sl<VehicleBloc>()),
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
      ],
      child: Container(
        color: AppTheme.surface,
        child: SafeArea(
          top: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                // Contenido principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SOS activo banner
                        if (_activeAlert != null) ...[
                          const SizedBox(height: 16),
                          _buildActiveSOSBanner(),
                        ],

                        // Bitacora activa banner
                        ActiveTripBanner(onTap: _navigateToActiveTrip),

                        const SizedBox(height: 24),

                        // Stats rapidas
                        _buildQuickStats(),

                        const SizedBox(height: 12),

                        // Stats de denuncias
                        _buildReportStats(),

                        const SizedBox(height: 24),

                        // CTA Principal - Nueva Citacion
                        _buildMainCTA(),

                        const SizedBox(height: 12),

                        // CTA Secundario - Nueva Denuncia
                        _buildDenunciaCTA(),

                        const SizedBox(height: 24),

                        // Acciones secundarias
                        _buildSecondaryActions(),

        const SizedBox(height: 24),

                        // Actividad reciente (citaciones + denuncias)
                        _buildRecentActivity(),

        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSOSBanner() {
    final userName = [_activeAlert?['first_name'], _activeAlert?['last_name']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    final status = _activeAlert?['status']?.toString() ?? 'active';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PanicAlertDetailScreen(
              alertId: _activeAlert?['id']?.toString(),
              latitude: (_activeAlert?['latitude'] as num?)?.toDouble(),
              longitude: (_activeAlert?['longitude'] as num?)?.toDouble(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: status == 'responding'
                ? [AppTheme.success, AppTheme.success.withValues(alpha: 0.85)]
                : [AppTheme.emergency, AppTheme.emergency.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (status == 'responding' ? AppTheme.success : AppTheme.emergency).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                status == 'responding' ? Icons.directions_run_rounded : Icons.sos,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == 'responding' ? 'SOS - EN CAMINO' : 'SOS ACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName.isNotEmpty ? userName : 'Ciudadano necesita ayuda',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStats() {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        final pendingCount = state is ReportsLoaded ? state.reports.length : 0;
        final isLoading = state is ReportLoading;

        return GestureDetector(
          onTap: _navigateToReports,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: pendingCount > 0
                    ? AppTheme.warning.withValues(alpha: 0.4)
                    : AppTheme.primary.withValues(alpha: 0.15),
              ),
              boxShadow: AppTheme.shadowSmall,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (pendingCount > 0 ? AppTheme.warning : AppTheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.report_problem_outlined,
                    color: pendingCount > 0 ? AppTheme.warning : AppTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Denuncias ciudadanas pendientes',
                        style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 40,
                              child: LinearProgressIndicator(),
                            )
                          : Text(
                              pendingCount == 0
                                  ? 'Sin denuncias pendientes'
                                  : '$pendingCount denuncia${pendingCount == 1 ? '' : 's'} sin atender',
                              style: AppTheme.titleSmall.copyWith(
                                color: pendingCount > 0
                                    ? AppTheme.warning
                                    : AppTheme.textPrimary,
                                fontWeight: pendingCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<CitationBloc, CitationState>(
      builder: (context, state) {
        int todayCitations = 0;
        int totalCitations = 0;

        if (state is CitationsLoaded) {
          final today = DateTime.now();
          todayCitations = state.citations
              .where((c) =>
                  c.createdAt.year == today.year &&
                  c.createdAt.month == today.month &&
                  c.createdAt.day == today.day)
              .length;
          totalCitations = state.citations.length;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  value: todayCitations.toString(),
                  label: 'Hoy',
                  icon: Icons.today_rounded,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  value: totalCitations.toString(),
                  label: 'Total',
                  icon: Icons.assignment_rounded,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  value: _panicCount.toString(),
                  label: 'Alertas',
                  icon: Icons.warning_amber_rounded,
                  isHighlighted: _panicCount > 0,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  value: _cancelledPanicCount.toString(),
                  label: 'Canceladas',
                  icon: Icons.cancel_outlined,
                  isHighlighted: false,
                  highlightColor: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn({
    required String value,
    required String label,
    required IconData icon,
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    final color = isHighlighted ? AppTheme.warning : (highlightColor ?? AppTheme.primary);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppTheme.border,
    );
  }

  Widget _buildMainCTA() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateToCreateCitation();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.neonCardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(
                Icons.add_circle_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Citacion',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crear citacion o advertencia',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.primary.withValues(alpha: 0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenunciaCTA() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _navigateToCreateReport();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(
                Icons.add_circle_rounded,
                color: AppTheme.warning,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Denuncia',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reportar problema urbano',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppTheme.warning.withValues(alpha: 0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSecondaryCard(
                icon: Icons.map_rounded,
                title: 'Mapa',
                subtitle: 'Ver alertas',
                color: AppTheme.success,
                onTap: _navigateToMap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryCard(
                icon: Icons.search_rounded,
                title: 'Consultas',
                subtitle: 'Buscar historial',
                color: AppTheme.info,
                onTap: _navigateToSearch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSecondaryCard(
                icon: Icons.report_problem_outlined,
                title: 'Denuncias',
                subtitle: 'Ciudadanas',
                color: AppTheme.warning,
                onTap: _navigateToReports,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryCard(
                icon: Icons.directions_car_rounded,
                title: 'Bitacora',
                subtitle: 'Vehiculos',
                color: Colors.teal,
                onTap: _navigateToVehicles,
                onLongPress: _navigateToVehicleLogs,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: AppTheme.shadowSmall,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title, style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad reciente',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<CitationBloc, CitationState>(
          builder: (context, citationState) {
            return BlocBuilder<ReportBloc, ReportState>(
              builder: (context, reportState) {
                final items = <_ActivityItem>[];

                // Collect citations
                if (citationState is CitationsLoaded) {
                  for (final c in citationState.citations) {
                    items.add(_ActivityItem.fromCitation(c));
                  }
                }

                // Collect denuncias (reports)
                if (reportState is ReportsLoaded) {
                  for (final r in reportState.reports) {
                    items.add(_ActivityItem.fromReport(r));
                  }
                }

                // Loading state
                final isLoading = citationState is CitationLoading ||
                    reportState is ReportLoading;
                if (isLoading && items.isEmpty) {
                  return _buildLoadingState();
                }

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                // Sort by date desc, take 5
                items.sort((a, b) => b.date.compareTo(a.date));
                final recent = items.take(5).toList();

                return Column(
                  children: recent.map((item) => _buildActivityCard(item)).toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(_ActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: item.color.withValues(alpha: 0.20)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => item.onTap(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTheme.titleSmall.copyWith(color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              item.typeLabel,
                              style: AppTheme.labelSmall.copyWith(color: item.color, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            _formatRelativeDate(item.date),
                            style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: AppTheme.primary.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment_outlined, size: 40, color: AppTheme.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text('Sin citaciones recientes', style: AppTheme.titleSmall.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Las citaciones que crees apareceran aqui', style: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreateCitation,
            icon: const Icon(Icons.add),
            label: const Text('Crear Citacion'),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Navigation
  void _navigateToCreateCitation() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCitationScreen(inspectorId: widget.user.id),
      ),
    );

    if (result == true && mounted) {
      context.read<CitationBloc>().add(RefreshCitationsEvent());
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectorMapScreen(),
      ),
    );
  }

  void _navigateToReports() {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(1); // Denuncias tab
    }
  }

  void _navigateToCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInspectorReportScreen(inspectorId: widget.user.id),
      ),
    ).then((_) {
      if (mounted) {
        context.read<ReportBloc>().add(const GetReportsByStatusEvent(status: 'pendiente'));
      }
    });
  }

  void _navigateToVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<VehicleBloc>(),
          child: VehicleSelectionPage(
            userId: widget.user.id,
            userName: widget.user.displayName,
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToActiveTrip() async {
    // Navigate to vehicles page; user can see the banner and continue their trip
    _navigateToVehicles();
  }

  void _navigateToVehicleLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VehicleLogsScreen()),
    );
  }
}

/// Unified activity item for the recent-activity feed.
class _ActivityItem {
  final String title;
  final String subtitle;
  final String typeLabel;
  final IconData icon;
  final Color color;
  final DateTime date;
  final void Function(BuildContext) onTap;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.typeLabel,
    required this.icon,
    required this.color,
    required this.date,
    required this.onTap,
  });

  factory _ActivityItem.fromCitation(CitationEntity c) {
    final isAdvertencia = c.citationType == CitationType.advertencia;
    return _ActivityItem(
      title: c.citationNumber,
      subtitle: c.targetDisplayName,
      typeLabel: isAdvertencia ? 'Advertencia' : 'Citacion',
      icon: isAdvertencia ? Icons.warning_amber_rounded : Icons.assignment_rounded,
      color: isAdvertencia ? AppTheme.warning : AppTheme.primary,
      date: c.createdAt,
      onTap: (ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => CitationDetailScreen(citation: c)),
      ),
    );
  }

  factory _ActivityItem.fromReport(ReportEntity r) {
    return _ActivityItem(
      title: r.title,
      subtitle: r.category,
      typeLabel: 'Denuncia',
      icon: Icons.report_problem_rounded,
      color: AppTheme.info,
      date: r.createdAt,
      onTap: (ctx) => Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => EnhancedReportDetailScreen(
            reportId: r.id,
            currentUserRole: 'inspector',
          ),
        ),
      ),
    );
  }
}
