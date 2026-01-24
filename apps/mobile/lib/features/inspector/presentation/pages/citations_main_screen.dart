// lib/features/inspector/presentation/pages/citations_main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/models/citation_model.dart';
import '../../domain/entities/citation_entity.dart';
import '../bloc/citation_bloc.dart';
import 'create_citation_screen.dart';

class CitationsMainScreen extends StatefulWidget {
  final UserEntity user;

  const CitationsMainScreen({super.key, required this.user});

  @override
  State<CitationsMainScreen> createState() => _CitationsMainScreenState();
}

class _CitationsMainScreenState extends State<CitationsMainScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  CitationStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<CitationBloc>()..add(LoadMyCitationsEvent()),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Citaciones'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: BlocConsumer<CitationBloc, CitationState>(
          listener: (context, state) {
            if (state is CitationUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is CitationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Búsqueda simple
                _buildSearchBar(context),
                // Filtros de estado
                _buildStatusFilters(context, state),
                // Lista
                Expanded(child: _buildList(context, state)),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToCreate(context),
          backgroundColor: _primaryGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva Citación', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por número, nombre, RUT o patente...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters(context);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => _applyFilters(context),
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context, CitationState state) {
    final statusCounts = state is CitationsLoaded ? state.statusCounts : <CitationStatus, int>{};
    final total = state is CitationsLoaded ? state.citations.length : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(
              context,
              label: 'Todos ($total)',
              isSelected: _selectedStatus == null,
              color: Colors.grey,
              onTap: () {
                setState(() => _selectedStatus = null);
                _applyFilters(context);
              },
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              context,
              label: 'Pendientes (${statusCounts[CitationStatus.pendiente] ?? 0})',
              isSelected: _selectedStatus == CitationStatus.pendiente,
              color: Colors.orange,
              onTap: () {
                setState(() => _selectedStatus = CitationStatus.pendiente);
                _applyFilters(context);
              },
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              context,
              label: 'Asistió (${statusCounts[CitationStatus.asistio] ?? 0})',
              isSelected: _selectedStatus == CitationStatus.asistio,
              color: Colors.green,
              onTap: () {
                setState(() => _selectedStatus = CitationStatus.asistio);
                _applyFilters(context);
              },
            ),
            const SizedBox(width: 8),
            _buildStatusChip(
              context,
              label: 'No Asistió (${statusCounts[CitationStatus.noAsistio] ?? 0})',
              isSelected: _selectedStatus == CitationStatus.noAsistio,
              color: Colors.red,
              onTap: () {
                setState(() => _selectedStatus = CitationStatus.noAsistio);
                _applyFilters(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, CitationState state) {
    if (state is CitationLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CitationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CitationBloc>().add(LoadMyCitationsEvent()),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is CitationsLoaded) {
      final citations = state.filteredCitations;

      if (citations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                _selectedStatus != null || _searchController.text.isNotEmpty
                    ? 'No se encontraron resultados'
                    : 'No hay citaciones',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<CitationBloc>().add(RefreshCitationsEvent());
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: citations.length,
          itemBuilder: (context, index) {
            return _buildCitationCard(context, citations[index]);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCitationCard(BuildContext context, CitationEntity citation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showCitationDetail(context, citation),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icono de estado
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getStatusColor(citation.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(citation.status),
                  color: _getStatusColor(citation.status),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          citation.citationNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        _buildStatusBadge(citation.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      citation.targetDisplayName,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      citation.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(citation.createdAt),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CitationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==================== DETALLE ====================
  void _showCitationDetail(BuildContext context, CitationEntity citation) async {
    final bloc = context.read<CitationBloc>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _CitationDetailScreen(citation: citation, bloc: bloc),
        ),
      ),
    );

    // Recargar si hubo cambios
    if (result == true && mounted) {
      bloc.add(RefreshCitationsEvent());
    }
  }

  void _navigateToCreate(BuildContext context) async {
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

  void _applyFilters(BuildContext context) {
    context.read<CitationBloc>().add(FilterCitationsEvent(
          status: _selectedStatus,
          searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        ));
  }

  Color _getStatusColor(CitationStatus status) {
    switch (status) {
      case CitationStatus.pendiente:
        return Colors.orange;
      case CitationStatus.notificado:
        return Colors.blue;
      case CitationStatus.asistio:
        return Colors.green;
      case CitationStatus.noAsistio:
        return Colors.red;
      case CitationStatus.cancelado:
        return Colors.grey;
    }
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== PANTALLA DE DETALLE ====================
class _CitationDetailScreen extends StatefulWidget {
  final CitationEntity citation;
  final CitationBloc bloc;

  const _CitationDetailScreen({required this.citation, required this.bloc});

  @override
  State<_CitationDetailScreen> createState() => _CitationDetailScreenState();
}

class _CitationDetailScreenState extends State<_CitationDetailScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);
  bool _isUpdating = false;

  CitationEntity get citation => widget.citation;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CitationBloc, CitationState>(
      listener: (context, state) {
        if (state is CitationUpdated) {
          // Quitar indicador y volver a la lista
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true); // true indica que hubo cambios
        } else if (state is CitationError) {
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(citation.citationNumber),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado actual
            _buildStatusHeader(),
            const SizedBox(height: 16),

            // Información principal
            _buildInfoSection(),

            // Mapa si hay ubicación
            if (citation.latitude != null && citation.longitude != null) ...[
              const SizedBox(height: 16),
              _buildMapSection(context),
            ],

            // Fotos si hay
            if (citation.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPhotosSection(context),
            ],

            // Notas/Observaciones
            if (citation.notes != null && citation.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesSection(),
            ],

            const SizedBox(height: 24),

            // Botón de cambiar estado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusDialog(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Cambiar Estado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
          ),
          // Indicador de carga mientras actualiza
          if (_isUpdating)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Actualizando estado...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: _getStatusColor(citation.status).withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(citation.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(citation.status),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  citation.status.displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(citation.status),
                  ),
                ),
                Text(
                  citation.citationType.displayName,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person, 'Citado', citation.targetDisplayName),
          if (citation.targetRut != null)
            _buildInfoRow(Icons.badge, 'RUT', citation.targetRut!),
          if (citation.targetPlate != null)
            _buildInfoRow(Icons.directions_car, 'Patente', citation.targetPlate!),
          if (citation.targetPhone != null)
            _buildInfoRow(Icons.phone, 'Teléfono', citation.targetPhone!),
          if (citation.targetAddress != null)
            _buildInfoRow(Icons.home, 'Dirección', citation.targetAddress!),
          const Divider(height: 24),
          _buildInfoRow(Icons.description, 'Motivo', citation.reason),
          if (citation.locationAddress != null)
            _buildInfoRow(Icons.location_on, 'Ubicación', citation.locationAddress!),
          const Divider(height: 24),
          _buildInfoRow(Icons.calendar_today, 'Fecha', _formatDateTime(citation.createdAt)),
          if (citation.issuerName != null)
            _buildInfoRow(Icons.person_outline, 'Inspector', citation.issuerName!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullMap(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(citation.latitude!, citation.longitude!),
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // Solo vista en miniatura
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.frogio.santa_juana',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(citation.latitude!, citation.longitude!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
            // Indicador de "tap para ampliar"
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Ampliar', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullMapScreen(
          citationLocation: LatLng(citation.latitude!, citation.longitude!),
          citationAddress: citation.locationAddress ?? 'Ubicación de la citación',
        ),
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fotos (${citation.photos.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: citation.photos.length,
              itemBuilder: (context, index) {
                final photoUrl = citation.photos[index];
                return GestureDetector(
                  onTap: () => _showFullImage(context, photoUrl),
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: EdgeInsets.only(right: index < citation.photos.length - 1 ? 10 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Observaciones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(citation.notes!),
        ],
      ),
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    final observacionController = TextEditingController();
    CitationStatus? selectedStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar Estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Citación: ${citation.citationNumber}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Opciones de estado
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CitationStatus.asistio,
                  CitationStatus.noAsistio,
                  CitationStatus.notificado,
                  CitationStatus.cancelado,
                ].map((status) {
                  final isSelected = selectedStatus == status;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedStatus = status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getStatusColor(status)
                            : _getStatusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 18,
                            color: isSelected ? Colors.white : _getStatusColor(status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Campo de observación
              TextField(
                controller: observacionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Detalle / Observación',
                  hintText: 'Ej: Se asistió y se dejó advertencia por ruidos molestos...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedStatus == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _updateStatus(context, selectedStatus!, observacionController.text);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, CitationStatus status, String observacion) {
    // Mostrar indicador de carga
    setState(() => _isUpdating = true);

    // Actualizar con la nueva observación
    final notes = observacion.isNotEmpty
        ? (citation.notes != null && citation.notes!.isNotEmpty
            ? '${citation.notes}\n\n[${_formatDateTime(DateTime.now())}] $observacion'
            : '[${_formatDateTime(DateTime.now())}] $observacion')
        : citation.notes;

    widget.bloc.add(
          UpdateCitationEvent(
            id: citation.id,
            dto: UpdateCitationDto(status: status, notes: notes),
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
        return Colors.green;
      case CitationStatus.noAsistio:
        return Colors.red;
      case CitationStatus.cancelado:
        return Colors.grey;
    }
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

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== PANTALLA DE MAPA COMPLETO ====================
class _FullMapScreen extends StatefulWidget {
  final LatLng citationLocation;
  final String citationAddress;

  const _FullMapScreen({
    required this.citationLocation,
    required this.citationAddress,
  });

  @override
  State<_FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<_FullMapScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);
  final MapController _mapController = MapController();
  LatLng? _inspectorLocation;
  bool _isLoadingLocation = true;
  double _currentZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _inspectorLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _centerOnCitation() {
    _mapController.move(widget.citationLocation, _currentZoom);
  }

  void _centerOnInspector() {
    if (_inspectorLocation != null) {
      _mapController.move(_inspectorLocation!, _currentZoom);
    }
  }

  void _fitBothLocations() {
    if (_inspectorLocation == null) {
      _centerOnCitation();
      return;
    }

    // Calcular bounds para incluir ambas ubicaciones
    final bounds = LatLngBounds.fromPoints([
      widget.citationLocation,
      _inspectorLocation!,
    ]);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_inspectorLocation != null)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: 'Ver ambas ubicaciones',
              onPressed: _fitBothLocations,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.citationLocation,
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.zoom != null) {
                  setState(() {
                    _currentZoom = position.zoom!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.frogio.santa_juana',
              ),
              MarkerLayer(
                markers: [
                  // Marcador de la citación
                  Marker(
                    point: widget.citationLocation,
                    width: 50,
                    height: 50,
                    child: const Column(
                      children: [
                        Icon(Icons.location_pin, color: Colors.red, size: 40),
                        Text(
                          'Citación',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Marcador del inspector si está disponible
                  if (_inspectorLocation != null)
                    Marker(
                      point: _inspectorLocation!,
                      width: 50,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const Text(
                            'Tú',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Línea entre ambas ubicaciones
              if (_inspectorLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [widget.citationLocation, _inspectorLocation!],
                      strokeWidth: 3,
                      color: _primaryGreen.withValues(alpha: 0.7),
                      isDotted: true,
                    ),
                  ],
                ),
            ],
          ),

          // Panel de información
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.citationAddress,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_inspectorLocation != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.directions_walk, color: _primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Distancia: ${_calculateDistance()} m',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ] else if (_isLoadingLocation) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Obteniendo tu ubicación...'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Controles de zoom
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, _zoomIn),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, _zoomOut),
              ],
            ),
          ),

          // Botones de centrar
          Positioned(
            left: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildLocationButton(
                  Icons.location_pin,
                  Colors.red,
                  'Citación',
                  _centerOnCitation,
                ),
                const SizedBox(height: 8),
                if (_inspectorLocation != null)
                  _buildLocationButton(
                    Icons.my_location,
                    _primaryGreen,
                    'Mi ubicación',
                    _centerOnInspector,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildLocationButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String _calculateDistance() {
    if (_inspectorLocation == null) return '---';

    final distance = Geolocator.distanceBetween(
      _inspectorLocation!.latitude,
      _inspectorLocation!.longitude,
      widget.citationLocation.latitude,
      widget.citationLocation.longitude,
    );

    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return distance.round().toString();
  }
}
