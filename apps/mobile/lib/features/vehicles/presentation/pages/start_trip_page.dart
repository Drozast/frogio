import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/injection_container_api.dart' as di;
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
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Iniciar Viaje'),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 32,
                            color: Theme.of(context).primaryColor,
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
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.vehicle.brand} ${widget.vehicle.model}',
                                style: TextStyle(
                                  fontSize: 14,
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
                const SizedBox(height: 24),

                // Usage Type
                const Text(
                  'Tipo de Uso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UsageType.values.map((type) {
                    final isSelected = _selectedUsageType == type;
                    return ChoiceChip(
                      label: Text(_getUsageTypeLabel(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedUsageType = type);
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Start KM
                TextFormField(
                  controller: _startKmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilometraje Inicial',
                    hintText: 'Ingrese el kilometraje actual',
                    prefixIcon: Icon(Icons.speed),
                    suffixText: 'km',
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Propósito del Viaje (opcional)',
                    hintText: 'Describa brevemente el objetivo del viaje',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // GPS Tracking Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El GPS se activará automáticamente para registrar tu recorrido.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startTrip,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow),
                              SizedBox(width: 8),
                              Text(
                                'Iniciar Viaje',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
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
