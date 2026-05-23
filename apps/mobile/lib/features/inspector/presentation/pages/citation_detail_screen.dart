// lib/features/inspector/presentation/pages/citation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../citizen/presentation/pages/enhanced_report_detail_screen.dart';
import '../../domain/entities/citation_entity.dart';
import '../utils/citation_ui_extensions.dart';

class CitationDetailScreen extends StatelessWidget {
  final CitationEntity citation;

  const CitationDetailScreen({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    final hasLocation = citation.latitude != null && citation.longitude != null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: hasLocation ? 250 : 0,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(citation.citationNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            flexibleSpace: hasLocation
                ? FlexibleSpaceBar(
                    background: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(citation.latitude!, citation.longitude!),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapsService.tileServerUrl,
                          tileProvider: MapsService.tileProvider,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(citation.latitude!, citation.longitude!),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.info, width: 2),
                                ),
                                child: const Icon(Icons.location_on,
                                    color: AppTheme.info, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // Info cards
                  _buildInfoCard(context, [
                    _infoRow(Icons.category_outlined, 'Tipo',
                        citation.citationType.displayName),
                    _infoRow(Icons.person_outline, 'Objetivo',
                        '${citation.targetType.displayName}: ${citation.targetDisplayName}'),
                    if (citation.targetRut != null)
                      _infoRow(Icons.badge_outlined, 'RUT', citation.targetRut!),
                    if (citation.targetPlate != null)
                      _infoRow(Icons.directions_car_outlined, 'Patente',
                          citation.targetPlate!),
                    if (citation.targetPhone != null)
                      _infoRow(Icons.phone_outlined, 'Telefono',
                          citation.targetPhone!),
                    if (citation.targetAddress != null)
                      _infoRow(Icons.edit_location_alt_outlined,
                          'Direccion (ingresada)', citation.targetAddress!),
                    if (citation.locationAddress != null &&
                        citation.locationAddress != citation.targetAddress)
                      _infoRow(Icons.my_location_outlined, 'Ubicacion GPS',
                          citation.locationAddress!),
                    if (hasLocation)
                      _infoRow(Icons.pin_drop_outlined, 'Coordenadas',
                          '${citation.latitude!.toStringAsFixed(5)}, ${citation.longitude!.toStringAsFixed(5)}'),
                  ]),

                  const SizedBox(height: 16),

                  // Reason
                  _buildSectionCard(
                    'Motivo',
                    Icons.description_outlined,
                    child: Text(citation.reason,
                        style: AppTheme.bodyLarge
                            .copyWith(color: AppTheme.textPrimary)),
                  ),

                  const SizedBox(height: 16),

                  // Emission info — WHO, WHEN, WHERE
                  _buildInfoCard(context, [
                    _infoRow(
                        Icons.calendar_today_outlined,
                        'Emitida',
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(citation.createdAt)),
                    if (citation.issuerName != null)
                      _infoRow(Icons.person_pin_outlined, 'Inspector',
                          citation.issuerName!),
                  ]),

                  // Notes
                  if (citation.notes != null && citation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Notas del Inspector',
                      Icons.note_alt_outlined,
                      child: Text(citation.notes!,
                          style: AppTheme.bodyMedium
                              .copyWith(color: AppTheme.textSecondary)),
                    ),
                  ],

                  // Photos
                  if (citation.photos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Evidencia Fotografica',
                      Icons.photo_library_outlined,
                      child: SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: citation.photos.length,
                          itemBuilder: (context, index) {
                            var photoUrl = citation.photos[index];
                            if (photoUrl.contains('192.168.') ||
                                photoUrl.contains('localhost')) {
                              final uri = Uri.parse(photoUrl);
                              photoUrl = '${ApiConfig.activeBaseUrl}${uri.path}';
                            } else if (!photoUrl.startsWith('http')) {
                              photoUrl = '${ApiConfig.activeBaseUrl}$photoUrl';
                            }
                            return GestureDetector(
                              onTap: () => _showFullImage(context, photoUrl),
                              child: Container(
                                width: 120,
                                margin: EdgeInsets.only(
                                    right: index < citation.photos.length - 1
                                        ? 10
                                        : 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.surface,
                                      child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: AppTheme.textTertiary),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // Linked report
                  if (citation.reportId != null) ...[
                    const SizedBox(height: 16),
                    _buildLinkedReportSection(context),
                  ],

                  const SizedBox(height: 32),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(citation.citationType.icon,
              color: AppTheme.success, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(citation.citationNumber,
                  style: AppTheme.titleLarge
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Emitida',
                  style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTheme.labelSmall
                        .copyWith(color: AppTheme.textTertiary)),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTheme.titleSmall
                      .copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLinkedReportSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnhancedReportDetailScreen(
                  reportId: citation.reportId!,
                  currentUserRole: 'inspector'),
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link_rounded,
                  color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Ver denuncia vinculada',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white)),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(url,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                        color: Colors.white, size: 64)),
              ),
            ),
          ),
        ));
  }
}
