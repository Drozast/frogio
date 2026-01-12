import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vehicle_entity.dart';
import '../bloc/vehicle_bloc.dart';
import '../widgets/vehicle_card.dart';
import 'start_trip_page.dart';

class VehicleSelectionPage extends StatefulWidget {
  final String userId;
  final String userName;

  const VehicleSelectionPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<VehicleBloc>().add(
          const LoadVehiclesByStatusEvent(
            status: VehicleStatus.available,
            muniId: 'santa_juana',
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Vehículo'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por patente o modelo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Vehicle List
          Expanded(
            child: BlocBuilder<VehicleBloc, VehicleState>(
              builder: (context, state) {
                if (state is VehicleLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is VehicleError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<VehicleBloc>().add(
                                  const LoadVehiclesByStatusEvent(
                                    status: VehicleStatus.available,
                                    muniId: 'santa_juana',
                                  ),
                                );
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is VehiclesLoaded) {
                  final vehicles = state.filteredVehicles
                      .where((v) => v.status == VehicleStatus.available)
                      .where((v) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery.toLowerCase();
                    return v.plate.toLowerCase().contains(query) ||
                        v.model.toLowerCase().contains(query) ||
                        v.brand.toLowerCase().contains(query);
                  }).toList();

                  if (vehicles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay vehículos disponibles'
                                : 'No se encontraron vehículos',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<VehicleBloc>().add(
                            const LoadVehiclesByStatusEvent(
                              status: VehicleStatus.available,
                              muniId: 'santa_juana',
                            ),
                          );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VehicleCard(
                            vehicle: vehicle,
                            onTap: () => _onVehicleSelected(vehicle),
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onVehicleSelected(VehicleEntity vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartTripPage(
          vehicle: vehicle,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }
}
