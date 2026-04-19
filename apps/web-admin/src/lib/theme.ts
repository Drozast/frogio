/**
 * FROGIO Verde Sapo color palette mirrored from
 * apps/mobile/lib/core/theme/app_theme.dart
 *
 * Use these constants for any dynamic style (charts, gradients,
 * inline styles for jsPDF, etc.) where Tailwind tokens are not enough.
 */
export const FROGIO_COLORS = {
  primary: '#4CAF50',
  primaryDark: '#2E7D32',
  primaryLight: '#A5D6A7',
  accent: '#69F0AE',
  surface: '#F0F7F0',
  surfaceWhite: '#FFFFFF',
  emergency: '#D32F2F',
  warning: '#F57C00',
  success: '#388E3C',
  info: '#1976D2',
  textPrimary: '#1B3A1B',
  textSecondary: '#4A6741',
  textTertiary: '#8DAF8D',
  border: '#E0E0E0',
} as const;

export const FROGIO_GRADIENTS = {
  primary: 'linear-gradient(135deg, #2E7D32 0%, #4CAF50 50%, #66BB6A 100%)',
  emergency: 'linear-gradient(135deg, #B71C1C 0%, #D32F2F 100%)',
} as const;

export type FrogioColorKey = keyof typeof FROGIO_COLORS;
export type FrogioGradientKey = keyof typeof FROGIO_GRADIENTS;

/**
 * Resolve the color of a status badge. Mirrors AppTheme.getStatusColor (Dart).
 */
export function getStatusColor(status: string): string {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'pendiente':
    case 'enviada':
      return FROGIO_COLORS.warning;
    case 'in_progress':
    case 'en_revision':
    case 'en_proceso':
      return FROGIO_COLORS.info;
    case 'resolved':
    case 'resuelta':
    case 'completada':
      return FROGIO_COLORS.success;
    case 'rejected':
    case 'rechazada':
    case 'cancelada':
      return FROGIO_COLORS.emergency;
    default:
      return FROGIO_COLORS.textSecondary;
  }
}
