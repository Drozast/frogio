// lib/features/auth/presentation/pages/edit_profile_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class EditProfileScreen extends StatefulWidget {
  final UserEntity user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rutController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late AuthRepository _authRepository;

  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isEditing = false;
  UserEntity? _updatedUser;
  File? _localImageFile;

  bool get _isInspectorOrAdmin =>
      widget.user.role == 'inspector' || widget.user.role == 'admin';
  UserEntity get _currentUser => _updatedUser ?? widget.user;

  @override
  void initState() {
    super.initState();
    _authRepository = di.sl<AuthRepository>();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _rutController = TextEditingController(text: widget.user.rut ?? '');
    _phoneController = TextEditingController(
      text: _cleanPhoneNumber(widget.user.phoneNumber ?? ''),
    );
    _addressController =
        TextEditingController(text: widget.user.address ?? '');
    _updatedUser = widget.user;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  String _cleanPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('569') && cleaned.length > 9) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('56') && cleaned.length > 9) {
      cleaned = cleaned.substring(2);
    }
    if (cleaned.length <= 1) return cleaned;
    if (cleaned.length <= 5) {
      return '${cleaned.substring(0, 1)} ${cleaned.substring(1)}';
    }
    if (cleaned.length <= 9) {
      return '${cleaned.substring(0, 1)} ${cleaned.substring(1, 5)} ${cleaned.substring(5)}';
    }
    return cleaned.substring(0, 9);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHero(),
                  collapseMode: CollapseMode.pin,
                ),
                title: const Text('Mi Perfil',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                actions: [
                  // Toggle edit/view
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      key: ValueKey(_isEditing),
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                      tooltip: _isEditing ? 'Cancelar' : 'Editar',
                    ),
                  ),
                ],
              ),

              // Body
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      children: [
                        _animatedSection(0, _buildInfoSection()),
                        const SizedBox(height: 20),
                        _animatedSection(1, _buildContactSection()),
                        const SizedBox(height: 20),
                        _animatedSection(2, _buildAccountSection()),
                        if (_isEditing) ...[
                          const SizedBox(height: 28),
                          _animatedSection(3, _buildSaveButton()),
                        ],
                        const SizedBox(height: 20),
                        _animatedSection(4, _buildPrivacySection()),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STAGGER ANIMATION
  // ---------------------------------------------------------------------------

  Widget _animatedSection(int index, Widget child) {
    final delay = (index * 0.2).clamp(0.0, 0.6);
    final end = (delay + 0.5).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(delay, end, curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, 40 * (1 - curve.value)),
        child: Opacity(opacity: curve.value, child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO SECTION
  // ---------------------------------------------------------------------------

  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final pulse = _pulseController.value;
        return Container(
          decoration: const BoxDecoration(gradient: AppTheme.accentGradient),
          child: Stack(
            children: [
              // Neon sparkles
              _neonOrb(left: 15, top: 70, size: 80, pulse: pulse),
              _neonOrb(right: 20, top: 55, size: 50, pulse: pulse),
              _neonOrb(left: 70, bottom: 30, size: 35, pulse: pulse),
              _neonOrb(right: 60, bottom: 60, size: 65, pulse: pulse),
              _neonOrb(left: 180, top: 45, size: 25, pulse: pulse),
              _neonOrb(right: 140, top: 110, size: 30, pulse: pulse),
              _neonOrb(left: 120, top: 75, size: 18, pulse: pulse),
              _neonOrb(right: 100, bottom: 100, size: 22, pulse: pulse),

              // Content
              SafeArea(
                bottom: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      _buildGlowAvatar(pulse),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        _currentUser.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Color(0x6069F0AE),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Role badge con neon
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppTheme.accent
                                .withValues(alpha: 0.3 + pulse * 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent
                                  .withValues(alpha: 0.15 + pulse * 0.2),
                              blurRadius: 12 + pulse * 8,
                              spreadRadius: pulse * 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentUser.role == 'admin'
                                  ? Icons.admin_panel_settings
                                  : _currentUser.role == 'inspector'
                                      ? Icons.shield
                                      : Icons.person,
                              color: AppTheme.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getRoleDisplayName(_currentUser.role),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _neonOrb({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required double pulse,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.accent.withValues(alpha: 0.25 + pulse * 0.2),
              AppTheme.accent.withValues(alpha: 0.0),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.2 + pulse * 0.15),
              blurRadius: size * 0.6 + pulse * size * 0.3,
              spreadRadius: pulse * size * 0.1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowAvatar(double pulse) {
    return GestureDetector(
      onTap: kIsWeb ? null : _showImagePicker,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.3 + pulse * 0.35),
              blurRadius: 28 + pulse * 16,
              spreadRadius: 4 + pulse * 6,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Outer neon ring
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.5 + pulse * 0.5),
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: _isUploadingImage
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : _buildAvatarContent(_currentUser),
                ),
              ),
            ),
            // Camera badge
            if (!kIsWeb)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarContent(UserEntity user) {
    if (_localImageFile != null) {
      return ClipOval(
        child: Image.file(_localImageFile!,
            width: 120, height: 120, fit: BoxFit.cover),
      );
    }
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      final url = user.profileImageUrl!.startsWith('file://')
          ? '${ApiConfig.activeBaseUrl}/api/files/serve/${ApiConfig.tenantId}/${user.profileImageUrl!.substring(7)}'
          : user.profileImageUrl!;
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (_, __) => const CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
          errorWidget: (_, __, ___) => _buildDefaultAvatar(user),
        ),
      );
    }
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(UserEntity user) {
    return Text(
      user.displayName.isNotEmpty
          ? user.displayName.substring(0, 1).toUpperCase()
          : '?',
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        shadows: [
          Shadow(
            color: AppTheme.accent.withValues(alpha: 0.8),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INFO SECTION (nombre, RUT)
  // ---------------------------------------------------------------------------

  Widget _buildInfoSection() {
    return _neonCard(
      icon: Icons.person_rounded,
      title: 'Informacion Personal',
      children: [
        _profileField(
          icon: Icons.badge_rounded,
          label: 'Nombre completo',
          value: _currentUser.displayName,
          controller: _nameController,
          inputFormatters: [NameFormatter()],
          validator: Validators.validateName,
        ),
        if (_isInspectorOrAdmin) ...[
          const SizedBox(height: 16),
          _profileField(
            icon: Icons.fingerprint_rounded,
            label: 'RUT',
            value: _currentUser.rut ?? 'Sin RUT',
            controller: _rutController,
            inputFormatters: [RutFormatter()],
            hint: '12.345.678-9',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Ingrese su RUT' : null,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONTACT SECTION (telefono, direccion)
  // ---------------------------------------------------------------------------

  Widget _buildContactSection() {
    return _neonCard(
      icon: Icons.phone_rounded,
      title: 'Contacto',
      children: [
        _profileField(
          icon: Icons.phone_rounded,
          label: 'Telefono',
          value: _currentUser.phoneNumber != null &&
                  _currentUser.phoneNumber!.isNotEmpty
              ? '+56 ${_cleanPhoneNumber(_currentUser.phoneNumber!)}'
              : 'Sin telefono',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneFormatter()],
          prefixText: '+56 ',
          validator: Validators.validatePhone,
        ),
        const SizedBox(height: 16),
        _profileField(
          icon: Icons.location_on_rounded,
          label: 'Direccion',
          value: _currentUser.address ?? 'Sin direccion',
          controller: _addressController,
          hint: 'Calle Los Aromos 123, Santa Juana',
          validator: Validators.validateAddress,
          maxLines: 2,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT SECTION (solo lectura)
  // ---------------------------------------------------------------------------

  Widget _buildAccountSection() {
    return _neonCard(
      icon: Icons.shield_rounded,
      title: 'Cuenta',
      children: [
        _readOnlyField(
          icon: Icons.email_rounded,
          label: 'Email',
          value: _currentUser.email,
        ),
        const SizedBox(height: 14),
        _readOnlyField(
          icon: Icons.verified_user_rounded,
          label: 'Rol',
          value: _getRoleDisplayName(_currentUser.role),
          highlight: true,
        ),
        const SizedBox(height: 14),
        _readOnlyField(
          icon: Icons.calendar_today_rounded,
          label: 'Miembro desde',
          value: _formatDate(_currentUser.createdAt),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PRIVACIDAD Y DATOS PERSONALES (Ley 21.719 / Ley 19.628)
  // ---------------------------------------------------------------------------

  Widget _buildPrivacySection() {
    return _neonCard(
      icon: Icons.privacy_tip_rounded,
      title: 'Privacidad y datos personales',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Frogio cumple con la Ley N° 21.719 y la Ley N° 19.628 sobre '
            'protección de datos personales. Revisa la política y ejerce tus '
            'derechos ARCOP en cualquier momento.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/privacy-policy');
            },
            icon: const Icon(Icons.policy_rounded),
            label: const Text('Ver Política de Privacidad'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NEON CARD WRAPPER
  // ---------------------------------------------------------------------------

  Widget _neonCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final p = _pulseController.value;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.15 + p * 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.06 + p * 0.04),
                blurRadius: 16 + p * 8,
                spreadRadius: p * 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.03 + p * 0.03),
                blurRadius: 24,
                spreadRadius: p,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primarySurface.withValues(alpha: 0.8),
                      AppTheme.primarySurface.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent
                                .withValues(alpha: 0.3 + p * 0.2),
                            blurRadius: 8 + p * 4,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(title,
                        style: AppTheme.titleMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: children),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE FIELD (view/edit toggle)
  // ---------------------------------------------------------------------------

  Widget _profileField({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 350),
      crossFadeState:
          _isEditing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: _readOnlyField(icon: icon, label: label, value: value),
      secondChild: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters?.cast(),
        maxLines: maxLines,
        style: AppTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.accent, width: 2),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _readOnlyField({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: highlight
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              size: 20,
              color: highlight ? AppTheme.primary : AppTheme.textSecondary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTheme.labelSmall
                      .copyWith(color: AppTheme.textTertiary)),
              const SizedBox(height: 3),
              Text(
                value,
                style: AppTheme.bodyLarge.copyWith(
                  color:
                      highlight ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE BUTTON (neon glow)
  // ---------------------------------------------------------------------------

  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final p = _pulseController.value;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.2 + p * 0.25),
                blurRadius: 20 + p * 12,
                spreadRadius: p * 3,
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.accent],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _isLoading ? null : _saveProfile,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
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
      },
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE PICKER
  // ---------------------------------------------------------------------------

  void _showImagePicker() {
    if (kIsWeb) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Cambiar foto',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _pickerCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camara',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _pickerCard(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeria',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
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

  Widget _pickerCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.primarySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: AppTheme.titleSmall
                      .copyWith(color: AppTheme.primary)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE UPLOAD
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _localImageFile = file;
          _isUploadingImage = true;
        });
        await _uploadImage(file);
      }
    } catch (e) {
      _showSnack('Error al seleccionar imagen', isError: true);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final result =
          await _authRepository.uploadProfileImage(widget.user.id, imageFile);
      await result.fold(
        (f) async {
          if (mounted) setState(() => _localImageFile = null);
          _showSnack('Error: ${f.message}', isError: true);
        },
        (imageUrl) async {
          final update = await _authRepository.updateProfileImage(
              widget.user.id, imageUrl);
          update.fold(
            (f) {
              if (mounted) setState(() => _localImageFile = null);
              _showSnack('Error: ${f.message}', isError: true);
            },
            (user) {
              if (mounted) {
                setState(() => _updatedUser = user);
                _showSnack('Foto actualizada');
                context.read<AuthBloc>().add(CheckAuthStatusEvent());
              }
            },
          );
        },
      );
    } catch (e) {
      if (mounted) setState(() => _localImageFile = null);
      _showSnack('Error inesperado', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE
  // ---------------------------------------------------------------------------

  Future<void> _saveProfile() async {
    final errors = <String>[];
    final ne = Validators.validateName(_nameController.text);
    if (ne != null) errors.add('Nombre: $ne');
    if (_isInspectorOrAdmin && _rutController.text.trim().isEmpty) {
      errors.add('RUT: Requerido');
    }
    final pe = Validators.validatePhone(_phoneController.text);
    if (pe != null) errors.add('Telefono: $pe');
    final ae = Validators.validateAddress(_addressController.text);
    if (ae != null) errors.add('Direccion: $ae');

    if (errors.isNotEmpty) {
      _showErrors(errors);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _authRepository.updateUserProfile(
        userId: widget.user.id,
        name: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        rut: _rutController.text.trim().isNotEmpty
            ? _rutController.text.trim()
            : null,
        phoneNumber: _phoneController.text
                .replaceAll(RegExp(r'[^\d]'), '')
                .isNotEmpty
            ? _phoneController.text.replaceAll(RegExp(r'[^\d]'), '')
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );
      result.fold(
        (f) => _showSnack('Error: ${f.message}', isError: true),
        (user) {
          _showSnack('Perfil actualizado');
          if (mounted) {
            context.read<AuthBloc>().add(CheckAuthStatusEvent());
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      _showSnack('Error inesperado', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppTheme.warning, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Revisa tus datos', style: AppTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: errors
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.close_rounded,
                            size: 16, color: AppTheme.emergency),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(e, style: AppTheme.bodyMedium)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppTheme.emergency : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'citizen':
        return 'Ciudadano';
      case 'inspector':
        return 'Inspector';
      case 'admin':
        return 'Administrador';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    const m = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${m[date.month - 1]} ${date.year}';
  }
}
