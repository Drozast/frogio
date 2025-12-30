import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/session_timeout_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../di/injection_container_api.dart' as di;
import '../../../features/auth/domain/entities/user_entity.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/auth/presentation/bloc/profile/profile_bloc.dart';
import '../../../features/auth/presentation/pages/edit_profile_screen.dart';
import '../../../features/auth/presentation/pages/login_screen.dart';
import '../../../features/auth/presentation/widgets/profile_avatar.dart';
import '../../../features/citizen/presentation/pages/create_report_screen.dart';
import '../../../features/citizen/presentation/pages/my_reports_screen.dart';
import '../widgets/dashboard_menu_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();

    // Inicializar servicio de timeout de sesión
    final sessionService = di.sl<SessionTimeoutService>();
    sessionService.onSessionTimeout = () {
      if (mounted) {
        context.read<AuthBloc>().add(SignOutEvent());
      }
    };
    sessionService.startTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<ProfileBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return _buildDashboard(state.user);
            } else if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cerrando sesión...'),
                    ],
                  ),
                ),
              );
            } else {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(UserEntity user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FROGIO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _showLogoutConfirmationDialog();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Actualizar timeout de sesión en actividad del usuario
          di.sl<SessionTimeoutService>().updateLastActivityTime();
        },
        child: _getPage(_currentIndex, user),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Actualizar timeout de sesión en navegación
          di.sl<SessionTimeoutService>().updateLastActivityTime();
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: _getNavigationItemsForRole(user.role),
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavigationItemsForRole(String role) {
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Inicio',
      ),
    ];

    // Ítems específicos por rol
    switch (role) {
      case 'citizen':
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.report),
          label: 'Denuncias',
        ));
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.question_answer),
          label: 'Consultas',
        ));
        break;
      case 'inspector':
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Tareas',
        ));
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.gavel),
          label: 'Infracciones',
        ));
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Vehículos',
        ));
        break;
      case 'admin':
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.insights),
          label: 'Estadísticas',
        ));
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Usuarios',
        ));
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configuración',
        ));
        break;
    }

    // Común para todos los roles
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Perfil',
    ));

    return items;
  }

  Widget _getPage(int index, UserEntity user) {
    switch (user.role) {
      case 'citizen':
        switch (index) {
          case 0:
            return _buildHomeDashboard(user);
          case 1:
            return MyReportsScreen(userId: user.id);
          case 2:
            return const Center(
              child: Text(
                'Consultas - En desarrollo',
                style: TextStyle(fontSize: 20),
              ),
            );
          case 3:
            return _buildProfilePage(user);
          default:
            return _buildHomeDashboard(user);
        }
      default:
        if (index == 0) {
          return _buildHomeDashboard(user);
        } else if (index == _getNavigationItemsForRole(user.role).length - 1) {
          return _buildProfilePage(user);
        } else {
          return Center(
            child: Text(
              'Página en desarrollo: $index',
              style: const TextStyle(fontSize: 20),
            ),
          );
        }
    }
  }

  Widget _buildHomeDashboard(UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida con animación
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: const Offset(0, 0),
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    )),
                    child: ProfileAvatar(
                      user: user,
                      radius: 50,
                      isEditable: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, ${user.displayName}!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rol: ${_getRoleDisplayName(user.role)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!user.isProfileComplete) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.warningColor),
                            ),
                            child: const Text(
                              'Completa tu perfil',
                              style: TextStyle(
                                color: AppTheme.warningColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Título de sección
          const Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Cuadrícula de acceso rápido
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: _getQuickAccessItemsForRole(user),
          ),
          const SizedBox(height: 24),
          // Sección de actividad reciente
          const Text(
            'Actividad Reciente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Marcador de posición para actividad reciente
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No hay actividad reciente',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(UserEntity user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de perfil con avatar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ProfileAvatar(
                    user: user,
                    radius: 40,
                    isEditable: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Perfil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Estado del perfil
          Card(
            color: user.isProfileComplete 
                ? AppTheme.successColor.withValues(alpha: 0.1)
                : AppTheme.warningColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    user.isProfileComplete 
                        ? Icons.check_circle 
                        : Icons.warning,
                    color: user.isProfileComplete 
                        ? AppTheme.successColor 
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isProfileComplete 
                              ? 'Perfil Completo' 
                              : 'Perfil Incompleto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: user.isProfileComplete 
                                ? AppTheme.successColor 
                                : AppTheme.warningColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.isProfileComplete
                              ? 'Puedes acceder a todas las funciones'
                              : 'Completa tu perfil para crear denuncias',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Información personal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileRow('Teléfono', user.phoneNumber ?? 'No especificado'),
                  _buildProfileRow('Dirección', user.address ?? 'No especificada'),
                  _buildProfileRow('Rol', _getRoleDisplayName(user.role)),
                  _buildProfileRow(
                    'Miembro desde', 
                    '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  List<Widget> _getQuickAccessItemsForRole(UserEntity user) {
    final List<Widget> items = [];

    switch (user.role) {
      case 'citizen':
        items.addAll([
          DashboardMenuItem(
            title: 'Nueva Denuncia',
            icon: Icons.add_circle,
            color: AppTheme.primaryColor,
            onTap: () {
              if (!user.isProfileComplete) {
                _showCompleteProfileDialog();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReportScreen(userId: user.id),
                ),
              );
            },
          ),
          DashboardMenuItem(
            title: 'Mis Denuncias',
            icon: Icons.list_alt,
            color: AppTheme.secondaryColor,
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          DashboardMenuItem(
            title: 'Nueva Consulta',
            icon: Icons.question_answer,
            color: AppTheme.darkGreen,
            onTap: () {
              if (!user.isProfileComplete) {
                _showCompleteProfileDialog();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad en desarrollo'),
                ),
              );
            },
          ),
          DashboardMenuItem(
            title: 'Mis Consultas',
            icon: Icons.question_mark,
            color: Colors.teal,
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
        ]);
        break;
      case 'inspector':
        items.addAll([
          DashboardMenuItem(
            title: 'Tareas Pendientes',
            icon: Icons.assignment,
            color: AppTheme.primaryColor,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Nueva Infracción',
            icon: Icons.gavel,
            color: AppTheme.secondaryColor,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Registro Vehículo',
            icon: Icons.directions_car,
            color: AppTheme.darkGreen,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Mapa',
            icon: Icons.map,
            color: Colors.teal,
            onTap: () {},
          ),
        ]);
        break;
      case 'admin':
        items.addAll([
          DashboardMenuItem(
            title: 'Estadísticas',
            icon: Icons.bar_chart,
            color: AppTheme.primaryColor,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Usuarios',
            icon: Icons.people,
            color: AppTheme.secondaryColor,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Denuncias Pendientes',
            icon: Icons.report_problem,
            color: AppTheme.darkGreen,
            onTap: () {},
          ),
          DashboardMenuItem(
            title: 'Configuración',
            icon: Icons.settings,
            color: Colors.teal,
            onTap: () {},
          ),
        ]);
        break;
      default:
        items.addAll([
          DashboardMenuItem(
            title: 'Perfil',
            icon: Icons.person,
            color: AppTheme.primaryColor,
            onTap: () {
              setState(() {
                _currentIndex = _getNavigationItemsForRole(user.role).length - 1;
              });
            },
          ),
        ]);
    }

    return items;
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

  void _showCompleteProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Perfil Incompleto'),
        content: const Text(
          'Para crear denuncias necesitas completar tu perfil con nombre, teléfono y dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final currentState = context.read<AuthBloc>().state;
              if (currentState is Authenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: currentState.user),
                  ),
                );
              }
            },
            child: const Text('Completar Perfil'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(SignOutEvent());
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}