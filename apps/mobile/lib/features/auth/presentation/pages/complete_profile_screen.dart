// lib/features/auth/presentation/pages/complete_profile_screen.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../domain/entities/family_member_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserEntity user;

  const CompleteProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  // Colores FROGIO
  static const Color _primaryGreen = Color(0xFF1B5E20);
  static const Color _lightGreen = Color(0xFF7CB342);

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  late AuthRepository _authRepository;

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
  List<FamilyMemberEntity> _familyMembers = [];
  double? _latitude;
  double? _longitude;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _authRepository = di.sl<AuthRepository>();

    _nameController = TextEditingController(text: widget.user.name ?? '');
    _rutController = TextEditingController(text: widget.user.rut ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _referenceController = TextEditingController(text: widget.user.referenceNotes ?? '');

    _familyMembers = List.from(widget.user.familyMembers);
    _latitude = widget.user.latitude;
    _longitude = widget.user.longitude;
    _updatedUser = widget.user;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _rutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header con estilo FROGIO
            _buildHeader(),
            // Tabs
            _buildTabBar(),
            // Contenido
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalDataTab(),
                  _buildFamilyTab(),
                  _buildLocationTab(),
                ],
              ),
            ),
            // Botón guardar
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentUser = _updatedUser ?? widget.user;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Mi Perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: _isUploadingImage
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _buildAvatarContent(currentUser),
              ),
              if (!kIsWeb)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImagePicker,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentUser.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            currentUser.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(UserEntity user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          user.profileImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultAvatar(user),
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primaryGreen,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        labelPadding: EdgeInsets.zero,
        tabs: [
          _buildTab(Icons.person, 'Datos'),
          _buildTab(Icons.family_restroom, 'Familia'),
          _buildTab(Icons.location_on, 'Ubicación'),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildPersonalDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Informaci\u00f3n Personal'),
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
              label: 'Tel\u00e9fono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneFormatter()],
              prefixText: '+56 ',
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressController,
              label: 'Direcci\u00f3n',
              icon: Icons.home,
              hint: 'Calle Los Aromos 123, Santa Juana',
              maxLines: 2,
              validator: Validators.validateAddress,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Referencia de ubicaci\u00f3n'),
            const SizedBox(height: 8),
            Text(
              'Describe c\u00f3mo llegar a tu domicilio o puntos de referencia cercanos',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _referenceController,
              label: 'Cuadro de referencia',
              icon: Icons.description,
              hint: 'Ej: Casa color azul, frente a la cancha de f\u00fatbol...',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            // Informaci\u00f3n de cuenta
            _buildAccountInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyTab() {
    return Column(
      children: [
        // Bot\u00f3n agregar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
        ),
        // Lista de familiares
        Expanded(
          child: _familyMembers.isEmpty
              ? _buildEmptyFamilyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _familyMembers.length,
                  itemBuilder: (context, index) {
                    return _buildFamilyMemberCard(_familyMembers[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyFamilyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Ubicaci\u00f3n de tu domicilio'),
              const SizedBox(height: 8),
              Text(
                'Marca tu ubicaci\u00f3n en el mapa para que los servicios de emergencia puedan encontrarte f\u00e1cilmente.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Usar mi ubicaci\u00f3n actual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
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
            ],
          ),
        ),
        // Mapa
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
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
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.frogio.santa_juana',
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Toca en el mapa para marcar tu ubicaci\u00f3n',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
      ],
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
            'Informaci\u00f3n de la cuenta',
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
                    value: selectedRelationship,
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
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final rut = _rutController.text.trim();
      final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      final address = _addressController.text.trim();
      final reference = _referenceController.text.trim();

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
          Navigator.pop(context, true);
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
