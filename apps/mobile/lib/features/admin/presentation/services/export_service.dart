// lib/features/admin/presentation/services/export_service.dart
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting admin data to CSV or PDF and sharing it.
class ExportService {
  /// Export rows to CSV and open the system share sheet.
  /// [headers] are the column titles.
  /// [rows] must have the same length as [headers].
  static Future<void> exportCsv({
    required String filenamePrefix,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${filenamePrefix}_$stamp.csv');

    final csv = const ListToCsvConverter().convert([headers, ...rows]);
    // Add BOM so Excel opens UTF-8 properly
    await file.writeAsString('\uFEFF$csv');

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: '${filenamePrefix}_$stamp',
    );
  }

  /// Export rows to PDF (tabular) with FROGIO header/footer and share it.
  static Future<void> exportPdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    String? generatedBy,
  }) async {
    final doc = pw.Document();
    final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Load FROGIO logo
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/icons/frogio_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    // Chunk rows to fit per page
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => _pdfHeader(title: title, subtitle: subtitle, logo: logo),
        footer: (ctx) => _pdfFooter(page: ctx.pageNumber, total: ctx.pagesCount, generatedBy: generatedBy, stamp: stamp),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Total de registros: ${rows.length}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final sanitized = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final file = File(
        '${dir.path}/${sanitized}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')], subject: title);
  }

  /// Open native print preview for a PDF.
  static Future<void> previewPdf({
    required String title,
    required String subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    String? generatedBy,
  }) async {
    final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load('assets/icons/frogio_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    await Printing.layoutPdf(
      name: title,
      onLayout: (format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            pageFormat: format.landscape,
            margin: const pw.EdgeInsets.all(28),
            header: (ctx) => _pdfHeader(title: title, subtitle: subtitle, logo: logo),
            footer: (ctx) => _pdfFooter(page: ctx.pageNumber, total: ctx.pagesCount, generatedBy: generatedBy, stamp: stamp),
            build: (ctx) => [
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            ],
          ),
        );
        return doc.save();
      },
    );
  }

  static pw.Widget _pdfHeader({
    required String title,
    required String subtitle,
    pw.ImageProvider? logo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.green800, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) pw.Image(logo, width: 40, height: 40),
          if (logo != null) pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                pw.SizedBox(height: 2),
                pw.Text(subtitle,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('FROGIO',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
              pw.Text('Municipalidad de Santa Juana',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfFooter({
    required int page,
    required int total,
    required String stamp,
    String? generatedBy,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
              'Generado: $stamp${generatedBy != null ? ' por $generatedBy' : ''}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text('Pagina $page de $total',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
