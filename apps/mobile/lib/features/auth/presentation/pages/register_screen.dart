import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../../../legal/presentation/pages/privacy_policy_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rutController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showPasswordRequirements = false;
  bool _acceptedPolicy = false;
  bool _policyError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rutController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatRut(String rut) {
    String clean = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return '';

    String body = clean.length > 1 ? clean.substring(0, clean.length - 1) : '';
    String dv = clean.isNotEmpty ? clean[clean.length - 1] : '';

    String formatted = '';
    for (int i = body.length - 1, count = 0; i >= 0; i--, count++) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = body[i] + formatted;
    }

    return dv.isNotEmpty ? '$formatted-$dv' : formatted;
  }

  bool _validateRut(String rut) {
    String clean = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (clean.length < 2) return false;

    String body = clean.substring(0, clean.length - 1);
    String dv = clean[clean.length - 1];

    int sum = 0;
    int multiplier = 2;

    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }

    int calculatedDv = 11 - (sum % 11);
    String expectedDv = calculatedDv == 11
        ? '0'
        : calculatedDv == 10
            ? 'K'
            : calculatedDv.toString();

    return dv == expectedDv;
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: AppTheme.primaryColor, size: 32),
            SizedBox(width: 12),
            Text(
              '¡Registro Exitoso!',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 56,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hemos enviado un correo de verificación a:',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text,
              style: AppTheme.titleSmall.copyWith(color: AppTheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _showEmailVerificationDialog();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            title: const Text('Registro'),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icono header
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primarySurface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.20),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: AppTheme.primaryLight.withValues(alpha: 0.10),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 40,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa tus datos para registrarte',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Form card blanca con sombra y borde primario suave
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            ...AppTheme.shadowSmall,
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo nombre
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu nombre';
                                }
                                if (value.length < 2) {
                                  return 'El nombre debe tener al menos 2 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Campo RUT
                            TextFormField(
                              controller: _rutController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'RUT',
                                hintText: '12.345.678-9',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              onChanged: (value) {
                                final formatted = _formatRut(value);
                                if (formatted != value) {
                                  _rutController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu RUT';
                                }
                                if (!_validateRut(value)) {
                                  return 'RUT inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Campo email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(trimmed)) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Campo contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onTap: () {
                                setState(() {
                                  _showPasswordRequirements = true;
                                });
                              },
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: PasswordValidator.validate,
                            ),
                            const SizedBox(height: 8),
                            // Requisitos de contraseña — fondo claro
                            if (_showPasswordRequirements) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primarySurface,
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium),
                                  border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Requisitos de contraseña:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...PasswordValidator.getRequirements()
                                        .map((req) {
                                      bool isValid = _validateRequirement(
                                          req, _passwordController.text);
                                      return Row(
                                        children: [
                                          Icon(
                                            isValid
                                                ? Icons.check_circle
                                                : Icons
                                                    .radio_button_unchecked,
                                            size: 16,
                                            color: isValid
                                                ? AppTheme.success
                                                : AppTheme.textTertiary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              req,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isValid
                                                    ? AppTheme.success
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Campo confirmar contraseña
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor confirma tu contraseña';
                                }
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Consentimiento de Política de Privacidad (Ley 21.719)
                      _PrivacyConsent(
                        accepted: _acceptedPolicy,
                        showError: _policyError,
                        onChanged: (v) {
                          setState(() {
                            _acceptedPolicy = v ?? false;
                            if (_acceptedPolicy) _policyError = false;
                          });
                        },
                        onOpenPolicy: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Botón registrar con glow verde
                      _RegisterButton(
                        isLoading: state is AuthLoading,
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                final formValid = _formKey.currentState!.validate();
                                if (!_acceptedPolicy) {
                                  setState(() => _policyError = true);
                                }
                                if (formValid && _acceptedPolicy) {
                                  context.read<AuthBloc>().add(
                                        RegisterEvent(
                                          email:
                                              _emailController.text.trim(),
                                          password: _passwordController.text,
                                          name: _nameController.text.trim(),
                                          rut: _rutController.text.trim(),
                                        ),
                                      );
                                }
                              },
                      ),

                      const SizedBox(height: 16),
                      // Opción iniciar sesión
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta?',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Inicia sesión'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateRequirement(String requirement, String password) {
    switch (requirement) {
      case 'Mínimo 8 caracteres':
        return password.length >= 8;
      case 'Al menos una mayúscula':
        return password.contains(RegExp(r'[A-Z]'));
      case 'Al menos un número':
        return password.contains(RegExp(r'[0-9]'));
      case 'Al menos un carácter especial (!@#\$%^&*)':
        return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      default:
        return false;
    }
  }
}

/// Bloque de consentimiento de Política de Privacidad (Ley 21.719 / Ley 19.628).
/// Muestra un checkbox obligatorio con enlace a la política completa.
class _PrivacyConsent extends StatelessWidget {
  final bool accepted;
  final bool showError;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onOpenPolicy;

  const _PrivacyConsent({
    required this.accepted,
    required this.showError,
    required this.onChanged,
    required this.onOpenPolicy,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = showError
        ? AppTheme.errorColor.withValues(alpha: 0.5)
        : AppTheme.primary.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: accepted,
                onChanged: onChanged,
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () => onChanged(!accepted),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          const TextSpan(
                            text: 'He leído y acepto la ',
                          ),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = onOpenPolicy,
                          ),
                          const TextSpan(
                            text:
                                ' y autorizo el tratamiento de mis datos personales '
                                'conforme a la Ley N° 21.719 y la Ley N° 19.628.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showError)
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 6, top: 2),
              child: Text(
                'Debes aceptar la Política de Privacidad para continuar.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón de registro con glow verde animado sobre fondo claro
class _RegisterButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _RegisterButton({required this.isLoading, this.onPressed});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) => Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight
                    .withValues(alpha: _glowAnim.value * 0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: AppTheme.primary
                    .withValues(alpha: _glowAnim.value * 0.18),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Registrarme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
