// lib/features/panic/presentation/pages/panic_alert_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;

class PanicAlertDetailScreen extends StatefulWidget {
  final String? alertId;
  final double? latitude;
  final double? longitude;
  final String? message;

  const PanicAlertDetailScreen({
    super.key,
    this.alertId,
    this.latitude,
    this.longitude,
    this.message,
  });

  @override
  State<PanicAlertDetailScreen> createState() => _PanicAlertDetailScreenState();
}

class _PanicAlertDetailScreenState extends State<PanicAlertDetailScreen> {
  Map<String, dynamic>? _alert;
  bool _isLoading = true;
  bool _isActing = false;
  Timer? _refreshTimer;
  Timer? _locationTimer;
  final MapController _mapController = MapController();
  LatLng? _inspectorLocation;

  @override
  void initState() {
    super.initState();
    _loadAlert();
    _startLocationTracking();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadAlert(silent: true);
    });
  }

  Future<void> _startLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      // Get initial position
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _inspectorLocation = LatLng(pos.latitude, pos.longitude));

      // Update every 3 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (mounted) setState(() => _inspectorLocation = LatLng(p.latitude, p.longitude));
        } catch (_) {}
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlert({bool silent = false}) async {
    final client = di.sl<AuthHttpClient>();
    try {
      if (widget.alertId != null) {
        final res = await client.get(Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/${widget.alertId}'));
        if (res.statusCode == 200 && mounted) {
          final data = json.decode(res.body);
          setState(() { _alert = data; _isLoading = false; });
          // Si fue resuelto/cancelado por otro inspector, mostrar y cerrar
          final status = data['status']?.toString() ?? '';
          if (status == 'resolved' || status == 'cancelled' || status == 'dismissed') {
            _refreshTimer?.cancel();
            if (!silent) return;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Esta alerta fue cerrada'), backgroundColor: AppTheme.info),
              );
            }
          }
          return;
        }
      }
      // Fallback: buscar alerta activa más reciente
      final res = await client.get(Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/active'));
      if (res.statusCode == 200 && mounted) {
        final List<dynamic> alerts = json.decode(res.body);
        if (alerts.isNotEmpty) {
          setState(() { _alert = alerts.first as Map<String, dynamic>; _isLoading = false; });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading alert: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String get _userName {
    final parts = [_alert?['first_name'], _alert?['last_name']];
    return parts.where((s) => s != null && s.toString().isNotEmpty).join(' ');
  }

  String? get _phone => _alert?['phone']?.toString() ?? _alert?['contact_phone']?.toString();
  String get _status => _alert?['status']?.toString() ?? 'active';
  double get _lat => (_alert?['latitude'] as num?)?.toDouble() ?? widget.latitude ?? 0;
  double get _lng => (_alert?['longitude'] as num?)?.toDouble() ?? widget.longitude ?? 0;
  bool get _isClosed => _status == 'resolved' || _status == 'cancelled' || _status == 'dismissed';

  Future<void> _respondToAlert() async {
    final id = _alert?['id'] ?? widget.alertId;
    if (id == null) return;
    setState(() => _isActing = true);
    HapticFeedback.heavyImpact();

    try {
      final res = await di.sl<AuthHttpClient>().patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/$id/respond'),
      );
      if (res.statusCode == 200 && mounted) {
        setState(() { _alert?['status'] = 'responding'; _isActing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asistiendo al SOS. El ciudadano fue notificado.'), backgroundColor: AppTheme.success),
        );
      } else {
        final err = json.decode(res.body);
        if (mounted) {
          setState(() => _isActing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err['error'] ?? 'Error'), backgroundColor: AppTheme.emergency),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _resolveAlert() async {
    final id = _alert?['id'] ?? widget.alertId;
    if (id == null) return;

    final notesController = TextEditingController();
    List<File> evidenceFiles = [];

    // Capturar ubicación actual del inspector
    Position? inspectorPosition;
    try {
      inspectorPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    if (!mounted) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                Text('Cerrar Procedimiento', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Describe que ocurrio y adjunta evidencia', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),

                if (inspectorPosition != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: AppTheme.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Ubicacion capturada: ${inspectorPosition.latitude.toStringAsFixed(5)}, ${inspectorPosition.longitude.toStringAsFixed(5)}',
                          style: AppTheme.labelSmall.copyWith(color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Que ocurrio? Describe la situacion...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                ),

                const SizedBox(height: 12),

                // Evidence files preview
                if (evidenceFiles.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: evidenceFiles.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(entry.value, width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () => setSheetState(() => evidenceFiles.removeAt(entry.key)),
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
                        // Compress
                        File file = File(picked.path);
                        try {
                          final dir = await getTemporaryDirectory();
                          final target = '${dir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final compressed = await FlutterImageCompress.compressAndGetFile(
                            file.absolute.path, target, quality: 70, minWidth: 1280, minHeight: 1280,
                          );
                          if (compressed != null) file = File(compressed.path);
                        } catch (_) {}
                        setSheetState(() => evidenceFiles.add(file));
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text('Adjuntar foto (${evidenceFiles.length}/5)'),
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
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cerrar Procedimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != true) return;

    setState(() => _isActing = true);
    try {
      final notes = notesController.text.trim();
      final resolveNotes = inspectorPosition != null
          ? '$notes\n\n[Ubicacion inspector: ${inspectorPosition.latitude}, ${inspectorPosition.longitude}]'
          : notes;

      final res = await di.sl<AuthHttpClient>().patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/panic/$id/resolve'),
        body: json.encode({'notes': resolveNotes}),
      );
      if (res.statusCode == 200 && mounted) {
        _refreshTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Procedimiento cerrado exitosamente'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.emergency),
        );
      }
    }
  }

  Widget _buildAvatar() {
    final avatar = _alert?['avatar']?.toString();
    const size = 52.0;
    if (avatar != null && avatar.isNotEmpty) {
      final url = avatar.startsWith('http') ? avatar : '${ApiConfig.activeBaseUrl}$avatar';
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(size),
        ),
      );
    }
    return _avatarFallback(size);
  }

  Widget _avatarFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.emergency.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.person_rounded, color: AppTheme.emergency, size: 28),
    );
  }

  List<String> _asStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = json.decode(raw);
        if (parsed is List) return parsed.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      } catch (_) {}
      return [raw];
    }
    return [];
  }

  Widget _medicalChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTheme.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMedicalCard() {
    final mr = _alert?['medical_record'];
    if (mr == null) return const SizedBox.shrink();

    final allergies = _asStringList(mr['allergies']);
    final chronic = _asStringList(mr['chronic_conditions']);
    final medications = _asStringList(mr['medications']);
    final notes = mr['medical_notes']?.toString();

    if (allergies.isEmpty && chronic.isEmpty && medications.isEmpty && (notes == null || notes.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.emergency.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.emergency.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_rounded, color: AppTheme.emergency, size: 20),
                const SizedBox(width: 8),
                Text('Ficha médica', style: AppTheme.titleSmall.copyWith(color: AppTheme.emergency, fontWeight: FontWeight.bold)),
              ],
            ),
            if (allergies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Alergias', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: allergies.map((a) => _medicalChip(a, Icons.warning_amber_rounded, AppTheme.emergency)).toList()),
            ],
            if (chronic.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Condiciones crónicas', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: chronic.map((c) => _medicalChip(c, Icons.favorite_rounded, Colors.orange)).toList()),
            ],
            if (medications.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Medicamentos', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: medications.map((m) => _medicalChip(m, Icons.medication_rounded, AppTheme.primary)).toList()),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Observaciones', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(notes, style: AppTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildEmergencyContactsCard() {
    final mr = _alert?['medical_record'];
    if (mr == null) return const SizedBox.shrink();

    final contactName = mr['emergency_contact_name']?.toString();
    final contactPhone = mr['emergency_contact_phone']?.toString();

    final family = mr['family_members'];
    List<Map<String, dynamic>> familyList = [];
    if (family is List) {
      familyList = family.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (family is String && family.isNotEmpty) {
      try {
        final parsed = json.decode(family);
        if (parsed is List) {
          familyList = parsed.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
    }

    final hasContact = (contactName != null && contactName.isNotEmpty) || (contactPhone != null && contactPhone.isNotEmpty);
    if (!hasContact && familyList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contacts_rounded, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('Contactos de emergencia', style: AppTheme.titleSmall.copyWith(color: AppTheme.success, fontWeight: FontWeight.bold)),
              ],
            ),
            if (hasContact) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contactName?.isNotEmpty == true ? contactName! : 'Contacto', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        if (contactPhone != null && contactPhone.isNotEmpty)
                          Text(contactPhone, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (contactPhone != null && contactPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppTheme.success),
                      onPressed: () => _callNumber(contactPhone),
                    ),
                ],
              ),
            ],
            if (familyList.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Grupo familiar', style: AppTheme.labelSmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...familyList.map((m) {
                final name = m['name']?.toString() ?? m['fullName']?.toString() ?? '';
                final relation = m['relation']?.toString() ?? m['relationship']?.toString() ?? '';
                final phone = m['phone']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.group_rounded, size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [name, if (relation.isNotEmpty) '($relation)'].where((s) => s.isNotEmpty).join(' '),
                          style: AppTheme.bodySmall,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        GestureDetector(
                          onTap: () => _callNumber(phone),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, size: 14, color: AppTheme.success),
                              const SizedBox(width: 4),
                              Text(phone, style: AppTheme.labelSmall.copyWith(color: AppTheme.success, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mapButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Future<void> _callUser() async {
    if (_phone == null) return;
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Center(child: CircularProgressIndicator(color: AppTheme.emergency)),
      );
    }

    if (_alert == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('SOS', style: TextStyle(color: Colors.white)), backgroundColor: AppTheme.emergency, foregroundColor: Colors.white, iconTheme: const IconThemeData(color: Colors.white)),
        body: const Center(child: Text('No se encontro la alerta')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: LatLng(_lat, _lng), initialZoom: 15),
                  children: [
                    TileLayer(urlTemplate: MapsService.tileServerUrl, tileProvider: MapsService.tileProvider),
                    MarkerLayer(
                      markers: [
                        // SOS location marker
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 60, height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.emergency.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.emergency, width: 2),
                            ),
                            child: const Icon(Icons.sos, color: AppTheme.emergency, size: 30),
                          ),
                        ),
                        // Inspector location marker
                        if (_inspectorLocation != null)
                          Marker(
                            point: _inspectorLocation!,
                            width: 44, height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue, width: 2),
                              ),
                              child: const Icon(Icons.my_location, color: Colors.blue, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8, left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
                  ),
                ),
                // Status badge
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isClosed ? AppTheme.textSecondary : (_status == 'responding' ? AppTheme.success : AppTheme.emergency),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isClosed ? Icons.check_circle : (_status == 'responding' ? Icons.directions_run_rounded : Icons.warning_rounded),
                          color: Colors.white, size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isClosed ? 'CERRADO' : (_status == 'responding' ? 'EN CAMINO' : 'SOS ACTIVO'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Map control buttons
                Positioned(
                  bottom: 16, right: 12,
                  child: Column(
                    children: [
                      // Center on SOS
                      _mapButton(Icons.sos, AppTheme.emergency, () {
                        _mapController.move(LatLng(_lat, _lng), 16);
                      }),
                      const SizedBox(height: 8),
                      // Center on my location
                      _mapButton(Icons.my_location, Colors.blue, () {
                        if (_inspectorLocation != null) {
                          _mapController.move(_inspectorLocation!, 16);
                        }
                      }),
                      const SizedBox(height: 8),
                      // Fit both markers
                      _mapButton(Icons.zoom_out_map, AppTheme.primary, () {
                        if (_inspectorLocation != null) {
                          final bounds = LatLngBounds(LatLng(_lat, _lng), _inspectorLocation!);
                          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
                        } else {
                          _mapController.move(LatLng(_lat, _lng), 15);
                        }
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info panel
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),

                    // Citizen info + call
                    Row(
                      children: [
                        _buildAvatar(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName.isNotEmpty ? _userName : 'Ciudadano', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                              if (_alert?['rut'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('RUT: ${_alert!['rut']}', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                                ),
                              if (_alert?['email'] != null)
                                Text(_alert!['email'].toString(), style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        if (_phone != null)
                          FloatingActionButton.small(
                            heroTag: 'call',
                            onPressed: _callUser,
                            backgroundColor: AppTheme.success,
                            child: const Icon(Icons.phone_rounded, color: Colors.white),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Message + address
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_alert?['message']?.toString() ?? widget.message ?? 'Emergencia', style: AppTheme.bodyLarge),
                          if (_alert?['address'] != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.textTertiary),
                                const SizedBox(width: 4),
                                Expanded(child: Text(_alert!['address'].toString(), style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary))),
                              ],
                            ),
                          ],
                          if (_alert?['user_address'] != null && _alert!['user_address'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.home_rounded, size: 14, color: AppTheme.textTertiary),
                                const SizedBox(width: 4),
                                Expanded(child: Text('Domicilio: ${_alert!['user_address']}', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Medical record
                    _buildMedicalCard(),

                    // Emergency contacts
                    _buildEmergencyContactsCard(),

                    if (_phone != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _callUser,
                          icon: const Icon(Icons.phone_rounded, color: AppTheme.success),
                          label: Text('Llamar: $_phone', style: const TextStyle(color: AppTheme.success)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.success),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // === ACTION BUTTONS ===
                    if (_status == 'active')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isActing ? null : _respondToAlert,
                          icon: _isActing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.directions_run_rounded, size: 24),
                          label: Text(
                            _isActing ? 'Enviando...' : 'ASISTIR',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emergency,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                    if (_status == 'responding')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isActing ? null : _resolveAlert,
                          icon: const Icon(Icons.check_circle_rounded, size: 24),
                          label: const Text(
                            'CERRAR PROCEDIMIENTO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                    // Responders list
                    if (_alert?['responders'] != null && (_alert!['responders'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text('Inspectores asistiendo (${(_alert!['responders'] as List).length})',
                                    style: AppTheme.titleSmall.copyWith(color: AppTheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...(_alert!['responders'] as List).map<Widget>((r) {
                              final name = '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
                              final time = DateTime.tryParse(r['responded_at']?.toString() ?? '');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 16, color: AppTheme.success),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(name.isNotEmpty ? name : 'Inspector', style: AppTheme.bodyMedium)),
                                    if (time != null)
                                      Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                                          style: AppTheme.labelSmall.copyWith(color: AppTheme.textTertiary)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    if (_isClosed) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 40),
                            const SizedBox(height: 8),
                            Text('Procedimiento cerrado', style: AppTheme.titleMedium.copyWith(color: AppTheme.success)),
                            if (_alert?['notes'] != null) ...[
                              const SizedBox(height: 8),
                              Text(_alert!['notes'].toString(), style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
