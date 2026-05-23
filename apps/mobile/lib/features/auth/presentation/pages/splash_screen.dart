import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../dashboard/presentation/pages/dashboard_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _subtitleController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _progressFade;
  late Animation<double> _glowAnim;

  bool _hasNavigated = false;

  // Neon green suave para fondo claro
  static const Color _neonGreen = Color(0xFF2E7D32);
  static const Color _neonGreenGlow = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Logo animation (0-800ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Text animation (400-1000ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Subtitle animation (800-1400ms)
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    // Progress animation (1200-1800ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Start animation sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _subtitleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget screen) {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          if (state.needsProfileCompletion) {
            _navigateToScreen(CompleteProfileScreen(user: state.user));
          } else {
            _navigateToScreen(const DashboardScreen());
          }
        } else if (state is Unauthenticated || state is AuthError) {
          _navigateToScreen(const LoginScreen());
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.surfaceGradient,
          ),
          child: Stack(
            children: [
              // Decorative circles con glow suave sobre fondo claro
              Positioned(
                top: -60,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neonGreen.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neonGreenGlow.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neonGreen.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo con neon glow suave sobre fondo claro
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: _neonGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: _neonGreen.withValues(alpha: _glowAnim.value * 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _neonGreenGlow.withValues(alpha: _glowAnim.value * 0.25),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: _neonGreen.withValues(alpha: _glowAnim.value * 0.12),
                                    blurRadius: 48,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/frogio_logo.png',
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (_, __, ___) => Text(
                                    'F',
                                    style: TextStyle(
                                      color: _neonGreen,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Montserrat',
                                      shadows: [
                                        Shadow(
                                          color: _neonGreenGlow.withValues(alpha: _glowAnim.value * 0.6),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Title con glow verde sobre fondo claro
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, _) {
                        return FadeTransition(
                          opacity: _textFade,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: Text(
                              'FROGIO',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                fontFamily: 'Montserrat',
                                shadows: [
                                  Shadow(
                                    color: _neonGreenGlow.withValues(alpha: _glowAnim.value * 0.4),
                                    blurRadius: 12,
                                  ),
                                  Shadow(
                                    color: _neonGreen.withValues(alpha: _glowAnim.value * 0.2),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    // Divider line con glow
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _textFade,
                          child: Container(
                            width: 48,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _neonGreen.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _neonGreenGlow.withValues(alpha: _glowAnim.value * 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Subtitle
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        'Solución Municipal Integral',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Progress indicator con glow verde
                    FadeTransition(
                      opacity: _progressFade,
                      child: SizedBox(
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            backgroundColor: _neonGreen.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom text
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Municipalidad de Santa Juana',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
