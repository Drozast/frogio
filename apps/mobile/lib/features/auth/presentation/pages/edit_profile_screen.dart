// lib/features/auth/presentation/pages/edit_profile_screen.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/datasources/auth_api_data_source.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class EditProfileScreen extends StatefulWidget {
  final UserEntity user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rutController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late AuthRepository _authRepository;

  bool _isLoading = false;
  bool _isUploadingImage = false;
  UserEntity? _updatedUser;

  // Verificar si es inspector o admin
  bool get _isInspectorOrAdmin =>
      widget.user.role == 'inspector' || widget.user.role == 'admin';

  @override
  void initState() {
    super.initState();
    _authRepository = di.sl<AuthRepository>();
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _rutController = TextEditingController(text: widget.user.rut ?? '');
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _updatedUser = widget.user;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rutController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar con opción de cambiar foto
              _buildProfileAvatar(),
              const SizedBox(height: 8),
              Text(
                kIsWeb 
                    ? 'Fotos de perfil disponibles en app móvil'
                    : 'Toca la cámara para cambiar tu foto',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Campo nombre
              TextFormField(
                controller: _nameController,
                inputFormatters: [NameFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),

              // Campo RUT (para inspectores/admin)
              if (_isInspectorOrAdmin) ...[
                TextFormField(
                  controller: _rutController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'RUT',
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'Ej: 12.345.678-9',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su RUT';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Campo teléfono
              TextFormField(
                controller: _phoneController,
                inputFormatters: [PhoneFormatter()],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                  prefixText: '+56 ',
                ),
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),

              // Campo dirección
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Ej: Calle Los Aromos 123, Santa Juana',
                ),
                validator: Validators.validateAddress,
              ),
              const SizedBox(height: 24),

              // Información de cuenta (solo lectura)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isInspectorOrAdmin
                            ? 'Información institucional'
                            : 'Información de la cuenta',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        _isInspectorOrAdmin ? 'Email institucional:' : 'Email:',
                        widget.user.email,
                      ),
                      _buildInfoRow('Rol:', _getRoleDisplayName(widget.user.role)),
                      if (!_isInspectorOrAdmin)
                        _buildInfoRow(
                          'Cuenta creada:',
                          _formatDate(widget.user.createdAt),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Guardar Cambios',
                  isLoading: _isLoading,
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final currentUser = _updatedUser ?? widget.user;
    
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: _isUploadingImage
              ? const CircularProgressIndicator()
              : _buildAvatarContent(currentUser),
        ),
        if (!kIsWeb)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent(UserEntity user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      // Verificar si es una referencia a archivo (file://fileId)
      if (user.profileImageUrl!.startsWith('file://')) {
        final fileId = user.profileImageUrl!.substring(7);
        return _FileImageWidget(
          fileId: fileId,
          size: 120,
          fallback: _buildDefaultAvatar(user),
        );
      }
      // URL directa
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(user),
        ),
      );
    }
    return _buildDefaultAvatar(user);
  }

  Widget _buildDefaultAvatar(UserEntity user) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      child: Text(
        user.displayName.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showImagePicker() {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotos de perfil disponibles en la app móvil'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }
    
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
              title: const Text('Elegir de galería'),
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final File imageFile = File(image.path);
        await _uploadImage(imageFile);
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final imageUrlResult = await _authRepository.uploadProfileImage(
        widget.user.id,
        imageFile,
      );

      await imageUrlResult.fold(
        (failure) async {
          _showError('Error al subir imagen: ${failure.message}');
        },
        (imageUrl) async {
          final updateResult = await _authRepository.updateProfileImage(
            widget.user.id,
            imageUrl,
          );

          updateResult.fold(
            (failure) {
              _showError('Error al actualizar perfil: ${failure.message}');
            },
            (user) {
              setState(() {
                _updatedUser = user;
              });
              _showSuccess('Imagen actualizada correctamente');
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
            },
          );
        },
      );
    } catch (e) {
      _showError('Error inesperado: ${e.toString()}');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = _nameController.text.trim();
        final rut = _rutController.text.trim();
        final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
        final address = _addressController.text.trim();

        final result = await _authRepository.updateUserProfile(
          userId: widget.user.id,
          name: name.isNotEmpty ? name : null,
          rut: rut.isNotEmpty ? rut : null,
          phoneNumber: phone.isNotEmpty ? phone : null,
          address: address.isNotEmpty ? address : null,
        );

        result.fold(
          (failure) {
            _showError('Error al actualizar perfil: ${failure.message}');
          },
          (user) {
            _showSuccess('Perfil actualizado correctamente');
            context.read<AuthBloc>().add(CheckAuthStatusEvent());
            Navigator.pop(context, true);
          },
        );
      } catch (e) {
        _showError('Error inesperado: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      debugPrint('📷 EditProfile: Loading image URL for fileId: ${widget.fileId}');
      final authDataSource = di.sl<AuthApiDataSource>();
      final url = await authDataSource.getFileUrl(widget.fileId);
      debugPrint('📷 EditProfile: Got URL: $url');

      if (!mounted) return;

      setState(() {
        _imageUrl = url;
        _isLoading = false;
        _hasError = url == null;
      });
    } catch (e) {
      debugPrint('📷 EditProfile: Error loading URL: $e');
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
        child: const Center(child: CircularProgressIndicator()),
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
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => widget.fallback,
      ),
    );
  }
}