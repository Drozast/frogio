// lib/features/auth/presentation/pages/login_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/animations.dart';
import '../../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberPassword = false;

  late AnimationController _neonController;
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  // Neon green adaptado a fondo claro (opacidades reducidas)
  static const Color _neonGreen = Color(0xFF00C853);
  static const Color _primaryGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _neonController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _neonController.dispose();
    _glowController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final savedPassword = prefs.getString('saved_password') ?? '';
    final rememberPassword = prefs.getBool('remember_password') ?? false;

    if (rememberPassword && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() {
        _rememberPassword = rememberPassword;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberPassword) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_password', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_password', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _saveCredentials();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        } else if (state is PasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha enviado un correo para restablecer tu contraseña'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Gradient header con wave clip + neon FX adaptado a claro
                ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    height: screenHeight * 0.38,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Neon orbs animados — opacidad ajustada para fondo verde oscuro
                        AnimatedBuilder(
                          animation: _neonController,
                          builder: (context, _) {
                            final t = _neonController.value * 2 * pi;
                            return Stack(
                              children: [
                                Positioned(
                                  top: 10 + sin(t) * 12,
                                  right: 20 + cos(t * 0.7) * 8,
                                  child: _NeonOrb(size: 90, color: _neonGreen, opacity: 0.20),
                                ),
                                Positioned(
                                  bottom: 50 + sin(t + 1) * 10,
                                  left: -10 + cos(t + 2) * 8,
                                  child: _NeonOrb(size: 60, color: _neonGreen, opacity: 0.15),
                                ),
                                Positioned(
                                  top: screenHeight * 0.12 + sin(t + 2) * 8,
                                  left: screenHeight * 0.08,
                                  child: _NeonOrb(size: 30, color: _neonGreen, opacity: 0.22),
                                ),
                              ],
                            );
                          },
                        ),
                        // Logo y título
                        SafeArea(
                          child: Center(
                            child: FadeSlideTransition(
                              beginOffset: const Offset(0, -0.1),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  // Logo con neon glow animado
                                  AnimatedBuilder(
                                    animation: _glowAnim,
                                    builder: (context, child) => Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _neonGreen.withValues(alpha: _glowAnim.value * 0.6),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _neonGreen.withValues(alpha: _glowAnim.value * 0.30),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: _neonGreen.withValues(alpha: _glowAnim.value * 0.15),
                                            blurRadius: 40,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        'assets/icons/frogio_logo.png',
                                        width: 50,
                                        height: 50,
                                        errorBuilder: (_, __, ___) => const Text(
                                          'F',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // FROGIO con glow verde sobre verde oscuro
                                  AnimatedBuilder(
                                    animation: _glowAnim,
                                    builder: (context, _) => Text(
                                      'FROGIO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 3,
                                        shadows: [
                                          Shadow(
                                            color: _neonGreen.withValues(alpha: _glowAnim.value * 0.7),
                                            blurRadius: 14,
                                          ),
                                          Shadow(
                                            color: _neonGreen.withValues(alpha: _glowAnim.value * 0.35),
                                            blurRadius: 28,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sistema de Gestión Municipal',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form section — card blanca sobre fondo claro
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          boxShadow: AppTheme.shadowMedium,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Bienvenido',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Inicia sesión para continuar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Email field
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 300),
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Correo electrónico',
                                    prefixIcon: Icon(Icons.email_outlined),
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
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 400),
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_obscurePassword),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingresa tu contraseña';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Remember & Forgot password
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 450),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: _rememberPassword,
                                          activeColor: AppTheme.primaryColor,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberPassword = value ?? false;
                                            });
                                          },
                                        ),
                                        const Text(
                                          'Recordar',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: _showForgotPasswordDialog,
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Login button con glow verde animado sobre fondo blanco
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 500),
                                child: ScaleOnTap(
                                  onTap: state is AuthLoading
                                      ? null
                                      : () {
                                          if (_formKey.currentState!.validate()) {
                                            context.read<AuthBloc>().add(
                                              SignInEvent(
                                                email: _emailController.text.trim(),
                                                password: _passwordController.text,
                                              ),
                                            );
                                          }
                                        },
                                  child: AnimatedBuilder(
                                    animation: _glowAnim,
                                    builder: (context, child) => Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                        boxShadow: [
                                          // Glow verde suave — elegante sobre fondo blanco
                                          BoxShadow(
                                            color: _neonGreen.withValues(alpha: _glowAnim.value * 0.35),
                                            blurRadius: 18,
                                            spreadRadius: 1,
                                          ),
                                          BoxShadow(
                                            color: _primaryGreen.withValues(alpha: _glowAnim.value * 0.20),
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
                                      child: state is AuthLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Iniciar Sesión',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Divider
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 550),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O continúa con',
                            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.border)),
                      ],
                    ),
                  ),
                ),

                // Social buttons — adaptados a fondo claro
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 570),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Apple Sign In — solo iOS
                        if (Theme.of(context).platform == TargetPlatform.iOS)
                          _SocialLoginButton(
                            onPressed: () => context.read<AuthBloc>().add(const SignInWithAppleEvent()),
                            icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                            label: 'Continuar con Apple',
                            backgroundColor: Colors.black87,
                            borderColor: Colors.black.withValues(alpha: 0.15),
                            textColor: Colors.white,
                          ),
                        if (Theme.of(context).platform == TargetPlatform.iOS)
                          const SizedBox(height: 10),
                        // Google Sign In — ambas plataformas
                        _SocialLoginButton(
                          onPressed: () => context.read<AuthBloc>().add(const SignInWithGoogleEvent()),
                          icon: _GoogleIcon(),
                          label: 'Continuar con Google',
                          backgroundColor: AppTheme.surfaceWhite,
                          borderColor: AppTheme.border,
                          textColor: AppTheme.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Register link
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'Ingresa tu correo para recuperar',
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return TextButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                        if (formKey.currentState!.validate()) {
                          context.read<AuthBloc>().add(
                            ForgotPasswordEvent(email: emailController.text.trim()),
                          );
                          Navigator.pop(context);
                        }
                      },
                child: state is AuthLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Glowing social login button (Apple / Google)
class _SocialLoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15,
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

/// Google "G" logo painted with the four brand colors
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    final bg = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bg);

    const segments = [
      (0.0, 0.333, Color(0xFF4285F4)),
      (0.333, 0.666, Color(0xFF34A853)),
      (0.666, 0.833, Color(0xFFFBBC05)),
      (0.833, 1.0, Color(0xFFEA4335)),
    ];
    for (final (start, end, color) in segments) {
      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.65),
        (start * 2 - 0.5) * 3.14159,
        ((end - start) * 2) * 3.14159,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeonOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _NeonOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity * 0.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: size * 0.5,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for wave shape at bottom of gradient header
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);

    final controlPoint1 = Offset(size.width * 0.25, size.height);
    final endPoint1 = Offset(size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(
      controlPoint1.dx, controlPoint1.dy,
      endPoint1.dx, endPoint1.dy,
    );

    final controlPoint2 = Offset(size.width * 0.75, size.height - 40);
    final endPoint2 = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(
      controlPoint2.dx, controlPoint2.dy,
      endPoint2.dx, endPoint2.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
