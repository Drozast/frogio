// lib/features/citizen/presentation/pages/enhanced_report_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frogio_mobile/core/services/maps_service.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/enhanced_report_entity.dart';
import '../bloc/report/enhanced_report_bloc.dart';
import '../bloc/report/enhanced_report_event.dart';
import '../bloc/report/enhanced_report_state.dart';

class EnhancedReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String? currentUserRole;
  final String? currentUserId;

  const EnhancedReportDetailScreen({
    super.key,
    required this.reportId,
    this.currentUserRole,
    this.currentUserId,
  });

  @override
  State<EnhancedReportDetailScreen> createState() => _EnhancedReportDetailScreenState();
}

class _EnhancedReportDetailScreenState extends State<EnhancedReportDetailScreen> {
  late ReportBloc _reportBloc;
  final MapController _mapController = MapController();
  LatLng? _myLocation;
  List<LatLng> _routePoints = [];
  Timer? _locationTimer;
  bool _loadingRoute = false;

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _reportBloc = di.sl<ReportBloc>();
    _loadReport();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));

      _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (mounted) setState(() => _myLocation = LatLng(p.latitude, p.longitude));
        } catch (_) {}
      });
    } catch (_) {}
  }

  void _loadReport() {
    _reportBloc.add(GetReportByIdEvent(reportId: widget.reportId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _reportBloc,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            } else if (state is ReportLoaded) {
              return _buildBody(state.report);
            } else if (state is ReportError) {
              return _buildError(state.message);
            }
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          },
        ),
      ),
    );
  }

  Widget _buildBody(ReportEntity report) {
    final loc = report.location;
    final hasCoords = loc.latitude != 0 && loc.longitude != 0;
    final statusColor = _statusColor(report.status);
    final reportLocation = LatLng(loc.latitude, loc.longitude);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: hasCoords ? 280 : 0,
          pinned: true,
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Detalle de Denuncia', style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadReport),
          ],
          flexibleSpace: hasCoords
              ? FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(initialCenter: reportLocation, initialZoom: 15),
                        children: [
                          TileLayer(
                            urlTemplate: MapsService.tileServerUrl,
                            tileProvider: MapsService.tileProvider,
                            userAgentPackageName: 'com.frogio.santajuana',
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(polylines: [
                              Polyline(points: _routePoints, strokeWidth: 4, color: AppTheme.primary),
                            ]),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: reportLocation,
                                width: 40, height: 40,
                                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                              ),
                              if (_myLocation != null)
                                Marker(
                                  point: _myLocation!,
                                  width: 36, height: 36,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.blue, width: 2),
                                    ),
                                    child: const Icon(Icons.my_location, color: Colors.blue, size: 18),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Status badge
                      Positioned(
                        bottom: 12, left: 12,
                        child: _buildStatusBadge(report.status, statusColor),
                      ),
                      // Map control buttons
                      Positioned(
                        bottom: 12, right: 12,
                        child: Column(
                          children: [
                            _mapBtn(Icons.location_pin, Colors.red, () {
                              _mapController.move(reportLocation, 16);
                            }),
                            const SizedBox(height: 8),
                            _mapBtn(Icons.my_location, Colors.blue, () {
                              if (_myLocation != null) _mapController.move(_myLocation!, 16);
                            }),
                            const SizedBox(height: 8),
                            _mapBtn(
                              _loadingRoute ? Icons.hourglass_empty : Icons.directions,
                              AppTheme.primary,
                              () => _calculateRoute(reportLocation),
                            ),
                            if (_myLocation != null) ...[
                              const SizedBox(height: 8),
                              _mapBtn(Icons.zoom_out_map, AppTheme.primary, () {
                                final bounds = LatLngBounds(reportLocation, _myLocation!);
                                _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _card([
                Text(_capitalize(report.title), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _chip(_capitalize(report.category), AppTheme.primary),
                    if (!hasCoords) _buildStatusBadge(report.status, statusColor),
                  ],
                ),
                if (loc.address != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(child: Text(loc.address!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                    ],
                  ),
                ],
              ]),

              const SizedBox(height: 12),

              _card([
                _sectionTitle('Descripcion', Icons.description),
                const SizedBox(height: 8),
                Text(report.description, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5)),
              ]),

              if (report.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                _card([
                  _sectionTitle('Evidencia', Icons.photo_library),
                  const SizedBox(height: 12),
                  _buildPhotoGallery(report.attachments),
                ]),
              ],

              const SizedBox(height: 12),

              _card([
                _sectionTitle('Fechas', Icons.calendar_today),
                const SizedBox(height: 8),
                _infoRow('Creada', DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt)),
                _infoRow('Actualizada', DateFormat('dd/MM/yyyy HH:mm').format(report.updatedAt)),
                if (report.status == ReportStatus.resuelto || report.status == ReportStatus.rechazado)
                  _infoRow(report.status == ReportStatus.resuelto ? 'Resuelta' : 'Rechazada', _resolvedDate(report)),
              ]),

              const SizedBox(height: 12),

              _card([
                _sectionTitle('Progreso', Icons.track_changes),
                const SizedBox(height: 16),
                _buildProgressTracker(report),
              ]),

              if (widget.currentUserRole == 'inspector') ...[
                const SizedBox(height: 12),
                _card([
                  _sectionTitle('Denunciante', Icons.person),
                  const SizedBox(height: 8),
                  _infoRow('Nombre', report.citizenName ?? 'No disponible'),
                  if (report.citizenEmail != null) _infoRow('Email', report.citizenEmail!),
                  if (report.citizenPhone != null && report.citizenPhone!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri(scheme: 'tel', path: report.citizenPhone);
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('Llamar: ${report.citizenPhone}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ]),
              ],

              if (report.assignedToName != null) ...[
                const SizedBox(height: 12),
                _card([
                  _sectionTitle('Inspector asignado', Icons.badge),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          report.assignedToName![0].toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(report.assignedToName!, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
                    ],
                  ),
                ]),
              ],

              if (report.statusHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                _card([
                  _sectionTitle('Historial', Icons.history),
                  const SizedBox(height: 12),
                  _buildTimeline(report.statusHistory),
                ]),
              ],

              // Inspector action buttons
              if (widget.currentUserRole == 'inspector') ...[
                const SizedBox(height: 20),
                _buildInspectorActions(report),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorActions(ReportEntity report) {
    if (report.status == ReportStatus.resuelto || report.status == ReportStatus.rechazado) {
      return const SizedBox.shrink();
    }

    if (report.status == ReportStatus.pendiente) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _attendReport(report),
          icon: const Icon(Icons.assignment_ind_rounded, size: 22),
          label: const Text('ATENDER DENUNCIA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    // en_proceso
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _closeReport(report, resolve: true),
            icon: const Icon(Icons.check_circle_rounded, size: 22),
            label: const Text('CERRAR DENUNCIA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _closeReport(report, resolve: false),
            icon: const Icon(Icons.cancel_outlined, size: 20),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emergency,
              side: BorderSide(color: AppTheme.emergency.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _attendReport(ReportEntity report) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    _reportBloc.add(UpdateReportStatusEvent(
      reportId: report.id,
      status: 'en_proceso',
      comment: 'Inspector atendiendo la denuncia',
      userId: authState.user.id,
      assignedTo: authState.user.id,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Denuncia tomada'), backgroundColor: AppTheme.success),
    );
  }

  Future<void> _closeReport(ReportEntity report, {required bool resolve}) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final notesController = TextEditingController();
    List<File> evidence = [];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(resolve ? 'Cerrar Denuncia' : 'Rechazar Denuncia',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(resolve ? 'Describe como se resolvio la denuncia' : 'Describe por que se rechaza',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Detalle de lo realizado...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                ),
                const SizedBox(height: 12),

                if (evidence.isNotEmpty) ...[
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: evidence.asMap().entries.map((e) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(e.value, width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -4, right: -4,
                            child: GestureDetector(
                              onTap: () => setSheet(() => evidence.removeAt(e.key)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: AppTheme.emergency, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                OutlinedButton.icon(
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: ctx,
                      builder: (c) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded),
                              title: const Text('Camara'),
                              onTap: () => Navigator.pop(c, ImageSource.camera),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library_rounded),
                              title: const Text('Galeria'),
                              onTap: () => Navigator.pop(c, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source != null) {
                      final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
                      if (picked != null) {
                        File f = File(picked.path);
                        try {
                          final dir = await getTemporaryDirectory();
                          final target = '${dir.path}/ev_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final compressed = await FlutterImageCompress.compressAndGetFile(
                            f.absolute.path, target, quality: 70, minWidth: 1280, minHeight: 1280,
                          );
                          if (compressed != null) f = File(compressed.path);
                        } catch (_) {}
                        setSheet(() => evidence.add(f));
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text('Adjuntar foto (${evidence.length}/5)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: notesController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resolve ? AppTheme.success : AppTheme.emergency,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(resolve ? 'Cerrar Denuncia' : 'Rechazar Denuncia',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;

    _reportBloc.add(UpdateReportStatusEvent(
      reportId: report.id,
      status: resolve ? 'resuelto' : 'rechazado',
      comment: notesController.text.trim(),
      userId: authState.user.id,
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resolve ? 'Denuncia cerrada' : 'Denuncia rechazada'),
          backgroundColor: resolve ? AppTheme.success : AppTheme.emergency,
        ),
      );
    }
  }

  Future<void> _calculateRoute(LatLng destination) async {
    if (_myLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obteniendo tu ubicacion...')),
      );
      return;
    }

    setState(() => _loadingRoute = true);
    try {
      final url = 'https://routing.supertools.cl/route/v1/driving/'
          '${_myLocation!.longitude},${_myLocation!.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coords.map<LatLng>((c) => LatLng(c[1] as double, c[0] as double)).toList();
          final distance = (data['routes'][0]['distance'] as num).toDouble();
          final duration = (data['routes'][0]['duration'] as num).toDouble();

          setState(() {
            _routePoints = points;
            _loadingRoute = false;
          });

          // Fit map to route
          final bounds = LatLngBounds.fromPoints(points);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ruta: ${(distance / 1000).toStringAsFixed(1)} km · ${(duration / 60).toStringAsFixed(0)} min'),
                backgroundColor: AppTheme.primary,
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Route error: $e');
    }
    if (mounted) {
      setState(() => _loadingRoute = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la ruta'), backgroundColor: AppTheme.emergency),
      );
    }
  }

  Widget _mapBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatusBadge(ReportStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(status.displayName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildPhotoGallery(List<MediaAttachment> attachments) {
    final images = attachments.where((a) => a.type == MediaType.image).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, i) {
          var url = images[i].url;
          if (url.contains('192.168.') || url.contains('localhost')) {
            final uri = Uri.parse(url);
            url = '${ApiConfig.activeBaseUrl}${uri.path}';
          }
          return GestureDetector(
            onTap: () => _openPhoto(url),
            child: Container(
              width: 120,
              margin: EdgeInsets.only(right: i < images.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: AppTheme.textTertiary)),
                  loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressTracker(ReportEntity report) {
    if (report.status == ReportStatus.rechazado) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.emergencyLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppTheme.emergency),
            SizedBox(width: 8),
            Expanded(child: Text('Esta denuncia ha sido rechazada', style: TextStyle(color: AppTheme.emergency, fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    final steps = [
      (label: 'Pendiente', icon: Icons.send, status: ReportStatus.pendiente),
      (label: 'En Proceso', icon: Icons.engineering, status: ReportStatus.enProceso),
      (label: 'Resuelta', icon: Icons.check_circle, status: ReportStatus.resuelto),
    ];

    final order = [ReportStatus.pendiente, ReportStatus.enProceso, ReportStatus.resuelto];
    final currentIdx = order.indexOf(report.status).clamp(0, 2);

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final done = currentIdx >= i;
        final isCurrent = currentIdx == i;
        final color = done ? _statusColor(step.status) : AppTheme.textTertiary;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 40 : 32,
                      height: isCurrent ? 40 : 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? color.withValues(alpha: 0.18) : AppTheme.surfaceWhite,
                        border: Border.all(color: done ? color : AppTheme.border, width: isCurrent ? 2.5 : 1.5),
                        boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)] : null,
                      ),
                      child: Icon(step.icon, size: isCurrent ? 20 : 16, color: done ? color : AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 8),
                    Text(step.label, style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: done ? color : AppTheme.textTertiary), textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 24, height: 3,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: currentIdx > i ? _statusColor(order[i + 1]).withValues(alpha: 0.6) : AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeline(List<StatusHistoryItem> history) {
    final items = history.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == items.length - 1;
        final color = _statusColor(item.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLast ? color.withValues(alpha: 0.2) : AppTheme.surface,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: isLast ? Icon(Icons.check, size: 12, color: color) : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: color.withValues(alpha: 0.25),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.status.displayName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isLast ? color : AppTheme.textPrimary))),
                          if (isLast)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: Text('Actual', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(DateFormat('dd/MM/yyyy HH:mm').format(item.timestamp), style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      if (item.comment != null && item.comment!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.comment!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
                      ],
                      if (item.userName != null) ...[
                        const SizedBox(height: 4),
                        Text(item.userName!, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pendiente: return Colors.orange;
      case ReportStatus.enProceso: return Colors.blue;
      case ReportStatus.resuelto: return AppTheme.success;
      case ReportStatus.rechazado: return AppTheme.emergency;
    }
  }

  String _resolvedDate(ReportEntity report) {
    final matching = report.statusHistory.where((h) => h.status == report.status);
    if (matching.isNotEmpty) return DateFormat('dd/MM/yyyy HH:mm').format(matching.last.timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(report.updatedAt);
  }

  void _openPhoto(String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _PhotoViewerScreen(imageUrl: imageUrl),
      fullscreenDialog: true,
    ));
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.emergency),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;
  const _PhotoViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
