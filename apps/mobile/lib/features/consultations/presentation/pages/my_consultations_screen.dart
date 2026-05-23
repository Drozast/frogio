// lib/features/consultations/presentation/pages/my_consultations_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class MyConsultationsScreen extends StatelessWidget {
  final String userId;

  const MyConsultationsScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Mis Consultas'),
        backgroundColor: AppTheme.surfaceWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    size: 80,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Consultas',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Esta funcionalidad estará disponible próximamente',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Podrás realizar consultas sobre:\n\n• Servicios municipales\n• Trámites y permisos\n• Información general\n• Atención ciudadana',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función en desarrollo'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Consulta'),
      ),
    );
  }
}
