// lib/features/admin/presentation/pages/admin_personnel_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';

/// Pantalla de gestión de personal (CRUD de usuarios) para administradores.
class AdminPersonnelScreen extends StatefulWidget {
  final UserEntity user;

  const AdminPersonnelScreen({super.key, required this.user});

  @override
  State<AdminPersonnelScreen> createState() => _AdminPersonnelScreenState();
}

class _AdminPersonnelScreenState extends State<AdminPersonnelScreen>
    with TickerProviderStateMixin {
  // ───────────────────────────── State
  List<_PersonnelUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _roleFilter = 'all'; // all | admin | inspector | citizen
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ───────────────────────────── Animations
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });

    _loadUsers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Data loading
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.get(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users'),
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> rawList = decoded is List
            ? decoded
            : (decoded is Map<String, dynamic> && decoded['data'] is List
                ? decoded['data'] as List
                : const []);
        final parsed = rawList
            .whereType<Map<String, dynamic>>()
            .map(_PersonnelUser.fromJson)
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970)));

        if (!mounted) return;
        setState(() {
          _users = parsed;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Error al cargar usuarios (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo conectar con el servidor';
        _isLoading = false;
      });
    }
  }

  Future<bool> _toggleStatus(_PersonnelUser user) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users/${user.id}/toggle-status'),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _updateRole(_PersonnelUser user, String newRole) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users/${user.id}'),
        body: jsonEncode({'role': newRole}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _changePassword(_PersonnelUser user, String newPassword) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.patch(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users/${user.id}/password'),
        body: jsonEncode({'password': newPassword}),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteUser(_PersonnelUser user) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.delete(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users/${user.id}'),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<({bool ok, String? error})> _createUser(Map<String, dynamic> body) async {
    try {
      final client = di.sl<AuthHttpClient>();
      final response = await client.post(
        Uri.parse('${ApiConfig.activeBaseUrl}/api/users'),
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (ok: true, error: null);
      }
      String? msg;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message']?.toString() ?? decoded['error']?.toString();
        }
      } catch (_) {}
      return (ok: false, error: msg ?? 'Error ${response.statusCode}');
    } catch (_) {
      return (ok: false, error: 'Error de conexión');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Filtering
  // ═══════════════════════════════════════════════════════════════════════

  List<_PersonnelUser> get _filteredUsers {
    return _users.where((u) {
      if (_roleFilter != 'all' && u.role.toLowerCase() != _roleFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final haystack =
            '${u.fullName} ${u.email}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();
  }

  int get _totalCount => _users.length;
  int get _adminCount =>
      _users.where((u) => u.role.toLowerCase() == 'admin').length;
  int get _inspectorCount =>
      _users.where((u) => u.role.toLowerCase() == 'inspector').length;
  int get _citizenCount =>
      _users.where((u) => u.role.toLowerCase() == 'citizen').length;
  int get _activeCount => _users.where((u) => u.isActive).length;

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.neonGlow,
        ),
        child: FloatingActionButton.extended(
          onPressed: _openCreateUserModal,
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textOnPrimary,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Nuevo usuario',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              SliverToBoxAdapter(child: _buildFilterBar()),
              if (_isLoading)
                SliverToBoxAdapter(child: _buildSkeleton())
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildErrorState(),
                )
              else if (_filteredUsers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _StaggeredItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUserCard(user),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
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
                const Text('Personal', style: AppTheme.headlineSmall),
                Text(
                  'Gestión de usuarios y roles',
                  style: AppTheme.labelSmall
                      .copyWith(color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onTap: _isLoading ? null : _loadUsers,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: AnimatedRotation(
                  turns: _isLoading ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: AppTheme.primaryDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.borderLight,
        highlightColor: AppTheme.surfaceWhite,
        child: Column(
          children: List.generate(
            5,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 82,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stats row ─────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip(
              label: 'Total',
              count: _totalCount,
              color: AppTheme.textPrimary,
              icon: Icons.people_outline,
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              label: 'Admins',
              count: _adminCount,
              color: AppTheme.emergency,
              icon: Icons.shield_outlined,
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              label: 'Inspectores',
              count: _inspectorCount,
              color: AppTheme.info,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              label: 'Ciudadanos',
              count: _citizenCount,
              color: AppTheme.primary,
              icon: Icons.person_outline,
            ),
            const SizedBox(width: 10),
            _buildStatChip(
              label: 'Activos',
              count: _activeCount,
              color: AppTheme.success,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter bar ───────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: AppTheme.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoleFilterChip('all', 'Todos', Icons.groups_outlined),
                const SizedBox(width: 8),
                _buildRoleFilterChip('admin', 'Admin', Icons.shield_outlined),
                const SizedBox(width: 8),
                _buildRoleFilterChip(
                    'inspector', 'Inspector', Icons.badge_outlined),
                const SizedBox(width: 8),
                _buildRoleFilterChip(
                    'citizen', 'Ciudadano', Icons.person_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String value, String label, IconData icon) {
    final isSelected = _roleFilter == value;
    final color = value == 'all' ? AppTheme.primary : _roleColor(value);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        onTap: () => setState(() => _roleFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color.withValues(alpha: 0.95), color],
                  )
                : null,
            color: isSelected ? null : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusRound),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.border.withValues(alpha: 0.6),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── User card ────────────────────────────────────────────────────────

  Widget _buildUserCard(_PersonnelUser user) {
    final role = user.role.toLowerCase();
    final roleColor = _roleColor(role);
    final roleLabel = _roleLabel(role);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUserDetail(user),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 4, color: roleColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    children: [
                      _buildAvatar(user, roleColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : 'Sin nombre',
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.alternate_email_rounded,
                                    size: 11,
                                    color: AppTheme.textTertiary
                                        .withValues(alpha: 0.7)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildRoleBadge(roleLabel, roleColor),
                                const SizedBox(width: 6),
                                _buildStatusPill(user.isActive),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textTertiary
                              .withValues(alpha: 0.7),
                          size: 20),
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

  Widget _buildAvatar(_PersonnelUser user, Color color) {
    final initials = _computeInitials(user.fullName, user.email);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isActive) {
    final color = isActive ? AppTheme.success : AppTheme.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty / Error states ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.people_alt_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin resultados',
              style: AppTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _users.isEmpty
                  ? 'Aún no hay usuarios registrados.\nCrea el primero con el botón "Nuevo usuario".'
                  : 'Ningún usuario coincide con los filtros.\nPrueba ajustando la búsqueda o el rol.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall
                  .copyWith(color: AppTheme.textSecondary),
            ),
            if (_users.isEmpty) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openCreateUserModal,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Crear usuario'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.emergencyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppTheme.emergency,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sin conexión', style: AppTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall
                  .copyWith(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Detail modal
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _openUserDetail(_PersonnelUser user) async {
    final refresh = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UserDetailSheet(
        user: user,
        currentAdmin: widget.user,
        onToggleStatus: () => _toggleStatus(user),
        onUpdateRole: (role) => _updateRole(user, role),
        onChangePassword: (password) => _changePassword(user, password),
        onDelete: () => _deleteUser(user),
      ),
    );
    if (refresh == true) {
      _loadUsers();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Create user modal
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _openCreateUserModal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateUserSheet(onSubmit: _createUser),
    );
    if (created == true) {
      _loadUsers();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════

  static Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.emergency;
      case 'inspector':
        return AppTheme.info;
      case 'citizen':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  static String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'ADMIN';
      case 'inspector':
        return 'INSPECTOR';
      case 'citizen':
        return 'CIUDADANO';
      default:
        return role.toUpperCase();
    }
  }

  static String _computeInitials(String name, String email) {
    final base = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (base.isEmpty) return '?';
    final parts = base.split(RegExp(r'[\s@]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return base[0].toUpperCase();
    if (parts.length == 1) {
      final p = parts[0];
      return p.length >= 2
          ? p.substring(0, 2).toUpperCase()
          : p[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Detail sheet
// ═════════════════════════════════════════════════════════════════════════

class _UserDetailSheet extends StatefulWidget {
  final _PersonnelUser user;
  final UserEntity currentAdmin;
  final Future<bool> Function() onToggleStatus;
  final Future<bool> Function(String role) onUpdateRole;
  final Future<bool> Function(String password) onChangePassword;
  final Future<bool> Function() onDelete;

  const _UserDetailSheet({
    required this.user,
    required this.currentAdmin,
    required this.onToggleStatus,
    required this.onUpdateRole,
    required this.onChangePassword,
    required this.onDelete,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  late _PersonnelUser _user;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.emergency : AppTheme.success,
      ),
    );
  }

  Future<void> _handleToggle() async {
    setState(() => _busy = true);
    final ok = await widget.onToggleStatus();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _user = _user.copyWith(isActive: !_user.isActive);
    });
    _showSnack(
      ok
          ? (_user.isActive ? 'Usuario activado' : 'Usuario desactivado')
          : 'No se pudo actualizar el estado',
      error: !ok,
    );
  }

  Future<void> _handleChangeRole() async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String selected = _user.role.toLowerCase();
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar rol'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roleRadio('admin', 'Administrador', selected,
                      (v) => setDialogState(() => selected = v)),
                  _roleRadio('inspector', 'Inspector', selected,
                      (v) => setDialogState(() => selected = v)),
                  _roleRadio('citizen', 'Ciudadano', selected,
                      (v) => setDialogState(() => selected = v)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(selected),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newRole == null || newRole == _user.role.toLowerCase()) return;

    setState(() => _busy = true);
    final ok = await widget.onUpdateRole(newRole);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _user = _user.copyWith(role: newRole);
    });
    _showSnack(
      ok ? 'Rol actualizado' : 'No se pudo actualizar el rol',
      error: !ok,
    );
  }

  Widget _roleRadio(
    String value,
    String label,
    String groupValue,
    ValueChanged<String> onChanged,
  ) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final controller = TextEditingController();
    bool obscure = true;
    String? errorText;

    final newPwd = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      errorText: errorText,
                      suffixIcon: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mínimo 8 caracteres',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text;
                    if (text.length < 8) {
                      setDialogState(() =>
                          errorText = 'Debe tener al menos 8 caracteres');
                      return;
                    }
                    Navigator.of(ctx).pop(text);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newPwd == null) return;

    setState(() => _busy = true);
    final ok = await widget.onChangePassword(newPwd);
    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(
      ok ? 'Contraseña actualizada' : 'No se pudo actualizar la contraseña',
      error: !ok,
    );
  }

  Future<void> _handleDelete() async {
    if (_user.id == widget.currentAdmin.id) {
      _showSnack('No puedes eliminar tu propio usuario', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que deseas eliminar a ${_user.fullName.isNotEmpty ? _user.fullName : _user.email}?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergency,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busy = true);
    final ok = await widget.onDelete();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _showSnack('Usuario eliminado');
      Navigator.of(context).pop(true);
    } else {
      _showSnack('No se pudo eliminar', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _user.role.toLowerCase();
    final roleColor = _AdminPersonnelScreenState._roleColor(role);
    final roleLabel = _AdminPersonnelScreenState._roleLabel(role);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  roleColor.withValues(alpha: 0.8),
                                  roleColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _AdminPersonnelScreenState._computeInitials(
                                _user.fullName,
                                _user.email,
                              ),
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user.fullName.isNotEmpty
                                      ? _user.fullName
                                      : 'Sin nombre',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user.email,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            roleColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusRound),
                                        border: Border.all(
                                          color:
                                              roleColor.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        roleLabel,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: roleColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (_user.isActive
                                                ? AppTheme.success
                                                : AppTheme.textTertiary)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusRound),
                                      ),
                                      child: Text(
                                        _user.isActive ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _user.isActive
                                              ? AppTheme.success
                                              : AppTheme.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fields
                      _buildInfoTile(Icons.badge_outlined, 'RUT',
                          _user.rut ?? 'No registrado'),
                      _buildInfoTile(Icons.phone_outlined, 'Teléfono',
                          _user.phone ?? 'No registrado'),
                      _buildInfoTile(
                        Icons.calendar_today_outlined,
                        'Registrado',
                        _user.createdAt != null
                            ? _formatDate(_user.createdAt!)
                            : 'Desconocido',
                      ),
                      _buildInfoTile(
                        Icons.fingerprint,
                        'ID',
                        _user.id,
                        monospace: true,
                      ),

                      const SizedBox(height: 20),

                      // Actions
                      _buildActionButton(
                        icon: _user.isActive
                            ? Icons.block_outlined
                            : Icons.check_circle_outline,
                        label:
                            _user.isActive ? 'Desactivar' : 'Activar',
                        color: _user.isActive
                            ? AppTheme.warning
                            : AppTheme.success,
                        onTap: _busy ? null : _handleToggle,
                      ),
                      const SizedBox(height: 10),
                      _buildActionButton(
                        icon: Icons.swap_horiz,
                        label: 'Cambiar rol',
                        color: AppTheme.info,
                        onTap: _busy ? null : _handleChangeRole,
                      ),
                      const SizedBox(height: 10),
                      _buildActionButton(
                        icon: Icons.lock_outline,
                        label: 'Cambiar contraseña',
                        color: AppTheme.primary,
                        onTap: _busy ? null : _handleChangePassword,
                      ),
                      const SizedBox(height: 10),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Eliminar usuario',
                        color: AppTheme.emergency,
                        onTap: _busy ? null : _handleDelete,
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 16),
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value,
      {bool monospace = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily:
                        monospace ? 'monospace' : AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Create user sheet
// ═════════════════════════════════════════════════════════════════════════

class _CreateUserSheet extends StatefulWidget {
  final Future<({bool ok, String? error})> Function(Map<String, dynamic> body)
      onSubmit;

  const _CreateUserSheet({required this.onSubmit});

  @override
  State<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends State<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _role = 'inspector';
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _rutCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Requerido';
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(v)) return 'Email no válido';
    return null;
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Requerido';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Requerido';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final body = <String, dynamic>{
      'email': _emailCtrl.text.trim(),
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'rut': _rutCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'role': _role,
      'password': _passwordCtrl.text,
    };

    final result = await widget.onSubmit(body);
    if (!mounted) return;

    setState(() => _submitting = false);

    if (result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario creado'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al crear usuario'),
          backgroundColor: AppTheme.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXLarge),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Crear nuevo usuario',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _firstNameCtrl,
                                label: 'Nombre',
                                icon: Icons.person_outline,
                                validator: _validateRequired,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _lastNameCtrl,
                                label: 'Apellido',
                                icon: Icons.person_outline,
                                validator: _validateRequired,
                              ),
                            ),
                          ],
                        ),
                        _buildField(
                          controller: _rutCtrl,
                          label: 'RUT',
                          icon: Icons.badge_outlined,
                        ),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        _buildRoleSelector(),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _passwordCtrl,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscureText: _obscure,
                          validator: _validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        const Text(
                          'Mínimo 8 caracteres',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium),
                            ),
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(_submitting
                              ? 'Creando...'
                              : 'Crear usuario'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          if (label == 'Email')
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rol',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _rolePill(
                  value: 'inspector',
                  label: 'Inspector',
                  icon: Icons.badge_outlined,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _rolePill(
                  value: 'admin',
                  label: 'Administrador',
                  icon: Icons.shield_outlined,
                  color: AppTheme.emergency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rolePill({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Staggered animation wrapper
// ═════════════════════════════════════════════════════════════════════════

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 60 * widget.index.clamp(0, 10));
    Future.delayed(delay, () {
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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Model
// ═════════════════════════════════════════════════════════════════════════

class _PersonnelUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? rut;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const _PersonnelUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.rut,
    this.phone,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }

  _PersonnelUser copyWith({
    String? role,
    bool? isActive,
  }) {
    return _PersonnelUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      rut: rut,
      phone: phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  factory _PersonnelUser.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['created_at'] ?? json['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final lower = v.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 't';
      }
      return true;
    }

    return _PersonnelUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? json['firstName'] ?? '').toString(),
      lastName: (json['last_name'] ?? json['lastName'] ?? '').toString(),
      rut: (json['rut'] as String?)?.trim().isEmpty == true
          ? null
          : json['rut'] as String?,
      phone: (json['phone'] as String?)?.trim().isEmpty == true
          ? null
          : json['phone'] as String?,
      role: (json['role'] ?? 'citizen').toString(),
      isActive: parseBool(json['is_active'] ?? json['isActive']),
      createdAt: parsedDate,
    );
  }
}

// Prevent unused import warning when http package isn't referenced directly.
// ignore: unused_element
typedef _HttpClientAlias = http.Client;
