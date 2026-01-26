// lib/features/admin/presentation/pages/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/statistics/statistics_bloc.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserEntity user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;

  // Design System Colors - Executive Dark Theme
  static const Color _primaryDark = Color(0xFF0D1B2A);
  static const Color _secondaryDark = Color(0xFF1B263B);
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _highlightBlue = Color(0xFF778DA9);
  static const Color _successGreen = Color(0xFF2ECC71);
  static const Color _warningOrange = Color(0xFFF39C12);
  static const Color _alertRed = Color(0xFFE74C3C);
  static const Color _infoBlue = Color(0xFF3498DB);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    // Load statistics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsBloc>().add(
            const LoadMunicipalStatisticsEvent(muniId: 'santa_juana'),
          );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildExecutiveHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildKeyMetricsSection(),
                    const SizedBox(height: 24),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),
                    _buildOperationalOverviewSection(),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Buenos Dias';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 19) {
      greeting = 'Buenas Tardes';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Buenas Noches';
      greetingIcon = Icons.nights_stay_rounded;
    }

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _primaryDark,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _secondaryDark,
                _primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentBlue.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _highlightBlue.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            greetingIcon,
                            color: _warningOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            greeting,
                            style: const TextStyle(
                              color: _highlightBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _successGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _successGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Administrador Municipal',
                              style: TextStyle(
                                color: _successGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showNotificationsSheet();
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: _highlightBlue),
              Positioned(
                right: 0,
                top: 0,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.8 + (_pulseController.value * 0.2),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _alertRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primaryDark, width: 1.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<StatisticsBloc>().add(
                  const RefreshStatisticsEvent(muniId: 'santa_juana'),
                );
          },
          icon: const Icon(Icons.refresh_rounded, color: _highlightBlue),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildKeyMetricsSection() {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return _buildLoadingMetrics();
        }

        // Default mock data for demo
        const totalReports = 156;
        const pendingReports = 23;
        const totalCitations = 89;
        const activeUsers = 1247;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Metricas Clave',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    // Navigate to full statistics
                  },
                  icon: const Icon(
                    Icons.analytics_outlined,
                    color: _infoBlue,
                    size: 18,
                  ),
                  label: const Text(
                    'Ver todo',
                    style: TextStyle(
                      color: _infoBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.assignment_outlined,
                    title: 'Denuncias',
                    value: totalReports.toString(),
                    subtitle: '+12 esta semana',
                    color: _infoBlue,
                    trend: 8.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.pending_actions_outlined,
                    title: 'Pendientes',
                    value: pendingReports.toString(),
                    subtitle: 'Por revisar',
                    color: _warningOrange,
                    trend: -3.2,
                    isNegativeTrendGood: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Citaciones',
                    value: totalCitations.toString(),
                    subtitle: 'Este mes',
                    color: _successGreen,
                    trend: 15.3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.people_outline,
                    title: 'Usuarios',
                    value: activeUsers.toString(),
                    subtitle: 'Activos',
                    color: _highlightBlue,
                    trend: 5.7,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metricas Clave',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildSkeletonCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_highlightBlue),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    double? trend,
    bool isNegativeTrendGood = false,
  }) {
    final isTrendPositive = trend != null && trend > 0;
    final showTrendAsGood = isNegativeTrendGood ? !isTrendPositive : isTrendPositive;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _secondaryDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (showTrendAsGood ? _successGreen : _alertRed)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTrendPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: showTrendAsGood ? _successGreen : _alertRed,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${trend.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: showTrendAsGood ? _successGreen : _alertRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: _highlightBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: _highlightBlue.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rapidas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildActionChip(
                icon: Icons.person_add_outlined,
                label: 'Nuevo Usuario',
                color: _infoBlue,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildActionChip(
                icon: Icons.directions_car_outlined,
                label: 'Gestionar Vehiculos',
                color: _successGreen,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildActionChip(
                icon: Icons.question_answer_outlined,
                label: 'Consultas Pendientes',
                color: _warningOrange,
                badge: '5',
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildActionChip(
                icon: Icons.file_download_outlined,
                label: 'Exportar Datos',
                color: _highlightBlue,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _secondaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _alertRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen Operacional',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _secondaryDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _accentBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildOverviewRow(
                icon: Icons.check_circle_outline,
                title: 'Denuncias Resueltas',
                value: '85%',
                color: _successGreen,
                progress: 0.85,
              ),
              const SizedBox(height: 20),
              _buildOverviewRow(
                icon: Icons.access_time,
                title: 'Tiempo Promedio Resolucion',
                value: '2.3 dias',
                color: _infoBlue,
                progress: 0.72,
              ),
              const SizedBox(height: 20),
              _buildOverviewRow(
                icon: Icons.sentiment_satisfied_alt,
                title: 'Satisfaccion Ciudadana',
                value: '4.2/5',
                color: _warningOrange,
                progress: 0.84,
              ),
              const SizedBox(height: 20),
              _buildOverviewRow(
                icon: Icons.local_police_outlined,
                title: 'Productividad Inspectores',
                value: '92%',
                color: _highlightBlue,
                progress: 0.92,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
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
                      title,
                      style: const TextStyle(
                        color: _highlightBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: _accentBlue.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    final activities = [
      _ActivityItem(
        icon: Icons.assignment_turned_in,
        title: 'Denuncia #1234 resuelta',
        subtitle: 'Por Inspector Martinez',
        time: 'Hace 5 min',
        color: _successGreen,
      ),
      _ActivityItem(
        icon: Icons.person_add,
        title: 'Nuevo usuario registrado',
        subtitle: 'Juan Perez - Ciudadano',
        time: 'Hace 15 min',
        color: _infoBlue,
      ),
      _ActivityItem(
        icon: Icons.receipt_long,
        title: 'Citacion emitida',
        subtitle: 'Infraccion de transito',
        time: 'Hace 32 min',
        color: _warningOrange,
      ),
      _ActivityItem(
        icon: Icons.warning_amber_rounded,
        title: 'Alerta de panico recibida',
        subtitle: 'Sector Centro - Atendida',
        time: 'Hace 1 hora',
        color: _alertRed,
      ),
      _ActivityItem(
        icon: Icons.directions_car,
        title: 'Vehiculo asignado',
        subtitle: 'Camioneta Municipal #05',
        time: 'Hace 2 horas',
        color: _highlightBlue,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Actividad Reciente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Ver historial',
                style: TextStyle(
                  color: _infoBlue,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _buildActivityItem(activity, isLast: index == activities.length - 1),
          );
        }),
      ],
    );
  }

  Widget _buildActivityItem(_ActivityItem activity, {required bool isLast}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: activity.color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activity.icon, color: activity.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    color: _highlightBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.time,
            style: TextStyle(
              color: _highlightBlue.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: _secondaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _accentBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Marcar leidas',
                      style: TextStyle(color: _infoBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNotificationItem(
                    icon: Icons.warning_amber_rounded,
                    title: 'Alerta urgente',
                    message: '3 denuncias sin revisar hace mas de 48 horas',
                    time: 'Hace 10 min',
                    isUrgent: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.person,
                    title: 'Nuevo inspector',
                    message: 'Pedro Gonzalez ha sido registrado como inspector',
                    time: 'Hace 2 horas',
                  ),
                  _buildNotificationItem(
                    icon: Icons.analytics,
                    title: 'Reporte semanal',
                    message: 'El reporte de estadisticas esta listo para revisar',
                    time: 'Hace 5 horas',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    bool isUrgent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? _alertRed.withValues(alpha: 0.3)
              : _accentBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isUrgent ? _alertRed : _infoBlue).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isUrgent ? _alertRed : _infoBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: isUrgent ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: _highlightBlue.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: _highlightBlue.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}
