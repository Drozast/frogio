import 'package:equatable/equatable.dart';

class PanicAlertEntity extends Equatable {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String? address;
  final String message;
  final String? contactPhone;
  final String status;
  final String? responderId;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PanicAlertEntity({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.message,
    this.contactPhone,
    required this.status,
    this.responderId,
    this.respondedAt,
    this.resolvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isResponding => status == 'responding';
  bool get isResolved => status == 'resolved';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [
        id,
        userId,
        latitude,
        longitude,
        address,
        message,
        contactPhone,
        status,
        responderId,
        respondedAt,
        resolvedAt,
        notes,
        createdAt,
        updatedAt,
      ];
}
