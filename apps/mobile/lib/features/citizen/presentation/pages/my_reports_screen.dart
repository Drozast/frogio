// lib/features/citizen/presentation/pages/my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';
import '../widgets/report_list_item.dart';
import 'create_report_screen.dart';
import 'enhanced_report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final String userId;
  final UserEntity? user;

  const MyReportsScreen({
    super.key,
    required this.userId,
    this.user,
  });

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late ReportBloc _reportBloc;

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _reportBloc.add(LoadReportsEvent(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportBloc,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Mis Denuncias'),
          backgroundColor: AppTheme.surfaceWhite,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              color: AppTheme.primary,
              onPressed: () {
                _reportBloc.add(LoadReportsEvent(userId: widget.userId));
              },
            ),
          ],
        ),
        body: BlocConsumer<ReportBloc, ReportState>(
          listener: (context, state) {
            if (state is ReportError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.emergency,
                ),
              );
            }
          },
          builder: (context, state) {
            return _buildContent(state);
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateReport(),
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textOnPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildContent(ReportState state) {
    if (state is ReportLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    } else if (state is ReportsLoaded) {
      return _buildReportsList(state.reports);
    } else if (state is ReportError) {
      return _buildErrorState(state);
    }

    return Center(
      child: Text(
        'Presiona + para crear tu primera denuncia',
        style: AppTheme.bodyMedium,
      ),
    );
  }

  Widget _buildReportsList(List<ReportEntity> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.report_outlined,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tienes denuncias',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona + para crear tu primera denuncia',
              style: AppTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surfaceWhite,
      onRefresh: () async {
        _reportBloc.add(LoadReportsEvent(userId: widget.userId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: AppTheme.cardDecoration,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                onTap: () => _navigateToReportDetail(report.id),
                child: ReportListItem(
                  report: report,
                  onTap: () => _navigateToReportDetail(report.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(ReportError state) {
    return Center(
      child: Padding(
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
              child: const Icon(Icons.error_outline, size: 56, color: AppTheme.emergency),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error al cargar denuncias',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _reportBloc.add(LoadReportsEvent(userId: widget.userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateReport() async {
    if (widget.user != null && !widget.user!.isProfileComplete) {
      _showIncompleteProfileDialog();
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReportScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      _reportBloc.add(LoadReportsEvent(userId: widget.userId));
    }
  }

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_outline, color: AppTheme.warning),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Perfil incompleto'),
            ),
          ],
        ),
        content: const Text(
          'Para crear denuncias necesitas completar tu perfil con nombre, teléfono y dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _navigateToReportDetail(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedReportDetailScreen(
          reportId: reportId,
          currentUserRole: 'citizen',
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
