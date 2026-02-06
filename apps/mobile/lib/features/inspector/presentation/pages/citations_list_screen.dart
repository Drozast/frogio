// lib/features/inspector/presentation/pages/citations_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import '../utils/citation_ui_extensions.dart';
import 'create_citation_screen.dart';

class CitationsListScreen extends StatefulWidget {
  const CitationsListScreen({super.key});

  @override
  State<CitationsListScreen> createState() => _CitationsListScreenState();
}

class _CitationsListScreenState extends State<CitationsListScreen>
    with WidgetsBindingObserver {
  Timer? _autoRefreshTimer;
  CitationBloc? _citationBloc;
  CitationStatus? _selectedStatFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_citationBloc != null && mounted) {
        _citationBloc!.add(RefreshCitationsEvent());
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _stopAutoRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    _citationBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _citationBloc ??= di.sl<CitationBloc>()..add(LoadMyCitationsEvent());

    // Start auto-refresh if not already running
    if (_autoRefreshTimer == null) {
      _startAutoRefresh();
    }

    return BlocProvider.value(
      value: _citationBloc!,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Mis Citaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<CitationBloc, CitationState>(
              builder: (context, state) {
                final bool filtersActive = state is CitationsLoaded &&
                    (state.currentStatusFilter != null || state.currentTypeFilter != null);
                return Badge(
                  isLabelVisible: filtersActive,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                    onPressed: () => _showFilterBottomSheet(context),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () {
                context.read<CitationBloc>().add(RefreshCitationsEvent());
              },
            ),
          ],
        ),
        body: BlocConsumer<CitationBloc, CitationState>(
          listener: (context, state) {
            if (state is CitationUpdated) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.success,
                  ),
                );
            } else if (state is CitationError) {
               ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.emergency,
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is CitationLoading && state.message != null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CitationError && state.canRetry) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is CitationsLoaded) {
              if (state.citations.isEmpty) {
                return _buildEmptyState(context, isFiltered: false);
              }
              if (state.filteredCitations.isEmpty) {
                return _buildEmptyState(context, isFiltered: true);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CitationBloc>().add(RefreshCitationsEvent());
                },
                child: Column(
                  children: [
                    _buildStatsHeader(context, state),
                    if (_selectedStatFilter != null)
                      _buildActiveFilterBar(context),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing16,
                          vertical: AppTheme.spacing8,
                        ),
                        itemCount: state.filteredCitations.length,
                        itemBuilder: (context, index) {
                          final citation = state.filteredCitations[index];
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(citation.id),
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(30 * (1 - value), 0),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: _CitationListItem(
                              citation: citation,
                              onTap: () => _showCitationDetail(context, citation),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final authState = context.read<AuthBloc>().state;
            final inspectorId = authState is Authenticated ? authState.user.id : '';

            return FloatingActionButton.extended(
              onPressed: () async {
                if (inspectorId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No se pudo obtener el inspector')),
                  );
                  return;
                }

                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCitationScreen(inspectorId: inspectorId),
                  ),
                );

                if (result == true && context.mounted) {
                  context.read<CitationBloc>().add(RefreshCitationsEvent());
                }
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Nueva Citación',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onStatCardTap(BuildContext context, CitationStatus? status) {
    setState(() {
      if (_selectedStatFilter == status) {
        _selectedStatFilter = null;
      } else {
        _selectedStatFilter = status;
      }
    });
    context.read<CitationBloc>().add(FilterCitationsEvent(status: _selectedStatFilter));
  }

  Widget _buildStatsHeader(BuildContext context, CitationsLoaded state) {
    final asistio = state.statusCounts[CitationStatus.asistio] ?? 0;
    final noAsistio = state.statusCounts[CitationStatus.noAsistio] ?? 0;
    final notificado = state.statusCounts[CitationStatus.notificado] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildStatCard(
            count: state.citations.length.toString(),
            label: 'Total',
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.assignment_outlined,
            isSelected: _selectedStatFilter == null,
            onTap: () {
              if (_selectedStatFilter != null) {
                setState(() => _selectedStatFilter = null);
                context.read<CitationBloc>().add(const FilterCitationsEvent());
              }
            },
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            count: notificado.toString(),
            label: 'Notificados',
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.notifications_active_outlined,
            isSelected: _selectedStatFilter == CitationStatus.notificado,
            onTap: () => _onStatCardTap(context, CitationStatus.notificado),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            count: asistio.toString(),
            label: 'Asistio',
            gradient: const LinearGradient(
              colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.check_circle_outline,
            isSelected: _selectedStatFilter == CitationStatus.asistio,
            onTap: () => _onStatCardTap(context, CitationStatus.asistio),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            count: noAsistio.toString(),
            label: 'No Asistio',
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.cancel_outlined,
            isSelected: _selectedStatFilter == CitationStatus.noAsistio,
            onTap: () => _onStatCardTap(context, CitationStatus.noAsistio),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Gradient gradient,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 105,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: isSelected ? 16 : 6,
                offset: Offset(0, isSelected ? 6 : 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isSelected ? 8 : 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isSelected ? 0.35 : 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isSelected ? 22 : 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBar(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primarySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Mostrando: ${_selectedStatFilter!.displayName}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() => _selectedStatFilter = null);
                context.read<CitationBloc>().add(const FilterCitationsEvent());
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isFiltered}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off_outlined : Icons.assignment_outlined,
            size: 80,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            isFiltered ? 'Sin Resultados' : 'No hay citaciones',
            style: AppTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isFiltered
                ? 'Prueba con otros filtros o límpialos.'
                : 'Las citaciones que crees aparecerán aquí.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton(
              onPressed: () {
                context.read<CitationBloc>().add(const FilterCitationsEvent());
              },
              child: const Text('Limpiar Filtros'),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.emergency,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Error al cargar citaciones',
              style: AppTheme.titleLarge.copyWith(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CitationBloc>().add(LoadMyCitationsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitationDetail(BuildContext context, CitationEntity citation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => BlocProvider.value(
        value: BlocProvider.of<CitationBloc>(context),
        child: _CitationDetailSheet(citation: citation),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final citationBloc = context.read<CitationBloc>();
    // Ensure we only show the filter sheet when the state is CitationsLoaded
    if (citationBloc.state is CitationsLoaded) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (modalContext) => BlocProvider.value(
          value: citationBloc,
          child: const _FilterSheet(),
        ),
      );
    }
  }
}

// -----------------------------------------------------------------------------
// WIDGET: _CitationListItem
// -----------------------------------------------------------------------------

class _CitationListItem extends StatelessWidget {
  final CitationEntity citation;
  final VoidCallback onTap;

  const _CitationListItem({required this.citation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono, título y badge de estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadingIcon(context),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  citation.citationNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              _buildStatusBadge(context),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            citation.citationType.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Línea divisoria sutil
                Container(
                  height: 1,
                  color: Colors.grey.shade100,
                ),

                const SizedBox(height: 14),

                // Información del citado
                _buildInfoRow(
                  icon: Icons.person_outline_rounded,
                  text: citation.targetDisplayName,
                  isMain: true,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.description_outlined,
                  text: citation.reason,
                  maxLines: 2,
                ),
                if (citation.locationAddress != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.location_on_outlined,
                    text: citation.locationAddress!,
                  ),
                ],

                const SizedBox(height: 14),

                // Footer con fecha y flecha
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy').format(citation.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: citation.status.backgroundColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        citation.citationType.icon,
        color: citation.status.color(context),
        size: 26,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: citation.status.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        citation.status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: citation.status.color(context),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    int maxLines = 1,
    bool isMain = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isMain ? AppTheme.primary : Colors.grey.shade500,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isMain ? FontWeight.w600 : FontWeight.w400,
              color: isMain ? const Color(0xFF333333) : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: _CitationDetailSheet
// -----------------------------------------------------------------------------

class _CitationDetailSheet extends StatelessWidget {
  final CitationEntity citation;
  const _CitationDetailSheet({required this.citation});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: AppTheme.spacing12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildDetailSection(context, 'Tipo', citation.citationType.displayName),
                  _buildDetailSection(context, 'Objetivo', '${citation.targetType.displayName}: ${citation.targetDisplayName}'),
                  if (citation.targetRut != null)
                    _buildDetailSection(context, 'RUT', citation.targetRut!),
                  if (citation.targetPlate != null)
                    _buildDetailSection(context, 'Patente', citation.targetPlate!),
                  if (citation.targetPhone != null)
                    _buildDetailSection(context, 'Teléfono', citation.targetPhone!),
                  _buildDetailSection(context, 'Motivo', citation.reason),
                  if (citation.locationAddress != null)
                    _buildDetailSection(context, 'Ubicación', citation.locationAddress!),
                  if (citation.notes != null)
                    _buildDetailSection(context, 'Notas', citation.notes!),
                  _buildDetailSection(context, 'Fecha', DateFormat('dd/MM/yyyy HH:mm').format(citation.createdAt)),
                  if (citation.issuerName != null)
                    _buildDetailSection(context, 'Emitida por', citation.issuerName!),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildActionButtons(context),
                  const SizedBox(height: AppTheme.spacing32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing12),
          decoration: BoxDecoration(
            color: citation.status.backgroundColor(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Icon(
            citation.citationType.icon,
            color: citation.status.color(context),
            size: 32,
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(citation.citationNumber, style: AppTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacing4),
              _buildStatusBadge(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: citation.status.backgroundColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Text(
        citation.status.displayName,
        style: AppTheme.labelMedium.copyWith(
          color: citation.status.color(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.labelMedium),
          const SizedBox(height: AppTheme.spacing4),
          Text(value, style: AppTheme.bodyLarge.copyWith(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (citation.status == CitationStatus.pendiente) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showUpdateStatusDialog(context, citation);
          },
          icon: const Icon(Icons.update_rounded),
          label: const Text('Actualizar Estado'),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: citation.status.backgroundColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              citation.status.icon,
              color: citation.status.color(context),
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              'Estado: ${citation.status.displayName}',
              style: AppTheme.titleSmall.copyWith(
                color: citation.status.color(context),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showUpdateStatusDialog(BuildContext context, CitationEntity citation) {
    final citationBloc = context.read<CitationBloc>();
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => BlocProvider.value(
        value: citationBloc,
        child: _UpdateStatusSheet(citation: citation),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: _FilterSheet (Stateful & Improved UX)
// -----------------------------------------------------------------------------

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  CitationStatus? _selectedStatus;
  CitationType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _datePreset;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<CitationBloc>().state;
    if (currentState is CitationsLoaded) {
      _selectedStatus = currentState.currentStatusFilter;
      _selectedType = currentState.currentTypeFilter;
      _startDate = currentState.startDateFilter;
      _endDate = currentState.endDateFilter;
    }
  }

  void _applyDatePreset(String label, DateTime start, DateTime end) {
    setState(() {
      if (_datePreset == label) {
        _datePreset = null;
        _startDate = null;
        _endDate = null;
      } else {
        _datePreset = label;
        _startDate = start;
        _endDate = end;
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
      locale: const Locale('es', 'CL'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _datePreset = null;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Filtrar Citaciones', style: AppTheme.headlineSmall),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),

            // Filtro por rango de fechas
            const Text('Por Fecha', style: AppTheme.titleSmall),
            const SizedBox(height: AppTheme.spacing12),

            // Quick date presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDatePresetChip(
                  'Hoy',
                  DateTime(now.year, now.month, now.day),
                  now,
                ),
                _buildDatePresetChip(
                  '7 dias',
                  now.subtract(const Duration(days: 7)),
                  now,
                ),
                _buildDatePresetChip(
                  '30 dias',
                  now.subtract(const Duration(days: 30)),
                  now,
                ),
                _buildDatePresetChip(
                  'Este mes',
                  DateTime(now.year, now.month, 1),
                  now,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing12),

            // Custom date range button
            InkWell(
              onTap: () => _selectDateRange(context),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: (_startDate != null && _datePreset == null) ? AppTheme.primary : AppTheme.border,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  color: (_startDate != null && _datePreset == null) ? AppTheme.primarySurface : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      color: _startDate != null ? AppTheme.primary : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                            : 'Rango personalizado...',
                        style: TextStyle(
                          color: _startDate != null ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: _startDate != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                            _datePreset = null;
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),
            _buildFilterSection<CitationStatus>(
              title: 'Por Estado',
              items: CitationStatus.values,
              selectedItem: _selectedStatus,
              onSelected: (status) {
                setState(() {
                  _selectedStatus = (_selectedStatus == status) ? null : status;
                });
              },
              itemLabel: (status) => status.displayName,
            ),
            const SizedBox(height: AppTheme.spacing24),
            _buildFilterSection<CitationType>(
              title: 'Por Tipo',
              items: CitationType.values,
              selectedItem: _selectedType,
              onSelected: (type) {
                setState(() {
                  _selectedType = (_selectedType == type) ? null : type;
                });
              },
              itemLabel: (type) => type.displayName,
            ),
            const SizedBox(height: AppTheme.spacing32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePresetChip(String label, DateTime start, DateTime end) {
    final isSelected = _datePreset == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyDatePreset(label, start, end),
      selectedColor: AppTheme.primarySurface,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFilterSection<T>({
    required String title,
    required List<T> items,
    required T? selectedItem,
    required ValueChanged<T> onSelected,
    required String Function(T) itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.titleSmall),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: items.map((item) {
            final isSelected = item == selectedItem;
            return ChoiceChip(
              label: Text(itemLabel(item)),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: AppTheme.primarySurface,
              labelStyle: isSelected
                  ? AppTheme.labelLarge.copyWith(color: AppTheme.primary)
                  : AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
              side: isSelected ? const BorderSide(color: AppTheme.primary) : const BorderSide(color: AppTheme.border),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedType = null;
                _startDate = null;
                _endDate = null;
                _datePreset = null;
              });
              context.read<CitationBloc>().add(const FilterCitationsEvent());
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<CitationBloc>().add(
                    FilterCitationsEvent(
                      status: _selectedStatus,
                      citationType: _selectedType,
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET: _UpdateStatusSheet (Stateful with Notes)
// -----------------------------------------------------------------------------

class _UpdateStatusSheet extends StatefulWidget {
  final CitationEntity citation;
  const _UpdateStatusSheet({required this.citation});

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final _notesController = TextEditingController();
  CitationStatus? _selectedStatus;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitUpdate() {
    if (_selectedStatus == null) return;

    final newNote = _notesController.text.trim();
    String? updatedNotes = widget.citation.notes;

    if (newNote.isNotEmpty) {
      final noteWithTimestamp = '[${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}] $newNote';
      if (updatedNotes != null && updatedNotes.isNotEmpty) {
        updatedNotes = '$updatedNotes\n\n$noteWithTimestamp';
      } else {
        updatedNotes = noteWithTimestamp;
      }
    }

    context.read<CitationBloc>().add(
          UpdateCitationStatusEvent(
            citationId: widget.citation.id,
            status: _selectedStatus!,
            notes: updatedNotes,
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Adjust padding to account for keyboard
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Actualizar Estado', style: AppTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Citación: ${widget.citation.citationNumber}',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing24),
            
            const Text('Seleccionar nuevo estado:', style: AppTheme.titleSmall),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: [
                CitationStatus.notificado,
                CitationStatus.asistio,
                CitationStatus.noAsistio,
                CitationStatus.cancelado,
              ].map((status) {
                final isSelected = _selectedStatus == status;
                return ChoiceChip(
                  label: Text(status.displayName),
                  avatar: Icon(status.icon, size: 16, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedStatus = status),
                  selectedColor: AppTheme.primarySurface,
                  labelStyle: isSelected
                      ? AppTheme.labelLarge.copyWith(color: AppTheme.primary)
                      : AppTheme.labelLarge.copyWith(color: AppTheme.textSecondary),
                  side: isSelected ? const BorderSide(color: AppTheme.primary) : const BorderSide(color: AppTheme.border),
                );
              }).toList(),
            ),

            const SizedBox(height: AppTheme.spacing24),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Añadir Observación (Opcional)',
                hintText: 'Ej: Se notifica en persona, pero no firma...',              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedStatus == null ? null : _submitUpdate,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Guardar Estado'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
