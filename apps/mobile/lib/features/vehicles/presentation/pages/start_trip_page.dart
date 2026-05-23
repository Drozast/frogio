import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../di/injection_container_api.dart' as di;
import '../../data/services/trip_tracking_service.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/vehicle_log_entity.dart';
import '../bloc/vehicle_bloc.dart';
import 'active_trip_page.dart';

class StartTripPage extends StatefulWidget {
  final VehicleEntity vehicle;
  final String userId;
  final String userName;

  const StartTripPage({
    super.key,
    required this.vehicle,
    required this.userId,
    required this.userName,
  });

  @override
  State<StartTripPage> createState() => _StartTripPageState();
}

class _StartTripPageState extends State<StartTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _startKmController = TextEditingController();
  final _purposeController = TextEditingController();

  UsageType _selectedUsageType = UsageType.patrol;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startKmController.text = widget.vehicle.currentKm.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _startKmController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listener: (context, state) {
        if (state is VehicleUsageStarted) {
          // Start background GPS tracking
          TripTrackingService().startTrip(logId: state.logId, plate: widget.vehicle.plate);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => di.sl<VehicleBloc>(),
                child: ActiveTripPage(
                  vehicleLogId: state.logId,
                  vehicle: widget.vehicle,
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            ),
          );
        } else if (state is VehicleError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.emergency,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Iniciar Viaje'),
          backgroundColor: AppTheme.surfaceWhite,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                    boxShadow: AppTheme.shadowSmall,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.shadowSmall,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          size: 32,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.vehicle.plate.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.vehicle.brand} ${widget.vehicle.model}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Usage Type Label
                const Text(
                  'Tipo de Uso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UsageType.values.map((type) {
                    final isSelected = _selectedUsageType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedUsageType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.2)
                              : AppTheme.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary.withValues(alpha: 0.7)
                                : AppTheme.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: isSelected ? AppTheme.shadowSmall : null,
                        ),
                        child: Text(
                          _getUsageTypeLabel(type),
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Start KM
                TextFormField(
                  controller: _startKmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Kilometraje Inicial',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    hintText: 'Ingrese el kilometraje actual',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(Icons.speed, color: AppTheme.primary),
                    suffixText: 'km',
                    suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.emergency),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.emergency,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el kilometraje inicial';
                    }
                    final km = double.tryParse(value);
                    if (km == null || km < 0) {
                      return 'Ingrese un valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Purpose (optional)
                TextFormField(
                  controller: _purposeController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Propósito del Viaje (opcional)',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    hintText: 'Describa brevemente el objetivo del viaje',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(
                      Icons.description,
                      color: AppTheme.primary,
                    ),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceWhite,
                  ),
                ),
                const SizedBox(height: 24),

                // GPS Tracking Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.15)),
                    boxShadow: AppTheme.shadowSmall,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.gps_fixed,
                          color: AppTheme.primaryDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'El GPS se activará automáticamente para registrar tu recorrido.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Button
                _isLoading
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startTrip,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Iniciar Viaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startTrip() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<VehicleBloc>().add(
          StartVehicleUsageEvent(
            vehicleId: widget.vehicle.id,
            driverId: widget.userId,
            driverName: widget.userName,
            startKm: double.parse(_startKmController.text),
            usageType: _selectedUsageType,
            purpose: _purposeController.text.isNotEmpty
                ? _purposeController.text
                : null,
          ),
        );
  }

  String _getUsageTypeLabel(UsageType type) {
    return type.displayName;
  }
}
