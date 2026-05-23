// lib/features/admin/presentation/pages/admin_fleet_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../services/export_service.dart';
import 'route_playback_screen.dart';

/// Fleet management screen for admins.
/// Two tabs: Vehicles and Logs (bitacoras).
class AdminFleetScreen extends StatefulWidget {
  final UserEntity user;

  const AdminFleetScreen({super.key, required this.user});

  @override
  State<AdminFleetScreen> createState() => _AdminFleetScreenState();
}

class _AdminFleetScreenState extends State<AdminFleetScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Vehicles state
  List<Map<String, dynamic>> _vehicles = [];
  bool _loadingVehicles = false;
  String? _vehiclesError;

  // Logs state
  List<Map<String, dynamic>> _logs = [];
  bool _loadingLogs = false;
  String? _logsError;

  // Filter for logs: 'active' | 'completed' | 'all'
  String _logsFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _loadVehicles();
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadVehicles() async {
    setState(() {
      _loadingVehicles = true;
      _vehiclesError = null;
    });
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles'),
      );
      if (res.statusCode >= 400) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final decoded = json.decode(res.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['data'] as List?) ?? (decoded['vehicles'] as List?) ?? const [];
      } else {
        list = const [];
      }
      if (!mounted) return;
      setState(() {
        _vehicles = list.whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
          // Normalize: API has is_active + active_log_id, derive a status
          if (m['status'] == null) {
            if (m['active_log_id'] != null) {
              m['status'] = 'in_use';
            } else if (m['is_active'] == true) {
              m['status'] = 'available';
            } else {
              m['status'] = 'out_of_service';
            }
          }
          return m;
        }).toList();
        _loadingVehicles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehiclesError = e.toString();
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _loadingLogs = true;
      _logsError = null;
    });
    try {
      final client = di.sl<AuthHttpClient>();
      List<Map<String, dynamic>>? logs;

      // Use the admin endpoint /logs (returns all logs)
      try {
        final res = await client.get(
          Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/logs'),
        );
        if (res.statusCode < 400) {
          logs = _extractLogs(res.body);
        }
      } catch (_) {/* fall through */}

      // Fallback: iterate vehicles
      if (logs == null) {
        logs = [];
        final vehicles = _vehicles.isNotEmpty
            ? _vehicles
            : await _fetchVehiclesForLogs();
        for (final v in vehicles) {
          final vid = v['id'];
          if (vid == null) continue;
          try {
            final res = await client.get(
              Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/$vid/logs'),
            );
            if (res.statusCode < 400) {
              final extracted = _extractLogs(res.body);
              // Attach plate for display
              for (final l in extracted) {
                l['plate'] ??= v['plate'];
                l['vehicle_plate'] ??= v['plate'];
              }
              logs.addAll(extracted);
            }
          } catch (_) {/* skip */}
        }
      }

      if (!mounted) return;
      setState(() {
        _logs = logs!;
        _loadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLogs = false;
        _logsError = e.toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchVehiclesForLogs() async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles'),
      );
      if (res.statusCode >= 400) return [];
      final decoded = json.decode(res.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        list = (decoded['data'] as List?) ?? (decoded['vehicles'] as List?) ?? const [];
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _extractLogs(String body) {
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) {
      final l = decoded['logs'] ?? decoded['data'] ?? decoded['items'];
      if (l is List) {
        return l
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_logsFilter == 'all') return _logs;
    return _logs.where((l) {
      final status = (l['status'] ?? '').toString().toLowerCase();
      if (_logsFilter == 'active') {
        return status == 'active' || l['end_time'] == null;
      }
      if (_logsFilter == 'completed') {
        return status == 'completed' || l['end_time'] != null;
      }
      return true;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _createVehicle(Map<String, dynamic> body) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.post(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles'),
        body: json.encode(body),
      );
      if (res.statusCode >= 400) {
        _showSnack('Error al crear: ${res.statusCode} ${res.body}', isError: true);
        return false;
      }
      _showSnack('Vehiculo creado');
      await _loadVehicles();
      return true;
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      return false;
    }
  }

  Future<bool> _updateVehicle(String id, Map<String, dynamic> body) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/$id'),
        body: json.encode(body),
      );
      if (res.statusCode >= 400) {
        _showSnack('Error al actualizar: ${res.statusCode} ${res.body}', isError: true);
        return false;
      }
      _showSnack('Vehiculo actualizado');
      await _loadVehicles();
      return true;
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      return false;
    }
  }

  Future<bool> _deleteVehicle(String id) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final res = await client.delete(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/vehicles/$id'),
      );
      if (res.statusCode >= 400) {
        _showSnack('Error al eliminar: ${res.statusCode} ${res.body}', isError: true);
        return false;
      }
      _showSnack('Vehiculo eliminado');
      await _loadVehicles();
      return true;
    } catch (e) {
      _showSnack('Error: $e', isError: true);
      return false;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.emergency : AppTheme.primaryDark,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSectionHeader(),
            _buildTabSegment(),
            const SizedBox(height: AppTheme.spacing8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVehiclesTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: AppTheme.neonGlow,
              ),
              child: FloatingActionButton.extended(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nuevo vehículo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _openCreateVehicleModal,
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader() {
    final isLogs = _tabController.index == 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradientVertical,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Flota Vehicular', style: AppTheme.headlineSmall),
                Text(
                  isLogs
                      ? '${_filteredLogs.length} bitácoras registradas'
                      : '${_vehicles.length} vehículos en el sistema',
                  style: AppTheme.labelSmall
                      .copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          if (isLogs)
            _HeaderIconButton(
              icon: Icons.ios_share_rounded,
              tooltip: 'Exportar CSV',
              onTap: _exportLogsCsv,
            ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Recargar',
            onTap: () {
              if (_tabController.index == 0) {
                _loadVehicles();
              } else {
                _loadLogs();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegment() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _segmentTab(
                index: 0,
                label: 'Vehículos',
                icon: Icons.directions_car_rounded,
              ),
            ),
            Expanded(
              child: _segmentTab(
                index: 1,
                label: 'Bitácoras',
                icon: Icons.route_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentTab({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final selected = _tabController.index == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VEHICLES TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVehiclesTab() {
    if (_loadingVehicles && _vehicles.isEmpty) {
      return _buildSkeleton();
    }
    if (_vehiclesError != null && _vehicles.isEmpty) {
      return _buildErrorState(_vehiclesError!, _loadVehicles);
    }
    if (_vehicles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_car_outlined,
        title: 'Sin vehículos',
        subtitle:
            'Agrega el primer vehículo de la flota con el botón "Nuevo vehículo"',
        action: ElevatedButton.icon(
          onPressed: _openCreateVehicleModal,
          icon: const Icon(Icons.add),
          label: const Text('Crear vehículo'),
        ),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadVehicles,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _vehicles.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
        itemBuilder: (context, index) {
          final v = _vehicles[index];
          return _AnimatedListItem(
            index: index,
            child: _buildVehicleCard(v),
          );
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    final plate = (v['plate'] ?? '').toString().toUpperCase();
    final brand = (v['brand'] ?? '').toString();
    final model = (v['model'] ?? '').toString();
    final year = v['year']?.toString() ?? '';
    final type = (v['type'] ?? '').toString();
    final status = (v['status'] ?? '').toString();
    final km = v['currentKm'] ?? v['current_km'];
    final driver = (v['active_driver_name'] ?? '').toString();
    final activeLogId = v['active_log_id'];
    final isActive = activeLogId != null;

    final statusColor = _statusColor(status);
    final statusBg = _statusBg(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => _openEditVehicleModal(v),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.border.withValues(alpha: 0.7),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : AppTheme.shadowSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: statusColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusBg,
                              statusColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                              color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          _typeIcon(type),
                          color: statusColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    plate.isEmpty ? '(Sin patente)' : plate,
                                    style: AppTheme.titleLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                _statusPill(status, statusColor, statusBg),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [brand, model, year]
                                  .where((s) => s.isNotEmpty)
                                  .join(' '),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spacing8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (km != null)
                                  _miniChip(Icons.speed_rounded, '$km km'),
                                if (driver.isNotEmpty)
                                  _miniChip(Icons.person_rounded, driver,
                                      color: AppTheme.primary),
                                if (isActive)
                                  _miniChip(
                                      Icons.play_circle_fill_rounded, 'En ruta',
                                      color: AppTheme.success),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textTertiary.withValues(alpha: 0.6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, {Color? color}) {
    final c = color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(text,
              style: AppTheme.labelSmall.copyWith(
                  color: c, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppTheme.borderLight,
      highlightColor: AppTheme.surfaceWhite,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 104,
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // LOGS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLogsTab() {
    return Column(
      children: [
        _buildLogsFilter(),
        Expanded(child: _buildLogsList()),
      ],
    );
  }

  Widget _buildLogsFilter() {
    final filters = <({String value, String label, IconData icon, Color color})>[
      (value: 'all', label: 'Todos', icon: Icons.all_inclusive_rounded, color: AppTheme.textSecondary),
      (value: 'active', label: 'Activos', icon: Icons.play_circle_fill_rounded, color: AppTheme.success),
      (value: 'completed', label: 'Completados', icon: Icons.check_circle_rounded, color: AppTheme.info),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final selected = _logsFilter == f.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusRound),
                        onTap: () => setState(() => _logsFilter = f.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? f.color.withValues(alpha: 0.12)
                                : AppTheme.surfaceWhite,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusRound),
                            border: Border.all(
                              color: selected
                                  ? f.color.withValues(alpha: 0.4)
                                  : AppTheme.border.withValues(alpha: 0.7),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(f.icon,
                                  size: 14,
                                  color: selected
                                      ? f.color
                                      : AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                f.label,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? f.color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            ),
            child: Text('${_filteredLogs.length}',
                style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList() {
    if (_loadingLogs && _logs.isEmpty) {
      return _buildSkeleton();
    }
    if (_logsError != null && _logs.isEmpty) {
      return _buildErrorState(_logsError!, _loadLogs);
    }
    final items = _filteredLogs;
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.route_outlined,
        title: 'Sin bitácoras',
        subtitle: 'No hay registros con este filtro.\nAjusta el filtro o recarga.',
      );
    }
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadLogs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing12),
        itemBuilder: (context, index) {
          final log = items[index];
          return _AnimatedListItem(
            index: index,
            child: _buildLogCard(log),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final status = (log['status'] ?? '').toString().toLowerCase();
    final isActive = status == 'active' || log['end_time'] == null;

    final plate = (log['plate'] ??
            log['vehicle_plate'] ??
            log['vehiclePlate'] ??
            '')
        .toString()
        .toUpperCase();
    final driver = (log['driver_name'] ??
            log['driverName'] ??
            log['user_name'] ??
            '')
        .toString();
    final start = _parseDate(log['start_time'] ?? log['startTime']);
    final end = _parseDate(log['end_time'] ?? log['endTime']);

    final startLabel = start != null
        ? DateFormat('dd MMM · HH:mm').format(start)
        : '--';
    final duration = _formatDuration(start, end);
    final distance = _formatDistance(log);

    final color = isActive ? AppTheme.success : AppTheme.info;
    final bg = isActive ? AppTheme.successLight : AppTheme.infoLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        onTap: () => _openRoutePlayback(log),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.4)
                  : AppTheme.border.withValues(alpha: 0.7),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppTheme.shadowSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: color),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusRound),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive)
                                  _PulseDot(color: color)
                                else
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                        color: color, shape: BoxShape.circle),
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'EN RUTA' : 'COMPLETADO',
                                  style: AppTheme.labelSmall.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plate.isEmpty ? '—' : plate,
                              style: AppTheme.titleSmall.copyWith(
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_rounded,
                                size: 14, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              driver.isEmpty ? 'Sin conductor' : driver,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _miniChip(Icons.schedule_rounded, startLabel),
                          _miniChip(Icons.timer_rounded, duration,
                              color: AppTheme.warning),
                          _miniChip(Icons.route_rounded, distance,
                              color: AppTheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODALS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _openCreateVehicleModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => _VehicleFormSheet(
        onSubmit: (body) async {
          final ok = await _createVehicle(body);
          if (ok && ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _openEditVehicleModal(Map<String, dynamic> vehicle) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXLarge)),
      ),
      builder: (ctx) => _VehicleFormSheet(
        initial: vehicle,
        onSubmit: (body) async {
          final id = vehicle['id']?.toString() ?? '';
          final ok = await _updateVehicle(id, body);
          if (ok && ctx.mounted) Navigator.of(ctx).pop();
        },
        onDelete: () async {
          final confirmed = await _confirmDelete();
          if (!confirmed) return;
          final id = vehicle['id']?.toString() ?? '';
          final ok = await _deleteVehicle(id);
          if (ok && ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar vehiculo'),
        content: const Text('Esta accion no se puede deshacer. Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.emergency),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _openRoutePlayback(Map<String, dynamic> log) {
    final id = (log['id'] ?? '').toString();
    if (id.isEmpty) {
      _showSnack('Bitacora sin ID, no se puede reproducir', isError: true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePlaybackScreen(
          vehicleLogId: id,
          plate: (log['vehicle_plate'] ?? log['plate'])?.toString(),
          driverName: log['driver_name']?.toString(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _exportLogsCsv() async {
    final items = _filteredLogs;
    if (items.isEmpty) {
      _showSnack('No hay bitacoras para exportar', isError: true);
      return;
    }
    final rows = items.map((l) {
      final start = _parseDate(l['start_time'] ?? l['startTime']);
      final end = _parseDate(l['end_time'] ?? l['endTime']);
      final fmt = DateFormat('dd/MM/yyyy HH:mm');
      final status = (l['status'] ?? '').toString().toLowerCase();
      final isActive = status == 'active' || l['end_time'] == null;
      return <dynamic>[
        (l['plate'] ?? l['vehicle_plate'] ?? '').toString(),
        (l['driver_name'] ?? l['driverName'] ?? l['user_name'] ?? '').toString(),
        start != null ? fmt.format(start) : '',
        end != null ? fmt.format(end) : '',
        (l['start_km'] ?? l['startKm'] ?? '').toString(),
        (l['end_km'] ?? l['endKm'] ?? '').toString(),
        _formatDistance(l),
        isActive ? 'Activo' : 'Completado',
      ];
    }).toList();

    try {
      await ExportService.exportCsv(
        filenamePrefix: 'bitacoras',
        headers: const [
          'Patente',
          'Conductor',
          'Inicio',
          'Fin',
          'Km inicial',
          'Km final',
          'Distancia',
          'Estado',
        ],
        rows: rows,
      );
    } catch (e) {
      _showSnack('Error al exportar: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.emergency),
            const SizedBox(height: AppTheme.spacing16),
            const Text(
              'Error al cargar',
              style: AppTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: c.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.18),
                          AppTheme.accent.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 54, color: AppTheme.primary),
                  ),
                  const SizedBox(height: AppTheme.spacing20),
                  Text(title, style: AppTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (action != null) ...[
                    const SizedBox(height: AppTheme.spacing20),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.success;
      case 'in_use':
        return AppTheme.info;
      case 'maintenance':
        return AppTheme.warning;
      case 'out_of_service':
        return AppTheme.emergency;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.successLight;
      case 'in_use':
        return AppTheme.infoLight;
      case 'maintenance':
        return AppTheme.warningLight;
      case 'out_of_service':
        return AppTheme.emergencyLight;
      default:
        return AppTheme.borderLight;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Disponible';
      case 'in_use':
        return 'En uso';
      case 'maintenance':
        return 'Mantencion';
      case 'out_of_service':
        return 'Fuera de servicio';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      case 'van':
        return Icons.airport_shuttle;
      case 'bicycle':
        return Icons.pedal_bike;
      default:
        return Icons.directions_car;
    }
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatDuration(DateTime? start, DateTime? end) {
    if (start == null) return '--';
    final to = end ?? DateTime.now();
    final diff = to.difference(start);
    if (diff.isNegative) return '--';
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatDistance(Map<String, dynamic> log) {
    final dist = log['distance'] ?? log['distance_km'] ?? log['distanceKm'];
    if (dist != null) {
      final n = double.tryParse(dist.toString());
      if (n != null) return '${n.toStringAsFixed(1)} km';
      return '$dist km';
    }
    final sk = double.tryParse((log['start_km'] ?? log['startKm'] ?? '').toString());
    final ek = double.tryParse((log['end_km'] ?? log['endKm'] ?? '').toString());
    if (sk != null && ek != null) {
      final d = (ek - sk).clamp(0, double.infinity);
      return '${d.toStringAsFixed(1)} km';
    }
    return '-- km';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PULSE DOT
// ═══════════════════════════════════════════════════════════════════════════

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final v = _ctl.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * (1 - v)),
                blurRadius: 6 * v,
                spreadRadius: 3 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER ICON BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppTheme.primaryDark),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED LIST ITEM
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 10)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VEHICLE FORM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _VehicleFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;
  final Future<void> Function()? onDelete;

  const _VehicleFormSheet({
    this.initial,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();

  String _type = 'car';
  String _status = 'available';
  bool _submitting = false;

  static const List<DropdownMenuItem<String>> _typeItems = [
    DropdownMenuItem(value: 'car', child: Text('Auto')),
    DropdownMenuItem(value: 'motorcycle', child: Text('Motocicleta')),
    DropdownMenuItem(value: 'truck', child: Text('Camion')),
    DropdownMenuItem(value: 'van', child: Text('Furgon')),
    DropdownMenuItem(value: 'bicycle', child: Text('Bicicleta')),
  ];

  static const List<DropdownMenuItem<String>> _statusItems = [
    DropdownMenuItem(value: 'available', child: Text('Disponible')),
    DropdownMenuItem(value: 'in_use', child: Text('En uso')),
    DropdownMenuItem(value: 'maintenance', child: Text('Mantencion')),
    DropdownMenuItem(value: 'out_of_service', child: Text('Fuera de servicio')),
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    if (v != null) {
      _plateCtrl.text = (v['plate'] ?? '').toString();
      _brandCtrl.text = (v['brand'] ?? '').toString();
      _modelCtrl.text = (v['model'] ?? '').toString();
      _yearCtrl.text = v['year']?.toString() ?? '';
      _colorCtrl.text = (v['color'] ?? '').toString();
      _kmCtrl.text = (v['currentKm'] ?? v['current_km'] ?? '').toString();
      final t = (v['type'] ?? '').toString();
      if (['car', 'motorcycle', 'truck', 'van', 'bicycle'].contains(t)) {
        _type = t;
      }
      final s = (v['status'] ?? '').toString();
      if (['available', 'in_use', 'maintenance', 'out_of_service'].contains(s)) {
        _status = s;
      }
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final body = <String, dynamic>{
      'plate': _plateCtrl.text.trim().toUpperCase(),
      'brand': _brandCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'type': _type,
      'status': _status,
    };
    final year = int.tryParse(_yearCtrl.text.trim());
    if (year != null) body['year'] = year;
    if (_colorCtrl.text.trim().isNotEmpty) {
      body['color'] = _colorCtrl.text.trim();
    }
    final km = int.tryParse(_kmCtrl.text.trim());
    if (km != null) body['currentKm'] = km;

    await widget.onSubmit(body);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollCtrl) {
          return SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEdit ? 'Editar vehiculo' : 'Nuevo vehiculo',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _plateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patente *',
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Marca *',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Modelo *',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _yearCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ano',
                            prefixIcon: Icon(Icons.event),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _kmCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Km',
                            prefixIcon: Icon(Icons.speed),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _typeItems,
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      prefixIcon: Icon(Icons.circle),
                    ),
                    items: _statusItems,
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _handleSubmit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(isEdit ? Icons.save : Icons.add),
                      label: Text(isEdit ? 'Guardar cambios' : 'Crear vehiculo'),
                    ),
                  ),
                  if (isEdit && widget.onDelete != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.emergency,
                        side: const BorderSide(color: AppTheme.emergency),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submitting ? null : widget.onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar vehiculo'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

