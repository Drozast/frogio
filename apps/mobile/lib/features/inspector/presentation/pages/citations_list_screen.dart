// lib/features/inspector/presentation/pages/citations_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import 'create_citation_screen.dart';

class CitationsListScreen extends StatelessWidget {
  const CitationsListScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Citaciones'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<CitationBloc, CitationState>(
          builder: (context, state) {
            if (state is CitationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CitationError) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is CitationsLoaded) {
              if (state.filteredCitations.isEmpty) {
                return _buildEmptyState(context);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CitationBloc>().add(RefreshCitationsEvent());
                },
                child: Column(
                  children: [
                    // Stats header
                    _buildStatsHeader(state),
                    // Lista de citaciones
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.filteredCitations.length,
                        itemBuilder: (context, index) {
                          final citation = state.filteredCitations[index];
                          return _buildCitationCard(context, citation);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Cargando...'));
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
              backgroundColor: _primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nueva', style: TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader(CitationsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _buildStatChip(
            'Total',
            state.citations.length.toString(),
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Pendientes',
            (state.statusCounts[CitationStatus.pendiente] ?? 0).toString(),
            Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatChip(
            'Notificados',
            (state.statusCounts[CitationStatus.notificado] ?? 0).toString(),
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard(BuildContext context, CitationEntity citation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCitationDetail(context, citation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(citation.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCitationTypeIcon(citation.citationType),
                      color: _getStatusColor(citation.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.citationNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          citation.citationType.displayName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(citation.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      citation.targetDisplayName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      citation.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (citation.locationAddress != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        citation.locationAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(citation.createdAt),
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
      ),
    );
  }

  Widget _buildStatusBadge(CitationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay citaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las citaciones que crees aparecerán aquí',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar citaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CitationBloc>().add(LoadMyCitationsEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(citation.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCitationTypeIcon(citation.citationType),
                      color: _getStatusColor(citation.status),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          citation.citationNumber,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(citation.status),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailSection('Tipo', citation.citationType.displayName),
              _buildDetailSection('Objetivo', '${citation.targetType.displayName}: ${citation.targetDisplayName}'),
              if (citation.targetRut != null)
                _buildDetailSection('RUT', citation.targetRut!),
              if (citation.targetPlate != null)
                _buildDetailSection('Patente', citation.targetPlate!),
              if (citation.targetPhone != null)
                _buildDetailSection('Teléfono', citation.targetPhone!),
              _buildDetailSection('Motivo', citation.reason),
              if (citation.locationAddress != null)
                _buildDetailSection('Ubicación', citation.locationAddress!),
              if (citation.notes != null)
                _buildDetailSection('Notas', citation.notes!),
              _buildDetailSection('Fecha', _formatDateTime(citation.createdAt)),
              if (citation.issuerName != null)
                _buildDetailSection('Emitida por', citation.issuerName!),
              const SizedBox(height: 24),
              // Botones de acción según estado
              if (citation.status == CitationStatus.pendiente) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showUpdateStatusDialog(context, citation);
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('Actualizar Estado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(citation.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getStatusColor(citation.status).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        citation.status == CitationStatus.asistio ? Icons.check_circle : Icons.info,
                        color: _getStatusColor(citation.status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estado: ${citation.status.displayName}',
                        style: TextStyle(
                          color: _getStatusColor(citation.status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar Citaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Por Estado:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CitationStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.displayName),
                  selected: false,
                  onSelected: (selected) {
                    context.read<CitationBloc>().add(
                          FilterCitationsEvent(status: selected ? status : null),
                        );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Por Tipo:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CitationType.values.map((type) {
                return FilterChip(
                  label: Text(type.displayName),
                  selected: false,
                  onSelected: (selected) {
                    context.read<CitationBloc>().add(
                          FilterCitationsEvent(citationType: selected ? type : null),
                        );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.read<CitationBloc>().add(const FilterCitationsEvent());
                  Navigator.pop(context);
                },
                child: const Text('Limpiar Filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return Colors.orange;
      case CitationStatus.notificado:
        return Colors.blue;
      case CitationStatus.asistio:
        return AppTheme.successColor;
      case CitationStatus.noAsistio:
        return Colors.red;
      case CitationStatus.cancelado:
        return Colors.grey;
    }
  }

  IconData _getCitationTypeIcon(CitationType type) {
    switch (type) {
      case CitationType.advertencia:
        return Icons.warning_amber;
      case CitationType.citacion:
        return Icons.assignment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showUpdateStatusDialog(BuildContext context, CitationEntity citation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actualizar Estado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Citación: ${citation.citationNumber}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ...[
              CitationStatus.notificado,
              CitationStatus.asistio,
              CitationStatus.noAsistio,
              CitationStatus.cancelado,
            ].map((status) {
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 24,
                  ),
                ),
                title: Text(status.displayName),
                subtitle: Text(_getStatusDescription(status)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<CitationBloc>().add(
                    UpdateCitationStatusEvent(
                      citationId: citation.id,
                      status: status,
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return Icons.schedule;
      case CitationStatus.notificado:
        return Icons.notifications_active;
      case CitationStatus.asistio:
        return Icons.check_circle;
      case CitationStatus.noAsistio:
        return Icons.cancel;
      case CitationStatus.cancelado:
        return Icons.block;
    }
  }

  String _getStatusDescription(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return 'Citación creada, pendiente de notificar';
      case CitationStatus.notificado:
        return 'El citado ha sido notificado';
      case CitationStatus.asistio:
        return 'El citado asistió a la cita';
      case CitationStatus.noAsistio:
        return 'El citado no asistió';
      case CitationStatus.cancelado:
        return 'Citación cancelada';
    }
  }
}
