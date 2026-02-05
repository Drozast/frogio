// lib/features/inspector/presentation/pages/inspector_map_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';
import 'report_detail_screen.dart';

class InspectorMapScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? highlightReportId;

  const InspectorMapScreen({
    super.key,
    this.initialLocation,
    this.highlightReportId,
  });

  @override
  State<InspectorMapScreen> createState() => _InspectorMapScreenState();
}

class _InspectorMapScreenState extends State<InspectorMapScreen> with TickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  // Coordenadas de Santa Juana, Región del Biobío, Chile
  static const LatLng _santaJuanaCenter = LatLng(-37.1769, -72.9386);
  static const double _defaultZoom = 14.0;
  static const double _minZoom = 10.0;
  static const double _maxZoom = 18.0;

  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  double _currentZoom = _defaultZoom;

  // Data
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _panicAlerts = [];
  Map<String, dynamic>? _selectedItem;
  String _selectedType = ''; // 'report' or 'panic'
  bool _showReportsList = false;

  // Loading states
  bool _isLoading = true;
  String _currentFilter = 'all';

  // Animation for panic alerts
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initPulseAnimation();
    _getCurrentLocation();
    _loadData();
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  void _initPulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final baseUrl = ApiConfig.activeBaseUrl;

      debugPrint('🗺️ Map loading data from: $baseUrl');
      debugPrint('🔑 Token available: ${token != null}');

      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': ApiConfig.tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Load reports and panic alerts in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/reports'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/panic/active'), headers: headers),
      ]);

      final reportsResponse = results[0];
      final panicResponse = results[1];

      debugPrint('📋 Reports response: ${reportsResponse.statusCode}');
      debugPrint('🚨 Panic response: ${panicResponse.statusCode}');

      setState(() {
        _isLoading = false;

        if (reportsResponse.statusCode == 200) {
          final List<dynamic> reportsData = json.decode(reportsResponse.body);
          _reports = reportsData.cast<Map<String, dynamic>>();
          debugPrint('✅ Loaded ${_reports.length} reports');
        } else {
          debugPrint('❌ Reports error: ${reportsResponse.body}');
        }

        if (panicResponse.statusCode == 200) {
          final List<dynamic> panicData = json.decode(panicResponse.body);
          _panicAlerts = panicData.cast<Map<String, dynamic>>();
          debugPrint('✅ Loaded ${_panicAlerts.length} panic alerts');
        } else {
          debugPrint('❌ Panic error: ${panicResponse.body}');
        }
      });
    } catch (e) {
      debugPrint('❌ Map load error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter out resolved/rejected reports and emergencia type (shown as SOS markers instead)
  List<Map<String, dynamic>> get _activeReports {
    return _reports.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? '';
      final type = r['type']?.toString().toLowerCase() ?? '';
      return status != 'resuelto' &&
          status != 'resolved' &&
          status != 'rechazado' &&
          status != 'rejected' &&
          type != 'emergencia';
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredReports {
    final reports = _currentFilter == 'all' ? _activeReports : _reports;

    return reports.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? '';
      switch (_currentFilter) {
        case 'all':
          // Already filtered to active only
          return true;
        case 'submitted':
          return status == 'pendiente' || status == 'submitted';
        case 'inProgress':
          return status == 'en_proceso' || status == 'in_progress' || status == 'inprogress';
        case 'resolved':
          return status == 'resuelto' || status == 'resolved';
        case 'rejected':
          return status == 'rechazado' || status == 'rejected';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Denuncias'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar',
            onSelected: (status) {
              setState(() {
                _currentFilter = status;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 18, color: _currentFilter == 'all' ? _primaryGreen : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Activas', style: TextStyle(fontWeight: _currentFilter == 'all' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'submitted',
                child: Row(
                  children: [
                    Icon(Icons.pending, size: 18, color: _currentFilter == 'submitted' ? Colors.orange : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Pendientes', style: TextStyle(fontWeight: _currentFilter == 'submitted' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'inProgress',
                child: Row(
                  children: [
                    Icon(Icons.autorenew, size: 18, color: _currentFilter == 'inProgress' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    Text('En Proceso', style: TextStyle(fontWeight: _currentFilter == 'inProgress' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'resolved',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: _currentFilter == 'resolved' ? Colors.green : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Resueltas (historial)', style: TextStyle(fontWeight: _currentFilter == 'resolved' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rejected',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 18, color: _currentFilter == 'rejected' ? Colors.red : Colors.grey),
                    const SizedBox(width: 8),
                    Text('Rechazadas (historial)', style: TextStyle(fontWeight: _currentFilter == 'rejected' ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Mi ubicación',
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, 16);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Obteniendo ubicación...')),
                );
                _getCurrentLocation();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Santa Juana',
            onPressed: () {
              _mapController.move(_santaJuanaCenter, _defaultZoom);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation ?? _santaJuanaCenter,
              initialZoom: _defaultZoom,
              minZoom: _minZoom,
              maxZoom: _maxZoom,
              onPositionChanged: (position, hasGesture) {
                if (position.zoom != null) {
                  setState(() => _currentZoom = position.zoom!);
                }
              },
              onTap: (_, __) {
                setState(() {
                  _selectedItem = null;
                  _selectedType = '';
                  _showReportsList = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.frogio.santa_juana',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  // Report markers
                  ..._filteredReports.map((report) => _buildReportMarker(report)),
                  // Panic alert markers (animated, rendered last = on top)
                  ..._panicAlerts.map((alert) => _buildPanicMarker(alert)),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Legend
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  _buildLegendItem(Colors.red, 'Emergencia', Icons.warning),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.orange, 'Pendiente', null),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.blue, 'En Proceso', null),
                  const SizedBox(height: 4),
                  _buildLegendItem(Colors.green, 'Resuelta', null),
                ],
              ),
            ),
          ),

          // Counters
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Panic alert counter (if any active)
                if (_panicAlerts.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${_panicAlerts.length} EMERGENCIA${_panicAlerts.length > 1 ? 'S' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Reports counter - clickable to show list
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showReportsList = !_showReportsList;
                      _selectedItem = null;
                      _selectedType = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showReportsList ? Colors.white : _primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: _showReportsList
                          ? Border.all(color: _primaryGreen, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showReportsList ? Icons.close : Icons.report,
                          color: _showReportsList ? _primaryGreen : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_filteredReports.length} denuncias',
                          style: TextStyle(
                            color: _showReportsList ? _primaryGreen : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showReportsList ? Icons.expand_less : Icons.expand_more,
                          color: _showReportsList ? _primaryGreen : Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Zoom controls
          Positioned(
            right: 16,
            bottom: _selectedItem != null ? 200 : 100,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  if (_currentZoom < _maxZoom) {
                    _mapController.move(
                      _mapController.camera.center,
                      _currentZoom + 1,
                    );
                  }
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  child: Text(
                    '${_currentZoom.toInt()}x',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, () {
                  if (_currentZoom > _minZoom) {
                    _mapController.move(
                      _mapController.camera.center,
                      _currentZoom - 1,
                    );
                  }
                }),
              ],
            ),
          ),

          // Reports list panel
          if (_showReportsList)
            Positioned(
              top: 80,
              right: 16,
              bottom: 100,
              width: 280,
              child: _buildReportsListPanel(),
            ),

          // Selected item card
          if (_selectedItem != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _selectedType == 'panic'
                  ? _buildPanicCard(_selectedItem!)
                  : _buildReportCard(_selectedItem!),
            ),
        ],
      ),
    );
  }

  Marker _buildPanicMarker(Map<String, dynamic> alert) {
    final lat = _parseCoordinate(alert['latitude']);
    final lng = _parseCoordinate(alert['longitude']);
    final isSelected = _selectedItem == alert && _selectedType == 'panic';

    return Marker(
      point: LatLng(lat, lng),
      width: 70,
      height: 70,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedItem = alert;
            _selectedType = 'panic';
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  // Inner icon
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      border: Border.all(
                        color: isSelected ? Colors.yellow : Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sos,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Marker _buildReportMarker(Map<String, dynamic> report) {
    // Parse latitude/longitude - handle both String and num types
    double lat = _parseCoordinate(report['latitude']);
    double lng = _parseCoordinate(report['longitude']);

    // Fallback to location string if lat/lng not present
    if (lat == 0 && lng == 0) {
      final location = report['location']?.toString() ?? '';
      final parts = location.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim()) ?? 0;
        lng = double.tryParse(parts[1].trim()) ?? 0;
      }
    }

    // Skip if no valid location
    if (lat == 0 && lng == 0) {
      return const Marker(
        point: LatLng(0, 0),
        width: 0,
        height: 0,
        child: SizedBox.shrink(),
      );
    }

    final color = _getStatusColor(report['status']?.toString() ?? '');
    final isSelected = _selectedItem == report && _selectedType == 'report';
    final isHighlighted = widget.highlightReportId == report['id'];

    return Marker(
      point: LatLng(lat, lng),
      width: isSelected || isHighlighted ? 50 : 40,
      height: isSelected || isHighlighted ? 50 : 40,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedItem = report;
            _selectedType = 'report';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected || isHighlighted ? Colors.white : color.withValues(alpha: 0.5),
              width: isSelected || isHighlighted ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            _getCategoryIcon(report['report_type']?.toString() ?? ''),
            color: Colors.white,
            size: isSelected || isHighlighted ? 24 : 20,
          ),
        ),
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
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 24, color: _primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsListPanel() {
    final reports = _filteredReports;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Denuncias (${reports.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() => _showReportsList = false);
                  },
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: reports.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'No hay denuncias',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportListItem(report);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportListItem(Map<String, dynamic> report) {
    final title = report['title']?.toString() ?? 'Sin título';
    final status = report['status']?.toString() ?? '';
    final reportType = report['report_type']?.toString() ?? '';
    final color = _getStatusColor(status);
    final hasLocation = _hasValidLocation(report);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getCategoryIcon(reportType),
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Row(
        children: [
          _buildStatusBadge(status),
          if (!hasLocation) ...[
            const SizedBox(width: 4),
            const Icon(Icons.location_off, size: 12, color: Colors.grey),
          ],
        ],
      ),
      trailing: hasLocation
          ? IconButton(
              icon: const Icon(Icons.my_location, color: _primaryGreen),
              tooltip: 'Ir al lugar',
              onPressed: () => _goToReport(report),
            )
          : const Icon(Icons.location_off, color: Colors.grey, size: 20),
      onTap: () {
        if (hasLocation) {
          _goToReport(report);
          setState(() {
            _selectedItem = report;
            _selectedType = 'report';
            _showReportsList = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta denuncia no tiene ubicación'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  double _parseCoordinate(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  bool _hasValidLocation(Map<String, dynamic> report) {
    // Try separate latitude/longitude fields first
    final lat = _parseCoordinate(report['latitude']);
    final lng = _parseCoordinate(report['longitude']);

    if (lat != 0 && lng != 0) return true;

    // Fallback to location string
    final location = report['location']?.toString() ?? '';
    if (location.isEmpty) return false;

    final parts = location.split(',');
    if (parts.length != 2) return false;

    final latStr = double.tryParse(parts[0].trim());
    final lngStr = double.tryParse(parts[1].trim());

    return latStr != null && lngStr != null && latStr != 0 && lngStr != 0;
  }

  void _goToReport(Map<String, dynamic> report) {
    // Try separate latitude/longitude fields first
    double lat = _parseCoordinate(report['latitude']);
    double lng = _parseCoordinate(report['longitude']);

    // Fallback to location string
    if (lat == 0 && lng == 0) {
      final location = report['location']?.toString() ?? '';
      final parts = location.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0].trim()) ?? 0;
        lng = double.tryParse(parts[1].trim()) ?? 0;
      }
    }

    if (lat != 0 && lng != 0) {
      _mapController.move(LatLng(lat, lng), 17);
    }
  }

  Future<void> _openReportDetail(Map<String, dynamic> report) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    );

    // If report was closed, refresh the data
    if (result == true) {
      setState(() {
        _selectedItem = null;
        _selectedType = '';
      });
      _loadData();
    }
  }

  Widget _buildLegendItem(Color color, String label, IconData? icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 10)
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPanicCard(Map<String, dynamic> alert) {
    final userName = '${alert['first_name'] ?? ''} ${alert['last_name'] ?? ''}'.trim();
    final phone = alert['phone']?.toString() ?? '';
    final address = alert['address']?.toString() ?? 'Sin dirección';
    final message = alert['message']?.toString() ?? 'Emergencia';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sos, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 ALERTA DE EMERGENCIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName.isNotEmpty ? userName : 'Usuario',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedItem = null;
                    _selectedType = '';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (message.isNotEmpty && message != 'Emergencia')
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Primera fila: Ir y Responder
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final lat = _parseCoordinate(alert['latitude']);
                    final lng = _parseCoordinate(alert['longitude']);
                    if (lat != 0 && lng != 0) {
                      _mapController.move(LatLng(lat, lng), 17);
                    }
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Ir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToAlert(alert['id']),
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text('Responder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segunda fila: Resolver y Descartar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _resolveAlert(alert['id']),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Resolver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _dismissAlert(alert['id']),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Descartar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final title = report['title']?.toString() ?? 'Sin título';
    final description = report['description']?.toString() ?? '';
    final status = report['status']?.toString() ?? '';
    final reportType = report['report_type']?.toString() ?? '';
    final locationDetails = report['location_details']?.toString() ?? 'Sin dirección';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(reportType),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getReportTypeLabel(reportType),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedItem = null;
                    _selectedType = '';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationDetails,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goToReport(report),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Ir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openReportDetail(report),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Ver Denuncia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'submitted':
        color = Colors.orange;
        text = 'Pendiente';
      case 'en_proceso':
      case 'in_progress':
      case 'inprogress':
        color = Colors.blue;
        text = 'En Proceso';
      case 'resuelto':
      case 'resolved':
        color = Colors.green;
        text = 'Resuelta';
      case 'rechazado':
      case 'rejected':
        color = Colors.red;
        text = 'Rechazada';
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'submitted':
        return Colors.orange;
      case 'en_proceso':
      case 'in_progress':
      case 'inprogress':
        return Colors.blue;
      case 'resuelto':
      case 'resolved':
        return Colors.green;
      case 'rechazado':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'complaint':
      case 'denuncia':
        return Icons.report_problem;
      case 'suggestion':
      case 'sugerencia':
        return Icons.lightbulb_outline;
      case 'emergency':
      case 'emergencia':
        return Icons.warning;
      case 'request':
      case 'solicitud':
        return Icons.assignment;
      case 'incident':
      case 'incidente':
        return Icons.error_outline;
      default:
        return Icons.description;
    }
  }

  String _getReportTypeLabel(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'complaint':
        return 'Denuncia';
      case 'suggestion':
        return 'Sugerencia';
      case 'emergency':
        return 'Emergencia';
      case 'request':
        return 'Solicitud';
      case 'incident':
        return 'Incidente';
      default:
        return reportType;
    }
  }

  Future<void> _respondToAlert(String? alertId) async {
    if (alertId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final baseUrl = ApiConfig.activeBaseUrl;

      final response = await http.patch(
        Uri.parse('$baseUrl/api/panic/$alertId/respond'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Has respondido a la alerta. ¡Acude al lugar!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh
      } else {
        final error = json.decode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Error al responder'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resolveAlert(String? alertId) async {
    if (alertId == null) return;

    final notesController = TextEditingController();
    String? selectedQuickNote;

    final notes = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final quickNotes = [
            'Situacion controlada',
            'Falsa alarma',
            'Persona asistida y fuera de peligro',
            'Derivado a servicios de emergencia',
            'Problema resuelto en el lugar',
          ];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Cerrar Alerta SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Describe brevemente lo sucedido:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    // Quick note chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickNotes.map((note) {
                        final isSelected = selectedQuickNote == note;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              if (isSelected) {
                                selectedQuickNote = null;
                                notesController.clear();
                              } else {
                                selectedQuickNote = note;
                                notesController.text = note;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Text field for custom notes
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Escribe el contexto de lo sucedido...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.green, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value != selectedQuickNote) {
                            selectedQuickNote = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este registro quedara asociado a la alerta.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('Cancelar', style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final text = notesController.text.trim();
                  if (text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debes escribir un contexto antes de cerrar la alerta'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, text);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Cerrar Alerta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (notes == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final baseUrl = ApiConfig.activeBaseUrl;

      final response = await http.patch(
        Uri.parse('$baseUrl/api/panic/$alertId/resolve'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _selectedItem = null;
          _selectedType = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerta resuelta exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Refresh
      } else {
        final error = json.decode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Error al resolver la alerta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _dismissAlert(String? alertId) async {
    if (alertId == null) return;

    // Mostrar diálogo de confirmación
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedReason = '';
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.orange),
              SizedBox(width: 8),
              Text('Descartar Alerta'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el motivo para descartar esta alerta:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selectedReason,
                    onChanged: (value) => setState(() => selectedReason = value ?? ''),
                    child: Column(
                      children: ['Falsa alarma', 'Prueba del sistema', 'Error del usuario', 'Duplicada', 'Otro'].map(
                        (reason) => RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedReason.isNotEmpty ? selectedReason : 'Sin motivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Descartar'),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final baseUrl = ApiConfig.activeBaseUrl;

      final response = await http.patch(
        Uri.parse('$baseUrl/api/panic/$alertId/dismiss'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _selectedItem = null;
          _selectedType = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta descartada: $reason'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData(); // Refresh
      } else {
        final error = json.decode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Error al descartar la alerta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
