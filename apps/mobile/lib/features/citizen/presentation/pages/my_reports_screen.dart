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
        appBar: AppBar(
          title: const Text('Mis Denuncias'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // ✅ CORREGIDO: Usar LoadReportsEvent en lugar de RefreshReportsEvent
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
                  backgroundColor: AppTheme.errorColor,
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
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent(ReportState state) {
    if (state is ReportLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ReportsLoaded) {
      return _buildReportsList(state.reports);
    } else if (state is ReportError) {
      return _buildErrorState(state);
    }
    
    return const Center(
      child: Text('Presiona + para crear tu primera denuncia'),
    );
  }

  Widget _buildReportsList(List<ReportEntity> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes denuncias',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Presiona + para crear tu primera denuncia',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // ✅ CORREGIDO: Usar LoadReportsEvent en lugar de RefreshReportsEvent
        _reportBloc.add(LoadReportsEvent(userId: widget.userId));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return ReportListItem(
            report: report,
            onTap: () => _navigateToReportDetail(report.id),
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
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Error al cargar denuncias',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _reportBloc.add(LoadReportsEvent(userId: widget.userId));
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateReport() async {
    // Verificar si el perfil está completo
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
      // ✅ CORREGIDO: Usar LoadReportsEvent para recargar después de crear
      _reportBloc.add(LoadReportsEvent(userId: widget.userId));
    }
  }

  void _showIncompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_outline, color: AppTheme.warningColor),
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
            onPressed: () {
              Navigator.pop(ctx);
              // El usuario debe ir a la pestaña de perfil desde el dashboard
            },
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