import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../dashboard/presentation/pages/dashboard_screen.dart';
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
    // Eliminar puntos y guión existentes
    String clean = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (clean.isEmpty) return '';

    // Separar cuerpo y dígito verificador
    String body = clean.length > 1 ? clean.substring(0, clean.length - 1) : '';
    String dv = clean.isNotEmpty ? clean[clean.length - 1] : '';

    // Formatear con puntos
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

    // Calcular dígito verificador
    int sum = 0;
    int multiplier = 2;

    for (int i = body.length - 1; i >= 0; i--) {
      sum += int.parse(body[i]) * multiplier;
      multiplier = multiplier == 7 ? 2 : multiplier + 1;
    }

    int calculatedDv = 11 - (sum % 11);
    String expectedDv = calculatedDv == 11 ? '0' : calculatedDv == 10 ? 'K' : calculatedDv.toString();

    return dv == expectedDv;
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: AppTheme.primaryColor, size: 32),
            SizedBox(width: 12),
            Text('¡Registro Exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Hemos enviado un correo de verificación a:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revisa tu bandeja de entrada y haz clic en el enlace para activar tu cuenta.',
                      style: TextStyle(fontSize: 13),
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
          // Mostrar diálogo de verificación de email
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
          appBar: AppBar(
            title: const Text('Registro'),
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
                      // Icono
                      const SizedBox(
                        height: 150,
                        child: Icon(
                          Icons.person_add,
                          size: 80,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa tus datos para registrarte',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
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
                              selection: TextSelection.collapsed(offset: formatted.length),
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
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo contraseña con validación estricta
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
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                      // Requisitos de contraseña
                      if (_showPasswordRequirements) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requisitos de contraseña:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...PasswordValidator.getRequirements().map((req) {
                                bool isValid = _validateRequirement(req, _passwordController.text);
                                return Row(
                                  children: [
                                    Icon(
                                      isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: isValid ? AppTheme.successColor : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        req,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isValid ? AppTheme.successColor : Colors.grey,
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
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
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
                      const SizedBox(height: 30),
                      // Botón registrar
                      CustomButton(
                        text: 'Registrarme',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(
                              RegisterEvent(
                                email: _emailController.text.trim(),
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
                          const Text('¿Ya tienes una cuenta?'),
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