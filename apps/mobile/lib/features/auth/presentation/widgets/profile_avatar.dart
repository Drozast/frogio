// lib/features/auth/presentation/widgets/profile_avatar.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';

class ProfileAvatar extends StatelessWidget {
  final UserEntity user;
  final double radius;
  final bool isEditable;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 50,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: state is ProfileImageUploading
                  ? const CircularProgressIndicator()
                  : _buildAvatarContent(),
            ),
            if (isEditable)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showImagePicker(context),
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
      },
    );
  }

  Widget _buildAvatarContent() {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: user.profileImageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          child: const CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      child: Text(
        user.displayName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
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
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        if (!context.mounted) return;
        
        // Buscar ProfileBloc en el contexto padre o crear uno nuevo
        try {
          context.read<ProfileBloc>().add(
            UploadProfileImageEvent(
              userId: user.id,
              imageFile: imageFile,
            ),
          );
        } catch (e) {
          // Si no hay ProfileBloc disponible, usar el servicio directamente
          _uploadImageDirectly(context, imageFile);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _uploadImageDirectly(BuildContext context, File imageFile) async {
    try {
      if (!context.mounted) return;
      
      // Mostrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Subiendo imagen...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Usar el servicio directamente
      final authRepo = di.sl<AuthRepository>();
      
      // Subir imagen
      final imageUrlResult = await authRepo.uploadProfileImage(user.id, imageFile);
      
      await imageUrlResult.fold(
        (failure) async {
          if (!context.mounted) return;
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
        (imageUrl) async {
          // Actualizar perfil con nueva URL
          final updateResult = await authRepo.updateProfileImage(user.id, imageUrl);
          
          if (!context.mounted) return;
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          updateResult.fold(
            (failure) {
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${failure.message}'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            (updatedUser) {
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Imagen actualizada correctamente'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
              
              // Actualizar AuthBloc
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}