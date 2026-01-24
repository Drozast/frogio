// lib/features/inspector/presentation/pages/inspector_home_screen_v2.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../panic/domain/repositories/panic_repository.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../../vehicles/presentation/pages/vehicle_selection_page.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import 'citations_list_screen.dart';
import 'create_citation_screen.dart';
import 'inspector_reports_screen.dart';
import 'inspector_map_screen.dart';

/// Pantalla principal del Inspector - Diseno Moderno Minimalista
///
/// Enfoque principal: Gestion de Citaciones
/// - CTA prominente para crear citaciones
/// - Lista de citaciones recientes
/// - Accesos secundarios a mapa y denuncias
class InspectorHomeScreenV2 extends StatefulWidget {
  final UserEntity user;

  const InspectorHomeScreenV2({super.key, required this.user});

  @override
  State<InspectorHomeScreenV2> createState() => _InspectorHomeScreenV2State();
}

class _InspectorHomeScreenV2State extends State<InspectorHomeScreenV2>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _panicCount = 0;

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
  }

  Future<void> _loadPanicCount() async {
    final panicRepository = di.sl<PanicRepository>();
    final result = await panicRepository.getTodayPanicCount();
    result.fold(
      (failure) => {},
      (count) {
        if (mounted) {
          setState(() {
            _panicCount = count;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent()),
        ),
        BlocProvider(create: (_) => di.sl<VehicleBloc>()),
      ],
      child: Container(
        color: AppTheme.surface,
        child: SafeArea(
          top: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Contenido principal
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Saludo y estado
                        _buildHeader(),

                        const SizedBox(height: 24),

                        // Stats rapidas
                        _buildQuickStats(),

                        const SizedBox(height: 24),

                        // CTA Principal - Nueva Citacion
                        _buildMainCTA(),

                        const SizedBox(height: 24),

                        // Acciones secundarias
                        _buildSecondaryActions(),

        const SizedBox(height: 24),

                        // Citaciones recientes
                        _buildRecentCitations(),

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
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos dias';
    } else if (hour < 19) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.displayName,
                style: AppTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<CitationBloc, CitationState>(
      builder: (context, state) {
        int todayCitations = 0;
        int pendingCitations = 0;

        if (state is CitationsLoaded) {
          final today = DateTime.now();

          todayCitations = state.citations
              .where((c) =>
                  c.createdAt.year == today.year &&
                  c.createdAt.month == today.month &&
                  c.createdAt.day == today.day)
              .length;

          pendingCitations = state.statusCounts[CitationStatus.pendiente] ?? 0;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
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
                  value: pendingCitations.toString(),
                  label: 'Pendientes',
                  icon: Icons.pending_actions_rounded,
                  isHighlighted: pendingCitations > 0,
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
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isHighlighted
              ? AppTheme.warning
              : Colors.white.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headlineMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.white.withValues(alpha: 0.2),
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
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.info,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.info.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                Icons.add_circle_rounded,
                color: Colors.white,
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 4),
                  Text(
                    'Crear citacion o advertencia',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Row(
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
          ),
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
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardBorderedDecoration,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.titleSmall,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCitations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Citaciones recientes',
              style: AppTheme.titleMedium,
            ),
          TextButton(
            onPressed: _navigateToCitationsList,
            child: const Text('Ver todas'),
          ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<CitationBloc, CitationState>(
          builder: (context, state) {
            if (state is CitationLoading) {
              return _buildLoadingState();
            }

            if (state is CitationsLoaded) {
              if (state.citations.isEmpty) {
                return _buildEmptyState();
              }

              final recentCitations = state.citations.take(3).toList();
              return Column(
                children: recentCitations
                    .map((citation) => _buildCitationCard(citation))
                    .toList(),
              );
            }

            if (state is CitationError) {
              return _buildErrorState(context, state.message);
            }

            return _buildEmptyState();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.cardBorderedDecoration,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.cardBorderedDecoration,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin citaciones recientes',
            style: AppTheme.titleSmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Las citaciones que crees apareceran aqui',
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToCreateCitation,
            icon: Icon(Icons.add, size: 18),
            label: Text('Crear Citacion'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.emergencyLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppTheme.emergency.withValues(alpha: 0.6),
          ),
          SizedBox(height: 12),
          Text(
            'Error al cargar',
            style: AppTheme.titleSmall.copyWith(color: AppTheme.emergency),
          ),
          SizedBox(height: 4),
          Text(
            message,
            style: AppTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              context.read<CitationBloc>().add(LoadMyCitationsEvent());
            },
            icon: Icon(Icons.refresh_rounded, size: 18),
            label: Text('Reintentar'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.emergency),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationCard(CitationEntity citation) {
    final statusColor = _getStatusColor(citation.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardBorderedDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CitationsListScreen(),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador de estado
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 16),
                // Icono de tipo
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    _getCitationTypeIcon(citation.citationType),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              citation.citationNumber,
                              style: AppTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
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
                      SizedBox(height: 4),
                      Text(
                        citation.targetDisplayName,
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppTheme.textTertiary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatRelativeDate(citation.createdAt),
                            style: AppTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helpers
  Color _getStatusColor(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return AppTheme.warning;
      case CitationStatus.notificado:
        return AppTheme.info;
      case CitationStatus.asistio:
        return AppTheme.success;
      case CitationStatus.noAsistio:
        return AppTheme.emergency;
      case CitationStatus.cancelado:
        return AppTheme.textTertiary;
    }
  }

  IconData _getCitationTypeIcon(CitationType type) {
    switch (type) {
      case CitationType.advertencia:
        return Icons.warning_amber_rounded;
      case CitationType.citacion:
        return Icons.assignment_rounded;
    }
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

  void _navigateToCitationsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitationsListScreen(),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectorReportsScreen(),
      ),
    );
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
}
