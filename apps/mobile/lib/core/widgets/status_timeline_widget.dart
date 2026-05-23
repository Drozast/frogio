// lib/core/widgets/status_timeline_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Entrada genérica de timeline — compatible con reportes y citaciones.
class TimelineEntry {
  final DateTime timestamp;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String? comment;
  final String? userName;
  /// true cuando es un seguimiento del inspector sin cambio de estado
  final bool isFollowUp;
  /// URLs de fotos adjuntas a esta entrada
  final List<String> attachments;

  const TimelineEntry({
    required this.timestamp,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.comment,
    this.userName,
    this.isFollowUp = false,
    this.attachments = const [],
  });
}

/// Widget de timeline vertical reutilizable.
/// Úsalo en: ReportDetailScreen, detalle de denuncia del ciudadano, CitationDetailScreen.
class StatusTimelineWidget extends StatelessWidget {
  final List<TimelineEntry> entries;
  /// Si true, la primera entrada (más reciente) se resalta como estado actual.
  final bool highlightFirst;

  const StatusTimelineWidget({
    super.key,
    required this.entries,
    this.highlightFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Sin historial de cambios',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isFirst = index == 0;
        final isLast = index == entries.length - 1;
        final isCurrent = highlightFirst && isFirst;

        return _TimelineItem(
          entry: entry,
          isCurrent: isCurrent,
          isLast: isLast,
        );
      },
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final TimelineEntry entry;
  final bool isCurrent;
  final bool isLast;

  const _TimelineItem({
    required this.entry,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> {
  bool _showPhotos = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(e.timestamp.toLocal());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Columna izquierda: línea + círculo
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Línea superior (excepto primer item)
                if (!widget.isCurrent)
                  Container(
                    width: 2,
                    height: 12,
                    color: Colors.grey.shade300,
                  )
                else
                  const SizedBox(height: 12),

                // Círculo de estado
                Container(
                  width: widget.isCurrent ? 36 : 28,
                  height: widget.isCurrent ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isCurrent
                        ? e.statusColor
                        : e.statusColor.withValues(alpha: 0.15),
                    border: widget.isCurrent
                        ? Border.all(color: e.statusColor, width: 3)
                        : null,
                    boxShadow: widget.isCurrent
                        ? [
                            BoxShadow(
                              color: e.statusColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    e.isFollowUp ? Icons.note_add_outlined : e.statusIcon,
                    size: widget.isCurrent ? 18 : 14,
                    color: widget.isCurrent ? Colors.white : e.statusColor,
                  ),
                ),

                // Línea inferior (excepto último item)
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),

          // Columna derecha: contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado + badge follow-up
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.isFollowUp ? 'Seguimiento' : e.statusLabel,
                          style: TextStyle(
                            fontSize: widget.isCurrent ? 15 : 14,
                            fontWeight: widget.isCurrent
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: widget.isCurrent
                                ? e.statusColor
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: e.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Actual',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: e.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2),

                  // Fecha y autor
                  Text(
                    e.userName != null
                        ? '$dateStr • ${e.userName}'
                        : dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  // Comentario / razón del cambio
                  if (e.comment != null && e.comment!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        e.comment!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  // Fotos adjuntas
                  if (e.attachments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showPhotos = !_showPhotos),
                      child: Row(
                        children: [
                          Icon(
                            _showPhotos
                                ? Icons.expand_less
                                : Icons.photo_library_outlined,
                            size: 14,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showPhotos
                                ? 'Ocultar fotos'
                                : '${e.attachments.length} foto(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showPhotos) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: e.attachments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (ctx, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              e.attachments[i],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
