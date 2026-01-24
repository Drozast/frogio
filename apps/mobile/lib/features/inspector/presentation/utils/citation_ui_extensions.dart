// lib/features/inspector/presentation/utils/citation_ui_extensions.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/citation_entity.dart';

/// Extension to provide UI-related properties for [CitationStatus].
extension CitationStatusUI on CitationStatus {
  /// Returns a theme-aware color for the status.
  Color color(BuildContext context) {
    switch (this) {
      case CitationStatus.pendiente:
        return AppTheme.warning;
      case CitationStatus.notificado:
        return AppTheme.info;
      case CitationStatus.asistio:
        return AppTheme.success;
      case CitationStatus.noAsistio:
        return AppTheme.emergency;
      case CitationStatus.cancelado:
        return AppTheme.textSecondary;
    }
  }

  /// Returns a background color for badges and highlights.
  Color backgroundColor(BuildContext context) {
     switch (this) {
      case CitationStatus.pendiente:
        return AppTheme.warningLight;
      case CitationStatus.notificado:
        return AppTheme.infoLight;
      case CitationStatus.asistio:
        return AppTheme.successLight;
      case CitationStatus.noAsistio:
        return AppTheme.emergencyLight;
      case CitationStatus.cancelado:
        return AppTheme.borderLight;
    }
  }

  /// Returns a descriptive icon for the status.
  IconData get icon {
    switch (this) {
      case CitationStatus.pendiente:
        return Icons.schedule_rounded;
      case CitationStatus.notificado:
        return Icons.notifications_active_rounded;
      case CitationStatus.asistio:
        return Icons.check_circle_rounded;
      case CitationStatus.noAsistio:
        return Icons.cancel_rounded;
      case CitationStatus.cancelado:
        return Icons.block_rounded;
    }
  }

    /// Returns a short description for the status.
  String get statusDescription {
    switch (this) {
      case CitationStatus.pendiente:
        return 'Citación creada, pendiente de notificar';
      case CitationStatus.notificado:
        return 'El citado ha sido notificado';
      case CitationStatus.asistio:
        return 'El citado asistió a la cita';
      case CitationStatus.noAsistio:
        return 'El citado no asistió';
      case CitationStatus.cancelado:
        return 'Citación cancelada';
    }
  }
}

/// Extension to provide UI-related properties for [CitationType].
extension CitationTypeUI on CitationType {
  /// Returns a descriptive icon for the citation type.
  IconData get icon {
    switch (this) {
      case CitationType.advertencia:
        return Icons.warning_amber_rounded;
      case CitationType.citacion:
        return Icons.assignment_rounded;
    }
  }
}
