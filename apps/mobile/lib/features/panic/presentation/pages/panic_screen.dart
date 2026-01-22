import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../di/injection_container_api.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';
import '../bloc/panic_state.dart';
import '../widgets/panic_button.dart';

class PanicScreen extends StatefulWidget {
  final UserEntity user;

  const PanicScreen({super.key, required this.user});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;
  String? _locationError;
  String? _activeAlertId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Permiso de ubicación denegado';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Permisos de ubicación denegados permanentemente. Habilítalos en configuración.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Obtener ubicación
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtener dirección
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}';
        }
      } catch (_) {
        // Geocoding puede fallar, continuar sin dirección
      }

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al obtener ubicación: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _sendPanicAlert(BuildContext context) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<PanicBloc>().add(
          SendPanicAlertEvent(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            address: _currentAddress,
            message: 'Alerta de emergencia desde la app',
            contactPhone: widget.user.phoneNumber,
          ),
        );
  }

  void _cancelAlert(BuildContext context) {
    if (_activeAlertId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar alerta'),
        content: const Text('¿Estás seguro de que quieres cancelar la alerta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PanicBloc>().add(
                    CancelPanicAlertEvent(alertId: _activeAlertId!),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PanicBloc>(),
      child: BlocConsumer<PanicBloc, PanicState>(
        listener: (context, state) {
          if (state is PanicAlertSent) {
            setState(() {
              _activeAlertId = state.alert.id;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Alerta enviada! Ayuda en camino.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          } else if (state is PanicAlertCancelled) {
            setState(() {
              _activeAlertId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alerta cancelada'),
                backgroundColor: Colors.orange,
              ),
            );
            context.read<PanicBloc>().add(const ResetPanicStateEvent());
          } else if (state is PanicError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PanicLoading;
          final isActive = state is PanicAlertSent || _activeAlertId != null;

          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: AppBar(
              title: const Text(
                'EMERGENCIA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Info del usuario
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.red.shade100,
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (widget.user.phoneNumber != null)
                                      Text(
                                        widget.user.phoneNumber!,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Ubicación
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: _locationError != null
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Tu ubicación',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!_isLoadingLocation)
                                    IconButton(
                                      icon: const Icon(Icons.refresh),
                                      onPressed: _getCurrentLocation,
                                      tooltip: 'Actualizar ubicación',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingLocation)
                                const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Obteniendo ubicación...'),
                                  ],
                                )
                              else if (_locationError != null)
                                Text(
                                  _locationError!,
                                  style: const TextStyle(color: Colors.red),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_currentAddress != null)
                                      Text(
                                        _currentAddress!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    if (_currentPosition != null)
                                      Text(
                                        'Coords: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botón de pánico
                      PanicButton(
                        onPanicTriggered: () => _sendPanicAlert(context),
                        isLoading: isLoading,
                        isActive: isActive,
                      ),

                      const SizedBox(height: 24),

                      // Botón cancelar (solo si hay alerta activa)
                      if (isActive && _activeAlertId != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelAlert(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar alerta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Información adicional
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  '¿Cómo funciona?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '1. Mantén presionado el botón SOS por 2 segundos\n'
                              '2. Tu ubicación y datos serán enviados automáticamente\n'
                              '3. Inspectores y administradores recibirán una notificación urgente\n'
                              '4. Ayuda será enviada a tu ubicación',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
