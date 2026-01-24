// lib/features/inspector/presentation/pages/inspector_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../vehicles/presentation/bloc/vehicle_bloc.dart';
import '../../../vehicles/presentation/pages/vehicle_selection_page.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import 'citations_list_screen.dart';
import 'create_citation_screen.dart';
import 'inspector_reports_screen.dart';
import 'inspector_map_screen.dart';

class InspectorHomeScreen extends StatefulWidget {
  final UserEntity user;

  const InspectorHomeScreen({super.key, required this.user});

  @override
  State<InspectorHomeScreen> createState() => _InspectorHomeScreenState();
}

class _InspectorHomeScreenState extends State<InspectorHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Design System Colors
  static const Color _primaryDark = Color(0xFF0D3B1E);
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _accentGreen = Color(0xFF4CAF50);
  static const Color _surfaceLight = Color(0xFFF8FAF8);
  static const Color _cardWhite = Colors.white;

  // Status Colors
  static const Color _urgentRed = Color(0xFFE53935);
  static const Color _warningOrange = Color(0xFFFB8C00);
  static const Color _successGreen = Color(0xFF43A047);
  static const Color _infoBlue = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent())),
        BlocProvider(create: (_) => di.sl<VehicleBloc>()),
      ],
      child: Container(
        color: _surfaceLight,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Stats Section
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildHeroStats(context),
                ),
              ),

              // Quick Actions - Primary
              SliverToBoxAdapter(
                child: _buildPrimaryActions(context),
              ),

              // Pending Items Alert
              SliverToBoxAdapter(
                child: _buildPendingAlerts(context),
              ),

              // Secondary Actions Grid
              SliverToBoxAdapter(
                child: _buildSecondaryActions(context),
              ),

              // Recent Activity Feed
              SliverToBoxAdapter(
                child: _buildActivityFeed(context),
              ),

              // Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStats(BuildContext context) {
    return BlocBuilder<CitationBloc, CitationState>(
      builder: (context, state) {
        int todayCitations = 0;
        int pendingCitations = 0;
        int totalCitations = 0;
        int weekCitations = 0;

        if (state is CitationsLoaded) {
          totalCitations = state.citations.length;
          pendingCitations = state.statusCounts[CitationStatus.pendiente] ?? 0;
          final today = DateTime.now();
          final weekAgo = today.subtract(const Duration(days: 7));

          todayCitations = state.citations
              .where((c) =>
                  c.createdAt.year == today.year &&
                  c.createdAt.month == today.month &&
                  c.createdAt.day == today.day)
              .length;

          weekCitations = state.citations
              .where((c) => c.createdAt.isAfter(weekAgo))
              .length;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryDark, _primaryGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Stats Grid
                      Row(
                        children: [
                          _buildStatCard(
                            value: todayCitations.toString(),
                            label: 'Hoy',
                            icon: Icons.today_rounded,
                            isHighlighted: todayCitations > 0,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            value: pendingCitations.toString(),
                            label: 'Pendientes',
                            icon: Icons.pending_actions_rounded,
                            isHighlighted: pendingCitations > 0,
                            highlightColor: _warningOrange,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            value: weekCitations.toString(),
                            label: 'Semana',
                            icon: Icons.date_range_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            value: totalCitations.toString(),
                            label: 'Total',
                            icon: Icons.assignment_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    bool isHighlighted = false,
    Color? highlightColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (highlightColor ?? Colors.white).withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? (highlightColor ?? Colors.white).withOpacity(0.4)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isHighlighted
                  ? (highlightColor ?? Colors.white)
                  : Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Nueva Citación - Primary CTA
          Expanded(
            flex: 2,
            child: _buildPrimaryCTA(
              context,
              icon: Icons.add_circle_rounded,
              title: 'Nueva Citación',
              subtitle: 'Crear citación o advertencia',
              gradient: const [_infoBlue, Color(0xFF1565C0)],
              onTap: () => _navigateToCreateCitation(context),
            ),
          ),
          const SizedBox(width: 12),
          // Ver Mapa - Secondary CTA
          Expanded(
            child: _buildSecondaryCTA(
              context,
              icon: Icons.map_rounded,
              title: 'Mapa',
              color: _accentGreen,
              onTap: () => _navigateToMap(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCTA(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCTA(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAlerts(BuildContext context) {
    return BlocBuilder<CitationBloc, CitationState>(
      builder: (context, state) {
        if (state is CitationsLoaded) {
          final pendingCount =
              state.statusCounts[CitationStatus.pendiente] ?? 0;
          if (pendingCount == 0) return const SizedBox.shrink();

          return AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: pendingCount > 5 ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => _navigateToCitationsList(context),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _warningOrange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: _warningOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$pendingCount citaciones pendientes',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Requieren seguimiento',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _warningOrange.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Herramientas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.list_alt_rounded,
                  title: 'Mis Citaciones',
                  subtitle: 'Ver historial',
                  color: Colors.deepPurple,
                  onTap: () => _navigateToCitationsList(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.report_problem_rounded,
                  title: 'Denuncias',
                  subtitle: 'Ciudadanas',
                  color: _urgentRed,
                  onTap: () => _navigateToReports(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.route_rounded,
                  title: 'Bitácora',
                  subtitle: 'Vehículos',
                  color: Colors.teal,
                  onTap: () => _navigateToVehicleSelection(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolCard(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Escanear',
                  subtitle: 'QR / Patente',
                  color: Colors.indigo,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Función próximamente disponible'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryDark,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToCitationsList(context),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BlocBuilder<CitationBloc, CitationState>(
            builder: (context, state) {
              if (state is CitationLoading) {
                return _buildLoadingActivity();
              }

              if (state is CitationsLoaded) {
                if (state.citations.isEmpty) {
                  return _buildEmptyActivity(context);
                }

                final recentCitations = state.citations.take(3).toList();
                return Column(
                  children: recentCitations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final citation = entry.value;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildActivityItem(context, citation),
                    );
                  }).toList(),
                );
              }

              if (state is CitationError) {
                return _buildErrorActivity(context, state.message);
              }

              return _buildEmptyActivity(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingActivity() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _primaryGreen,
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: _primaryGreen.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin actividad reciente',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las citaciones que crees aparecerán aquí',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateCitation(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear Citación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, CitationEntity citation) {
    final statusColor = _getStatusColor(citation.status);
    final typeIcon = _getCitationTypeIcon(citation.citationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CitationsListScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status indicator line
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                // Content
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _primaryDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              citation.status.displayName,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        citation.targetDisplayName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRelativeDate(citation.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorActivity(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _urgentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _urgentRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: _urgentRed.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Error al cargar',
            style: TextStyle(
              color: _urgentRed.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              context.read<CitationBloc>().add(LoadMyCitationsEvent());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
            style: TextButton.styleFrom(
              foregroundColor: _urgentRed,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return _warningOrange;
      case CitationStatus.notificado:
        return _infoBlue;
      case CitationStatus.asistio:
        return _successGreen;
      case CitationStatus.noAsistio:
        return _urgentRed;
      case CitationStatus.cancelado:
        return Colors.grey;
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

  // Navigation Methods
  void _navigateToCreateCitation(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCitationScreen(inspectorId: widget.user.id),
      ),
    );

    if (result == true && context.mounted) {
      context.read<CitationBloc>().add(RefreshCitationsEvent());
    }
  }

  void _navigateToCitationsList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CitationsListScreen(),
      ),
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectorReportsScreen(),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InspectorMapScreen(),
      ),
    );
  }

  void _navigateToVehicleSelection(BuildContext context) {
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
