// lib/features/legal/presentation/pages/privacy_policy_screen.dart
//
// Pantalla in-app que muestra la Política de Privacidad y los derechos del
// titular de datos personales conforme a la Ley N° 21.719 (Chile, 2024) y la
// Ley N° 19.628.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _webUrl = 'https://frogio.cl/privacidad';
  static const String _contactEmail = 'rddigitalspa@gmail.com';

  Future<void> _openWeb() async {
    final uri = Uri.parse(_webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contact() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
      queryParameters: {
        'subject': 'Solicitud de derechos ARCOP - Frogio',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Abrir versión completa en la web',
            icon: const Icon(Icons.open_in_new),
            onPressed: _openWeb,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLawBadge(),
              const SizedBox(height: 20),
              _section(
                'Resumen',
                'Frogio recopila y trata tus datos personales (nombre, RUT, correo, '
                    'teléfono, ubicación cuando usas el botón SOS o creas una denuncia, '
                    'y multimedia que adjuntas) con la finalidad de gestionar denuncias '
                    'ciudadanas, transmitir alertas de emergencia a la municipalidad y '
                    'a la Central de Seguridad Ciudadana, y mejorar el servicio.',
              ),
              _sosWarning(),
              _section(
                'Bases legales',
                'Tratamos tus datos en virtud de: (i) tu consentimiento al registrarte; '
                    '(ii) el cumplimiento de obligaciones legales municipales; '
                    '(iii) el interés público en seguridad ciudadana; y '
                    '(iv) la protección de intereses vitales en emergencias.',
              ),
              _section(
                'Tus derechos (ARCOP)',
                'Conforme a la Ley N° 21.719 y la Ley N° 19.628, puedes ejercer en '
                    'cualquier momento y de forma gratuita los siguientes derechos:',
                bullets: const [
                  'Acceso: saber qué datos tuyos tratamos.',
                  'Rectificación: corregir datos inexactos o desactualizados.',
                  'Cancelación / supresión: eliminar tus datos.',
                  'Oposición: oponerte a tratamientos específicos.',
                  'Portabilidad: recibir tus datos en formato estructurado.',
                  'Bloqueo: suspender el tratamiento mientras se resuelve una controversia.',
                  'Retirar el consentimiento en cualquier momento.',
                  'No ser sometido a decisiones automatizadas con efectos jurídicos.',
                  'Reclamar ante la Agencia de Protección de Datos Personales.',
                ],
              ),
              _section(
                'Con quién compartimos tus datos',
                null,
                bullets: const [
                  'Municipalidad correspondiente, para la gestión de denuncias.',
                  'Central de Seguridad Ciudadana, en caso de alerta SOS.',
                  'Carabineros de Chile, cuando la situación lo requiera.',
                  'Proveedores tecnológicos (hosting, notificaciones push) bajo acuerdos de confidencialidad.',
                ],
                footer: 'No vendemos ni alquilamos tus datos personales.',
              ),
              _section(
                'Seguridad y conservación',
                'Aplicamos cifrado en tránsito (TLS) y en reposo, control de accesos y '
                    'registros de auditoría. Conservamos tus datos mientras tu cuenta '
                    'esté activa y por el plazo adicional que exija la ley.',
              ),
              _section(
                'Cumplimiento de la Ley N° 21.719',
                'La Ley N° 21.719 (publicada el 13 de diciembre de 2024 y plenamente '
                    'vigente desde el 1 de diciembre de 2026) moderniza la protección '
                    'de datos personales en Chile. Frogio adopta sus principios:',
                bullets: const [
                  'Licitud, lealtad y transparencia.',
                  'Finalidad específica y explícita.',
                  'Proporcionalidad y minimización.',
                  'Calidad y exactitud.',
                  'Responsabilidad (accountability).',
                  'Seguridad y confidencialidad.',
                  'Notificación de brechas a la autoridad y a los afectados.',
                ],
              ),
              _section(
                'Contacto del responsable',
                'Responsable del tratamiento: drozast.\n'
                    'Correo: $_contactEmail.\n'
                    'Plazo de respuesta: hasta 30 días hábiles.',
              ),
              const SizedBox(height: 16),
              _actionButtons(),
              const SizedBox(height: 16),
              const Text(
                'Última actualización: 5 de mayo de 2026',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta política da cumplimiento a la Ley N° 21.719 y la Ley N° 19.628 '
              'de la República de Chile, y a las disposiciones aplicables del GDPR.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14E53935),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: const Color(0x55E53935)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'El botón SOS NO reemplaza a los servicios de emergencia oficiales. '
              'Para urgencias llama siempre al 133 (Carabineros), 132 (Bomberos) '
              'o 131 (SAMU).',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF7F1D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    String? body, {
    List<String> bullets = const [],
    String? footer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (body != null)
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bullets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _contact,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Ejercer mis derechos (ARCOP)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openWeb,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ver versión completa en frogio.cl'),
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
}
