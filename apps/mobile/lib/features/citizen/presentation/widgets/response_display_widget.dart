// lib/features/citizen/presentation/widgets/response_display_widget.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

class ResponseDisplayWidget extends StatelessWidget {
  final List<ReportResponse> responses;
  final bool showPrivateResponses;
  final String? currentUserRole;

  const ResponseDisplayWidget({
    super.key,
    required this.responses,
    this.showPrivateResponses = false,
    this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final filteredResponses = responses.where((response) {
      if (response.isPublic) return true;
      if (showPrivateResponses && (currentUserRole == 'admin' || currentUserRole == 'inspector')) {
        return true;
      }
      return false;
    }).toList();

    if (filteredResponses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredResponses.length,
      itemBuilder: (context, index) {
        return _buildResponseCard(filteredResponses[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Sin respuestas aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las respuestas del municipio aparecerán aquí',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(ReportResponse response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponseHeader(response),
            const SizedBox(height: 12),
            _buildResponseContent(response),
            if (response.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildAttachments(response.attachments),
            ],
            const SizedBox(height: 8),
            _buildResponseFooter(response),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseHeader(ReportResponse response) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            response.responderName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    response.responderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildRoleBadge(response.responderRole),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(response.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildResponseTypeBadge(response.responseType),
      ],
    );
  }

  Widget _buildResponseContent(ReportResponse response) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        response.message,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildAttachments(List<String> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Archivos adjuntos:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: attachments[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResponseFooter(ReportResponse response) {
    return Row(
      children: [
        if (!response.isPublic)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Privado',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (response.urgency != 'Normal')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getUrgencyColor(response.urgency).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              response.urgency,
              style: TextStyle(
                color: _getUrgencyColor(response.urgency),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(String? role) {
    if (role == null) return const SizedBox.shrink();
    
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.purple;
        break;
      case 'inspector':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResponseTypeBadge(String? type) {
    if (type == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Baja': return Colors.green;
      case 'Normal': return Colors.blue;
      case 'Alta': return Colors.orange;
      case 'Urgente': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// Modelo para las respuestas
class ReportResponse {
  final String id;
  final String responderId;
  final String responderName;
  final String? responderRole;
  final String message;
  final List<String> attachments;
  final bool isPublic;
  final String? responseType;
  final String urgency;
  final DateTime createdAt;

  ReportResponse({
    required this.id,
    required this.responderId,
    required this.responderName,
    this.responderRole,
    required this.message,
    this.attachments = const [],
    this.isPublic = true,
    this.responseType,
    this.urgency = 'Normal',
    required this.createdAt,
  });
}