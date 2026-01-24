// lib/features/inspector/presentation/pages/report_detail_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/api_config.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  static const Color _primaryGreen = Color(0xFF1B5E20);

  final _resolutionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isClosing = false;
  String _selectedResolutionType = 'resolved';

  final List<Map<String, String>> _resolutionTypes = [
    {'value': 'resolved', 'label': 'Resuelta', 'description': 'El problema fue solucionado'},
    {'value': 'rejected', 'label': 'Rechazada', 'description': 'No procede o es falsa'},
    {'value': 'duplicate', 'label': 'Duplicada', 'description': 'Ya existe otra denuncia igual'},
  ];

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  Future<void> _closeReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isClosing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final baseUrl = ApiConfig.activeBaseUrl;

      final response = await http.patch(
        Uri.parse('$baseUrl/api/reports/${widget.report['id']}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': _selectedResolutionType,
          'resolution': _resolutionController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedResolutionType == 'resolved'
                  ? 'Denuncia cerrada exitosamente'
                  : 'Denuncia actualizada'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al cerrar denuncia');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final title = report['title']?.toString() ?? 'Sin título';
    final description = report['description']?.toString() ?? 'Sin descripción';
    final status = report['status']?.toString() ?? '';
    final reportType = report['type']?.toString() ?? report['report_type']?.toString() ?? '';
    final address = report['address']?.toString() ?? 'Sin dirección';
    final createdAt = report['created_at']?.toString() ?? '';
    final photos = report['photos'] as List<dynamic>? ?? [];
    final priority = report['priority']?.toString() ?? 'medium';

    final isOpen = status.toLowerCase() != 'resolved' &&
        status.toLowerCase() != 'resuelto' &&
        status.toLowerCase() != 'rejected' &&
        status.toLowerCase() != 'rechazado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Denuncia'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: _getStatusColor(status),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(reportType),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusBadge(status),
                                const SizedBox(width: 8),
                                _buildPriorityBadge(priority),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type
                  _buildDetailRow(
                    Icons.category_outlined,
                    'Tipo',
                    _getReportTypeLabel(reportType),
                  ),
                  const Divider(height: 24),

                  // Address
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Ubicación',
                    address,
                  ),
                  const Divider(height: 24),

                  // Date
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'Fecha',
                    _formatDate(createdAt),
                  ),
                  const Divider(height: 24),

                  // Description
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),

                  // Photos
                  if (photos.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Fotos adjuntas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          final photoUrl = photos[index].toString();
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photoUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Resolution section (only for open reports)
                  if (isOpen) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _primaryGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.task_alt, color: _primaryGreen),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cerrar Denuncia',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Resolution type
                            const Text(
                              'Tipo de resolución',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_resolutionTypes.map((type) => RadioListTile<String>(
                                  value: type['value']!,
                                  groupValue: _selectedResolutionType,
                                  onChanged: (value) {
                                    setState(() => _selectedResolutionType = value!);
                                  },
                                  title: Text(type['label']!),
                                  subtitle: Text(
                                    type['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: _primaryGreen,
                                ))),

                            const SizedBox(height: 16),

                            // Resolution notes
                            TextFormField(
                              controller: _resolutionController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Descripción de la resolución *',
                                hintText: 'Describe qué se hizo para resolver el problema...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _primaryGreen, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor describe la resolución';
                                }
                                if (value.trim().length < 10) {
                                  return 'La descripción debe tener al menos 10 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isClosing ? null : _closeReport,
                                icon: _isClosing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: Text(
                                  _isClosing ? 'Cerrando...' : 'Cerrar Denuncia',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show resolution for closed reports
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Denuncia ${_getStatusLabel(status)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ],
                          ),
                          if (report['resolution'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              report['resolution'].toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'alta':
        color = Colors.red;
        label = 'Alta';
      case 'medium':
      case 'media':
        color = Colors.orange;
        label = 'Media';
      case 'low':
      case 'baja':
        color = Colors.blue;
        label = 'Baja';
      default:
        color = Colors.grey;
        label = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'submitted':
        return Colors.orange;
      case 'en_proceso':
      case 'in_progress':
      case 'inprogress':
        return Colors.blue;
      case 'resuelto':
      case 'resolved':
        return Colors.green;
      case 'rechazado':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'submitted':
        return 'Pendiente';
      case 'en_proceso':
      case 'in_progress':
      case 'inprogress':
        return 'En Proceso';
      case 'resuelto':
      case 'resolved':
        return 'Resuelta';
      case 'rechazado':
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }

  IconData _getCategoryIcon(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'complaint':
      case 'denuncia':
        return Icons.report_problem;
      case 'suggestion':
      case 'sugerencia':
        return Icons.lightbulb_outline;
      case 'emergency':
      case 'emergencia':
        return Icons.warning;
      case 'request':
      case 'solicitud':
        return Icons.assignment;
      case 'incident':
      case 'incidente':
        return Icons.error_outline;
      default:
        return Icons.description;
    }
  }

  String _getReportTypeLabel(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'complaint':
        return 'Denuncia';
      case 'suggestion':
        return 'Sugerencia';
      case 'emergency':
        return 'Emergencia';
      case 'request':
        return 'Solicitud';
      case 'incident':
        return 'Incidente';
      default:
        return reportType.isNotEmpty ? reportType : 'General';
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Fecha no disponible';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
