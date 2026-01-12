import 'package:flutter/material.dart';

import '../../domain/entities/vehicle_entity.dart';

class VehicleCard extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vehicle Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getTypeColor(vehicle.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(vehicle.type),
                  size: 32,
                  color: _getTypeColor(vehicle.type),
                ),
              ),
              const SizedBox(width: 16),

              // Vehicle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plate.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(vehicle.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusLabel(vehicle.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(vehicle.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTypeLabel(vehicle.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.bicycle:
        return Icons.pedal_bike;
    }
  }

  Color _getTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Colors.blue;
      case VehicleType.truck:
        return Colors.orange;
      case VehicleType.motorcycle:
        return Colors.purple;
      case VehicleType.van:
        return Colors.teal;
      case VehicleType.bicycle:
        return Colors.green;
    }
  }

  String _getTypeLabel(VehicleType type) {
    return type.displayName;
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.available:
        return Colors.green;
      case VehicleStatus.inUse:
        return Colors.blue;
      case VehicleStatus.maintenance:
        return Colors.orange;
      case VehicleStatus.outOfService:
        return Colors.red;
    }
  }

  String _getStatusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.available:
        return 'Disponible';
      case VehicleStatus.inUse:
        return 'En uso';
      case VehicleStatus.maintenance:
        return 'En mantención';
      case VehicleStatus.outOfService:
        return 'Fuera de servicio';
    }
  }
}
