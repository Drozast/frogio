// lib/features/auth/presentation/pages/complete_profile_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/services/maps_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/datasources/auth_api_data_source.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserEntity user;
  final bool isEmbedded;

  const CompleteProfileScreen({
    super.key,
    required this.user,
    this.isEmbedded = false,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with TickerProviderStateMixin {
  // Colores FROGIO
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF7CB342);

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late AuthRepository _authRepository;
  late AnimationController _pulseController;
  int _selectedSection = 0;

  // Controladores de texto
  late TextEditingController _nameController;
  late TextEditingController _rutController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _referenceController;

  // Estado
  bool _isLoading = false;
  bool _isUploadingImage = false;
  UserEntity? _updatedUser;
  File? _localImageFile;
  List<FamilyMemberEntity> _familyMembers = [];
  double? _latitude;
  double? _longitude;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Verificar si es inspector o admin (perfil simplificado)
  bool get _isInspectorOrAdmin =>
      widget.user.role == 'inspector' || widget.user.role == 'admin';

  @override
  void initState() {
    super.initState();
    // Inspectores solo tienen 1 tab, ciudadanos tienen 3
    _tabController = TabController(length: _isInspectorOrAdmin ? 1 : 3, vsync: this);
    _authRepository = di.sl<AuthRepository>();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _nameController = TextEditingController(text: widget.user.name ?? '');
    final initialRut = (widget.user.rut?.startsWith('APPLE_') ?? false) ? '' : (widget.user.rut ?? '');
    _rutController = TextEditingController(text: initialRut);
    // Strip +56 prefix if already in the phone number to avoid duplication with prefixText
    var phoneValue = widget.user.phoneNumber ?? '';
    if (phoneValue.startsWith('+56')) phoneValue = phoneValue.substring(3);
    if (phoneValue.startsWith('56') && phoneValue.length > 9) phoneValue = phoneValue.substring(2);
    _phoneController = TextEditingController(text: phoneValue);
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _referenceController = TextEditingController(text: widget.user.referenceNotes ?? '');

    _familyMembers = List.from(widget.user.familyMembers);
    _latitude = widget.user.latitude;
    _longitude = widget.user.longitude;
    _updatedUser = widget.user;

    _loadFullProfile();
  }

  bool get _isFirstLogin =>
      (widget.user.rut != null && widget.user.rut!.startsWith('APPLE_')) ||
      widget.user.displayName == 'Usuario' ||
      (widget.user.name == null || widget.user.name!.isEmpty);

  Future<void> _loadFullProfile() async {
    try {
      final dataSource = di.sl<AuthApiDataSource>();
      final user = await dataSource.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _updatedUser = user;
          if (_nameController.text.isEmpty && user.name != null) {
            _nameController.text = user.name!;
          }
          if (_phoneController.text.isEmpty && user.phoneNumber != null) {
            var phone = user.phoneNumber!;
            if (phone.startsWith('+56')) phone = phone.substring(3);
            if (phone.startsWith('56') && phone.length > 9) phone = phone.substring(2);
            _phoneController.text = phone;
          }
          if (_addressController.text.isEmpty && user.address != null) {
            _addressController.text = user.address!;
          }
          if (_referenceController.text.isEmpty && user.referenceNotes != null) {
            _referenceController.text = user.referenceNotes!;
          }
          if (_latitude == null && user.latitude != null) {
            _latitude = user.latitude;
            _longitude = user.longitude;
          }
          if (_familyMembers.isEmpty && user.familyMembers.isNotEmpty) {
            _familyMembers = List.from(user.familyMembers);
          }
          // Update RUT if not APPLE_ prefix
          if (_rutController.text.isEmpty && user.rut != null && !user.rut!.startsWith('APPLE_')) {
            _rutController.text = user.rut!;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _rutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            onPressed: _showSettingsSheet,
            icon: const Icon(Icons.settings_outlined, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileRow(),
                      const SizedBox(height: 16),
                      if (!_isInspectorOrAdmin) ...[
                        _buildSegmentedButtons(),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          child: _buildSelectedSection(),
                        ),
                      ] else
                        _buildInspectorDataTab(),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 0:
        return _buildPersonalDataTab();
      case 1:
        return _buildFamilyTab();
      default:
        return _buildPersonalDataTab();
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SettingsSheet(
        onChangePhoto: () {
          Navigator.pop(ctx);
          _showImagePicker();
        },
        onLogout: () {
          Navigator.pop(ctx);
          showDialog(
            context: context,
            builder: (dlg) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Cerrar sesión'),
              content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlg), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () { Navigator.pop(dlg); context.read<AuthBloc>().add(SignOutEvent()); },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emergency),
                  child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _neonOrb(double size, double pulse) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * pulse);
        return Container(
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.accent.withValues(alpha: 0.3 * (1.0 - _pulseController.value * 0.5)),
                AppTheme.accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow() {
    final currentUser = _updatedUser ?? widget.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.neonGlow,
      ),
      child: Stack(
        children: [
          // Neon orbs for decoration
          Positioned(top: -10, right: -10, child: _neonOrb(60, 0.15)),
          Positioned(bottom: -15, left: 30, child: _neonOrb(40, 0.2)),
          Row(
            children: [
              // Avatar LEFT (~70px)
              GestureDetector(
                onTap: kIsWeb ? null : _showImagePicker,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : ClipOval(
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: _buildAvatarContent70(currentUser),
                              ),
                            ),
                    ),
                    if (!kIsWeb)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt, color: AppTheme.primaryDark, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Name + email + role RIGHT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser.email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                      ),
                      child: Text(
                        _getRoleDisplayName(currentUser.role),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent70(UserEntity user) {
    // Show local file if just picked
    if (_localImageFile != null) {
      return Image.file(_localImageFile!, width: 70, height: 70, fit: BoxFit.cover);
    }
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      // Build public serve URL for file:// references
      final url = user.profileImageUrl!.startsWith('file://')
          ? '${ApiConfig.activeBaseUrl}/api/files/serve/${ApiConfig.tenantId}/${user.profileImageUrl!.substring(7)}'
          : user.profileImageUrl!;
      return CachedNetworkImage(
        imageUrl: url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(user),
      );
    }
    return Center(child: _buildDefaultAvatar(user));
  }

  Widget _buildAvatarContent(UserEntity user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      // Verificar si es una referencia a archivo (file://fileId)
      if (user.profileImageUrl!.startsWith('file://')) {
        final fileId = user.profileImageUrl!.substring(7);
        return _FileImageWidget(
          fileId: fileId,
          size: 100,
          fallback: _buildDefaultAvatar(user),
        );
      }
      // URL directa
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
          errorWidget: (context, url, error) => _buildDefaultAvatar(user),
        ),
      );
    }
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(UserEntity user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSegmentedButtons() {
    const icons = [Icons.person_rounded, Icons.family_restroom_rounded];
    const labels = ['Datos', 'Familia'];

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        final p = _pulseController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.15 + p * 0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
              BoxShadow(color: AppTheme.accent.withValues(alpha: 0.03 + p * 0.03), blurRadius: 14),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = (constraints.maxWidth - 8) / labels.length;
              return Stack(
                children: [
                  // Sliding indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    left: 4 + (_selectedSection * tabWidth),
                    top: 4,
                    bottom: 4,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3 + p * 0.15), blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                  // Tab labels
                  Row(
                    children: List.generate(labels.length, (index) {
                      final isSelected = _selectedSection == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSection = index),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(fontSize: 0, color: isSelected ? Colors.white : AppTheme.textSecondary),
                                  child: Icon(icons[index], size: 18, color: isSelected ? Colors.white : AppTheme.textSecondary),
                                ),
                                const SizedBox(width: 6),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  ),
                                  child: Text(labels[index]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Tab simplificado para inspectores/admins
  Widget _buildInspectorDataTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Personal'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Icons.person,
            inputFormatters: [NameFormatter()],
            validator: Validators.validateName,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _rutController,
            label: 'RUT',
            icon: Icons.badge,
            hint: '12.345.678-9',
            inputFormatters: [RutFormatter()],
            validator: Validators.validateRut,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneFormatter()],
            prefixText: '+56 ',
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Dirección',
            icon: Icons.home,
            hint: 'Calle Los Aromos 123, Santa Juana',
            maxLines: 2,
            validator: Validators.validateAddress,
          ),
          const SizedBox(height: 20),
          // Información institucional
          _buildInspectorAccountInfo(),
        ],
      ),
    );
  }

  Widget _buildPersonalDataTab() {
    return Padding(
      key: const ValueKey('personal'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información Personal'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Icons.person,
            inputFormatters: [NameFormatter()],
            validator: Validators.validateName,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _rutController,
            label: 'RUT',
            icon: Icons.badge,
            hint: '12.345.678-9',
            inputFormatters: [RutFormatter()],
            validator: Validators.validateRut,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneFormatter()],
            prefixText: '+56 ',
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'Dirección',
            icon: Icons.home,
            hint: 'Calle Los Aromos 123, Santa Juana',
            maxLines: 2,
            validator: Validators.validateAddress,
          ),
          // Botón geocodificar dirección → mapa
          if (_addressController.text.trim().length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: _geocodeAddress,
                child: Row(
                  children: [
                    Icon(Icons.search, size: 14, color: AppTheme.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('Buscar en mapa', style: TextStyle(fontSize: 12, color: AppTheme.primary.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // --- Ubicación en mapa ---
          _buildSectionTitle('Ubicación en mapa'),
          const SizedBox(height: 8),
          Text(
            'Marca tu domicilio para emergencias. Al tocar el mapa se actualiza la dirección.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Botones Mi ubicación + Ampliar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('Mi ubicación', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showFullscreenMap,
                icon: const Icon(Icons.fullscreen, size: 16),
                label: const Text('Ampliar', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Mapa inline
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _latitude != null
                          ? LatLng(_latitude!, _longitude!)
                          : const LatLng(-37.1676, -72.9424),
                      initialZoom: 15,
                      onTap: (_, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapsService.tileServerUrl,
                        tileProvider: MapsService.tileProvider,
                        userAgentPackageName: 'com.frogio.santajuana',
                      ),
                      if (_latitude != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: LatLng(_latitude!, _longitude!),
                            width: 40, height: 40,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ]),
                    ],
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      elevation: 2,
                      child: InkWell(
                        onTap: _showFullscreenMap,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.fullscreen, color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Referencia ---
          _buildSectionTitle('Referencia de ubicación'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _referenceController,
            label: 'Cuadro de referencia',
            icon: Icons.description,
            hint: 'Ej: Casa color azul, frente a la cancha...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _buildAccountInfo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    return Padding(
      key: const ValueKey('family'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón agregar
          Row(
            children: [
              Expanded(child: _buildSectionTitle('Integrantes del hogar')),
              ElevatedButton.icon(
                onPressed: _showAddFamilyMemberDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de familiares (inline, no ListView since parent scrolls)
          if (_familyMembers.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(Icons.family_restroom, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay integrantes registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega a los miembros de tu hogar',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else
            ...List.generate(_familyMembers.length, (index) {
              return _buildFamilyMemberCard(_familyMembers[index], index);
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard(FamilyMemberEntity member, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        member.relationship,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditFamilyMemberDialog(member, index),
                  icon: const Icon(Icons.edit, color: _lightGreen),
                ),
                IconButton(
                  onPressed: () => _removeFamilyMember(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            if (member.rut != null && member.rut!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoChip(Icons.badge, 'RUT: ${member.rut}'),
            ],
            if (member.phone != null && member.phone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoChip(Icons.phone, member.phone!),
            ],
            if (member.hasDisability || member.hasChronicIllness) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (member.hasDisability)
                    _buildStatusChip(
                      Icons.accessible,
                      member.disabilityType ?? 'Discapacidad',
                      Colors.orange,
                    ),
                  if (member.hasChronicIllness)
                    _buildStatusChip(
                      Icons.medical_services,
                      member.illnessType ?? 'Enfermedad cr\u00f3nica',
                      Colors.red,
                    ),
                ],
              ),
            ],
            if (member.notes != null && member.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                member.notes!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildStatusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return Padding(
      key: const ValueKey('location'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Ubicación de tu domicilio'),
          const SizedBox(height: 8),
          Text(
            'Marca tu ubicación en el mapa para que los servicios de emergencia puedan encontrarte fácilmente.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Barra de búsqueda
          _buildSearchBar(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Mi ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showFullscreenMap,
                icon: const Icon(Icons.fullscreen, size: 18),
                label: const Text('Ampliar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _lightGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _lightGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _lightGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordenadas: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Mapa con altura fija
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _latitude != null && _longitude != null
                          ? LatLng(_latitude!, _longitude!)
                          : const LatLng(-37.1676, -72.9424), // Santa Juana
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _latitude = point.latitude;
                          _longitude = point.longitude;
                          _searchResults = [];
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: '${ApiConfig.tileServerUrl}/styles/osm-bright/{z}/{x}/{y}.png',
                        userAgentPackageName: ApiConfig.appPackageName,
                      ),
                      if (_latitude != null && _longitude != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_latitude!, _longitude!),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                // Botón de expandir en esquina superior derecha
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      onTap: _showFullscreenMap,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.fullscreen, color: _primaryGreen),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Toca en el mapa para marcar tu ubicación',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar dirección...',
              prefixIcon: const Icon(Icons.search, color: _primaryGreen),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: _searchAddress,
            textInputAction: TextInputAction.search,
          ),
        ),
        // Resultados de búsqueda
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: _primaryGreen),
                  title: Text(
                    result['display_name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // Usar Nominatim para geocodificación (OpenStreetMap)
      final searchQuery = '$query, Santa Juana, Chile';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=5&countrycodes=cl',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FrogioApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error buscando dirección: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'] ?? '');
    final lon = double.tryParse(result['lon'] ?? '');

    if (lat != null && lon != null) {
      setState(() {
        _latitude = lat;
        _longitude = lon;
        _searchResults = [];
        _searchController.clear();
      });

      _mapController.move(LatLng(lat, lon), 17.0);

      // Siempre actualizar dirección desde resultado de búsqueda
      final displayName = result['display_name'] as String?;
      if (displayName != null) {
        final parts = displayName.split(',');
        if (parts.length >= 2) {
          _addressController.text = '${parts[0].trim()}, ${parts[1].trim()}';
        }
      }
    }
  }

  /// Mapa tocado → reverse geocode → actualizar dirección
  void _onMapTap(LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
      _searchResults = [];
    });
    _reverseGeocode(point.latitude, point.longitude);
  }

  /// Coordenadas → dirección (reverse geocoding via Nominatim)
  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.nominatimUrl}/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final response = await http.get(url, headers: {'User-Agent': 'FrogioApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null && mounted) {
          final road = address['road'] ?? '';
          final houseNumber = address['house_number'] ?? '';
          final suburb = address['suburb'] ?? address['neighbourhood'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
          final parts = [
            if (road.isNotEmpty) '$road${houseNumber.isNotEmpty ? ' $houseNumber' : ''}',
            if (suburb.isNotEmpty) suburb,
            if (city.isNotEmpty) city,
          ];
          if (parts.isNotEmpty) {
            _addressController.text = parts.join(', ');
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  /// Dirección texto → coordenadas (forward geocoding)
  Future<void> _geocodeAddress() async {
    final query = _addressController.text.trim();
    if (query.length < 5) return;

    try {
      final searchQuery = '$query, Santa Juana, Chile';
      final url = Uri.parse(
        '${ApiConfig.nominatimUrl}/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=1',
      );
      final response = await http.get(url, headers: {'User-Agent': 'FrogioApp/1.0'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && mounted) {
          final lat = double.tryParse(data[0]['lat'] ?? '');
          final lon = double.tryParse(data[0]['lon'] ?? '');
          if (lat != null && lon != null) {
            setState(() {
              _latitude = lat;
              _longitude = lon;
            });
            _mapController.move(LatLng(lat, lon), 17.0);
          }
        }
      }
    } catch (e) {
      debugPrint('Geocode error: $e');
    }
  }

  void _showFullscreenMap() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FullscreenMapDialog(
        initialLat: _latitude,
        initialLon: _longitude,
        onLocationSelected: (lat, lon) {
          setState(() {
            _latitude = lat;
            _longitude = lon;
          });
          _mapController.move(LatLng(lat, lon), 17.0);
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _primaryGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: _primaryGreen),
          prefixText: prefixText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _primaryGreen, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la cuenta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildAccountInfoRow('Email:', widget.user.email),
          _buildAccountInfoRow('Rol:', _getRoleDisplayName(widget.user.role)),
          _buildAccountInfoRow('Creada:', _formatDate(widget.user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInspectorAccountInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información institucional',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildAccountInfoRow('Email institucional:', widget.user.email),
          _buildAccountInfoRow('Cargo:', _getRoleDisplayName(widget.user.role)),
        ],
      ),
    );
  }

  Widget _buildAccountInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  // ========== DIALOGS ==========

  void _showAddFamilyMemberDialog() {
    _showFamilyMemberDialog(null, null);
  }

  void _showEditFamilyMemberDialog(FamilyMemberEntity member, int index) {
    _showFamilyMemberDialog(member, index);
  }

  void _showFamilyMemberDialog(FamilyMemberEntity? member, int? index) {
    final nameController = TextEditingController(text: member?.name ?? '');
    final rutController = TextEditingController(text: member?.rut ?? '');
    final phoneController = TextEditingController(text: member?.phone ?? '');
    final notesController = TextEditingController(text: member?.notes ?? '');
    final disabilityController = TextEditingController(text: member?.disabilityType ?? '');
    final illnessController = TextEditingController(text: member?.illnessType ?? '');

    String selectedRelationship = member?.relationship ?? FamilyRelationships.all.first;
    bool hasDisability = member?.hasDisability ?? false;
    bool hasChronicIllness = member?.hasChronicIllness ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(member == null ? 'Agregar Integrante' : 'Editar Integrante'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rutController,
                    decoration: const InputDecoration(
                      labelText: 'RUT',
                      hintText: '12.345.678-9',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    inputFormatters: [RutFormatter()],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRelationship,
                    decoration: const InputDecoration(
                      labelText: 'Relación *',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    items: FamilyRelationships.all.map((r) {
                      return DropdownMenuItem(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRelationship = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Tel\u00e9fono',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+56 ',
                    ),
                    inputFormatters: [PhoneFormatter()],
                  ),
                  const SizedBox(height: 16),
                  // Discapacidad
                  SwitchListTile(
                    title: const Text('Tiene discapacidad'),
                    value: hasDisability,
                    onChanged: (value) => setDialogState(() => hasDisability = value),
                    activeTrackColor: _primaryGreen.withValues(alpha: 0.5),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasDisability) ...[
                    TextField(
                      controller: disabilityController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de discapacidad',
                        hintText: 'Ej: Movilidad reducida, visual...',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Enfermedad crónica
                  SwitchListTile(
                    title: const Text('Tiene enfermedad crónica'),
                    value: hasChronicIllness,
                    onChanged: (value) => setDialogState(() => hasChronicIllness = value),
                    activeTrackColor: _primaryGreen.withValues(alpha: 0.5),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasChronicIllness) ...[
                    TextField(
                      controller: illnessController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de enfermedad',
                        hintText: 'Ej: Diabetes, hipertensi\u00f3n...',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas adicionales',
                      hintText: 'Informaci\u00f3n importante...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El nombre es obligatorio')),
                    );
                    return;
                  }

                  final newMember = FamilyMemberEntity(
                    id: member?.id,
                    name: nameController.text.trim(),
                    rut: rutController.text.trim().isNotEmpty ? rutController.text.trim() : null,
                    relationship: selectedRelationship,
                    phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                    hasDisability: hasDisability,
                    disabilityType: hasDisability ? disabilityController.text.trim() : null,
                    hasChronicIllness: hasChronicIllness,
                    illnessType: hasChronicIllness ? illnessController.text.trim() : null,
                    notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                  );

                  setState(() {
                    if (index != null) {
                      _familyMembers[index] = newMember;
                    } else {
                      _familyMembers.add(newMember);
                    }
                  });

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
                child: Text(member == null ? 'Agregar' : 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeFamilyMember(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u00bfEliminar integrante?'),
        content: Text('\u00bfEst\u00e1s seguro de eliminar a ${_familyMembers[index].name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _familyMembers.removeAt(index));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ========== ACTIONS ==========

  void _showImagePicker() {
    if (kIsWeb) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galer\u00eda'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 70);

      if (image != null) {
        setState(() => _isUploadingImage = true);
        final imageFile = File(image.path);
        await _uploadImage(imageFile);
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final imageUrlResult = await _authRepository.uploadProfileImage(
        widget.user.id,
        imageFile,
      );

      await imageUrlResult.fold(
        (failure) async => _showError('Error al subir imagen: ${failure.message}'),
        (imageUrl) async {
          final updateResult = await _authRepository.updateProfileImage(
            widget.user.id,
            imageUrl,
          );

          updateResult.fold(
            (failure) => _showError('Error al actualizar perfil: ${failure.message}'),
            (user) {
              setState(() => _updatedUser = user);
              _showSuccess('Imagen actualizada');
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
            },
          );
        },
      );
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          _showError('Permiso de ubicaci\u00f3n denegado');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permisos de ubicaci\u00f3n permanentemente denegados');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _mapController.move(LatLng(_latitude!, _longitude!), 17.0);
      _showSuccess('Ubicaci\u00f3n obtenida');
    } catch (e) {
      _showError('Error al obtener ubicaci\u00f3n: $e');
    }
  }

  Future<void> _saveProfile() async {
    // Validar formulario solo si estamos en la pestaña de datos o si el form está montado
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) {
      // Ir a la pestaña de datos para mostrar los errores
      if (!_isInspectorOrAdmin) {
        _tabController.animateTo(0);
      }
      _showError('Por favor corrige los errores en el formulario');
      return;
    }

    // Validación manual de campos requeridos
    final name = _nameController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final address = _addressController.text.trim();

    // Validar nombre (siempre requerido)
    final nameError = Validators.validateName(name);
    if (nameError != null) {
      if (!_isInspectorOrAdmin) {
        _tabController.animateTo(0);
      }
      _showError('Nombre: $nameError');
      return;
    }

    // Validar teléfono si tiene valor
    if (phone.isNotEmpty) {
      final phoneError = Validators.validatePhone(_phoneController.text);
      if (phoneError != null) {
        if (!_isInspectorOrAdmin) {
          _tabController.animateTo(0);
        }
        _showError('Teléfono: $phoneError');
        return;
      }
    }

    // Validar dirección si tiene valor
    if (address.isNotEmpty) {
      final addressError = Validators.validateAddress(address);
      if (addressError != null) {
        if (!_isInspectorOrAdmin) {
          _tabController.animateTo(0);
        }
        _showError('Dirección: $addressError');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final rut = _rutController.text.trim();
      final reference = _referenceController.text.trim();

      debugPrint('📍 Guardando perfil con ubicación: $_latitude, $_longitude');

      final result = await _authRepository.updateUserProfile(
        userId: widget.user.id,
        name: name.isNotEmpty ? name : null,
        rut: rut.isNotEmpty ? rut : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
        address: address.isNotEmpty ? address : null,
        latitude: _latitude,
        longitude: _longitude,
        referenceNotes: reference.isNotEmpty ? reference : null,
        familyMembers: _familyMembers.isNotEmpty ? _familyMembers : null,
      );

      result.fold(
        (failure) => _showError('Error: ${failure.message}'),
        (user) {
          _showSuccess('Perfil actualizado correctamente');
          context.read<AuthBloc>().add(CheckAuthStatusEvent());
          // Solo hacer pop si no está embebido en el dashboard
          if (!widget.isEmbedded) {
            Navigator.pop(context, true);
          }
        },
      );
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

/// Widget que carga una imagen desde un fileId
class _FileImageWidget extends StatefulWidget {
  final String fileId;
  final double size;
  final Widget fallback;

  const _FileImageWidget({
    required this.fileId,
    required this.size,
    required this.fallback,
  });

  @override
  State<_FileImageWidget> createState() => _FileImageWidgetState();
}

class _FileImageWidgetState extends State<_FileImageWidget> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    try {
      final authDataSource = di.sl<AuthApiDataSource>();
      final url = await authDataSource.getFileUrl(widget.fileId);

      if (!mounted) return;

      setState(() {
        _imageUrl = url;
        _isLoading = false;
        _hasError = url == null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_hasError || _imageUrl == null) {
      return widget.fallback;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: _imageUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
        errorWidget: (context, url, error) => widget.fallback,
      ),
    );
  }
}

/// Dialog de mapa en pantalla completa
class _FullscreenMapDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final Function(double lat, double lon) onLocationSelected;

  const _FullscreenMapDialog({
    this.initialLat,
    this.initialLon,
    required this.onLocationSelected,
  });

  @override
  State<_FullscreenMapDialog> createState() => _FullscreenMapDialogState();
}

class _FullscreenMapDialogState extends State<_FullscreenMapDialog> {
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF7CB342);

  late MapController _mapController;
  double? _selectedLat;
  double? _selectedLon;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLat = widget.initialLat;
    _selectedLon = widget.initialLon;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: _primaryGreen,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Seleccionar ubicación',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (_selectedLat != null && _selectedLon != null)
              TextButton.icon(
                onPressed: () {
                  widget.onLocationSelected(_selectedLat!, _selectedLon!);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Column(
          children: [
            // Barra de búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar dirección...',
                      prefixIcon: const Icon(Icons.search, color: _primaryGreen),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: _primaryGreen, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onSubmitted: _searchAddress,
                    textInputAction: TextInputAction.search,
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: _primaryGreen, size: 20),
                            title: Text(
                              result['display_name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Coordenadas seleccionadas
            if (_selectedLat != null && _selectedLon != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: _lightGreen.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop, color: _lightGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedLat!.toStringAsFixed(6)}, ${_selectedLon!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            // Mapa
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLat != null && _selectedLon != null
                          ? LatLng(_selectedLat!, _selectedLon!)
                          : const LatLng(-37.1676, -72.9424),
                      initialZoom: 16.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLat = point.latitude;
                          _selectedLon = point.longitude;
                          _searchResults = [];
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: '${ApiConfig.tileServerUrl}/styles/osm-bright/{z}/{x}/{y}.png',
                        userAgentPackageName: ApiConfig.appPackageName,
                      ),
                      if (_selectedLat != null && _selectedLon != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_selectedLat!, _selectedLon!),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 50,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Botón de mi ubicación
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location, color: _primaryGreen),
                    ),
                  ),
                  // Controles de zoom
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      children: [
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'zoom_in',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(_mapController.camera.center, currentZoom + 1);
                          },
                          child: const Icon(Icons.add, color: _primaryGreen),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          heroTag: 'zoom_out',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(_mapController.camera.center, currentZoom - 1);
                          },
                          child: const Icon(Icons.remove, color: _primaryGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Instrucción
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Toca en el mapa para marcar tu ubicación',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final searchQuery = '$query, Santa Juana, Chile';
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=5&countrycodes=cl',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'FrogioApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error buscando dirección: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'] ?? '');
    final lon = double.tryParse(result['lon'] ?? '');

    if (lat != null && lon != null) {
      setState(() {
        _selectedLat = lat;
        _selectedLon = lon;
        _searchResults = [];
        _searchController.clear();
      });

      _mapController.move(LatLng(lat, lon), 17.0);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          _showError('Permiso de ubicación denegado');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permisos de ubicación permanentemente denegados');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLat = position.latitude;
        _selectedLon = position.longitude;
      });

      _mapController.move(LatLng(_selectedLat!, _selectedLon!), 17.0);
    } catch (e) {
      _showError('Error al obtener ubicación: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Settings bottom sheet with functional permission toggles
class _SettingsSheet extends StatefulWidget {
  final VoidCallback onChangePhoto;
  final VoidCallback onLogout;

  const _SettingsSheet({required this.onChangePhoto, required this.onLogout});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _notificationsEnabled = false;
  bool _locationEnabled = false;
  bool _cameraEnabled = false;
  bool _loadingPerms = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locPerm = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _locationEnabled = locPerm == LocationPermission.always || locPerm == LocationPermission.whileInUse;
      _notificationsEnabled = true;
      _cameraEnabled = true;
      _loadingPerms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Configuración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),

            _tile(Icons.camera_alt_rounded, 'Cambiar foto de perfil', 'Actualizar tu imagen', onTap: widget.onChangePhoto),
            const SizedBox(height: 8),

            _toggleTile(
              Icons.notifications_rounded, 'Notificaciones', 'Alertas y avisos de la app',
              _loadingPerms ? false : _notificationsEnabled,
              (val) async {
                await Geolocator.openAppSettings();
                if (mounted) _checkPermissions();
              },
            ),
            const SizedBox(height: 8),

            _toggleTile(
              Icons.location_on_rounded, 'Ubicación', 'Acceso GPS para emergencias',
              _loadingPerms ? false : _locationEnabled,
              (val) async {
                if (!_locationEnabled) {
                  final perm = await Geolocator.requestPermission();
                  if (perm == LocationPermission.deniedForever) {
                    await Geolocator.openAppSettings();
                  }
                } else {
                  await Geolocator.openAppSettings();
                }
                if (mounted) _checkPermissions();
              },
            ),
            const SizedBox(height: 8),

            _toggleTile(
              Icons.photo_camera_rounded, 'Cámara', 'Para fotos de perfil y denuncias',
              _loadingPerms ? false : _cameraEnabled,
              (val) async {
                await Geolocator.openAppSettings();
                if (mounted) _checkPermissions();
              },
            ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderLight),
            const SizedBox(height: 8),

            _tile(Icons.info_rounded, 'Acerca de FROGIO', 'Versión 1.0.0 · Santa Juana', onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'FROGIO',
                applicationVersion: '1.0.0',
                applicationIcon: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_city, color: Colors.white, size: 28),
                ),
                children: const [
                  Text('Sistema de gestión municipal para la comuna de Santa Juana.'),
                  SizedBox(height: 8),
                  Text('Desarrollado por SuperTools', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              );
            }),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, color: AppTheme.emergency),
                label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.emergency)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.emergency.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.primarySurface, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
        ],
      ),
    );
  }
}
