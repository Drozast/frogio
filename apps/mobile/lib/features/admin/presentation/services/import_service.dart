// lib/features/admin/presentation/services/import_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/network/auth_http_client.dart';
import '../../../../di/injection_container_api.dart' as di;

/// Available historical CSV templates bundled with the app.
enum ImportDataset {
  citations('Citaciones',
      'number,target_name,target_rut,target_address,reason,citation_type,created_at',
      'plantilla_citaciones.csv',
      '/api/admin/imports/citations'),
  reports('Denuncias',
      'title,description,category,priority,status,latitude,longitude,address,citizen_name,citizen_phone,created_at',
      'plantilla_denuncias.csv',
      '/api/admin/imports/reports'),
  vehicles('Vehiculos',
      'plate,brand,model,year,type,status,current_km,color',
      'plantilla_vehiculos.csv',
      '/api/admin/imports/vehicles'),
  users('Usuarios',
      'email,first_name,last_name,rut,phone,role,password',
      'plantilla_usuarios.csv',
      '/api/admin/imports/users');

  const ImportDataset(this.label, this.headersCsv, this.filename, this.endpoint);

  final String label;
  final String headersCsv;
  final String filename;
  final String endpoint;

  List<String> get headers => headersCsv.split(',');
}

class ImportSummary {
  final int inserted;
  final int failed;
  final List<String> errors;

  ImportSummary({required this.inserted, required this.failed, required this.errors});

  factory ImportSummary.fromJson(Map<String, dynamic> json) {
    return ImportSummary(
      inserted: (json['inserted'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      errors: ((json['errors'] as List?)?.map((e) => e.toString()).toList()) ?? [],
    );
  }
}

class ImportService {
  /// Let admin download/share a blank template they can fill in.
  static Future<void> shareTemplate(ImportDataset ds) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${ds.filename}');
    // First, try reading a bundled template from assets/templates/
    try {
      final bytes = await rootBundle.load('assets/templates/${ds.filename}');
      await file.writeAsBytes(bytes.buffer.asUint8List());
    } catch (_) {
      // Fallback: generate header-only CSV
      final content = '\uFEFF${ds.headersCsv}\n';
      await file.writeAsString(content);
    }
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Plantilla ${ds.label}',
    );
  }

  /// Pick a CSV file from device storage.
  static Future<File?> pickCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.first.path;
    if (path == null) return null;
    return File(path);
  }

  /// Parse a local CSV into rows of maps (header-driven).
  static Future<List<Map<String, String>>> parseCsv(File file) async {
    final content = await file.readAsString();
    // Strip BOM
    final clean = content.startsWith('\uFEFF') ? content.substring(1) : content;
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(clean);
    if (rows.isEmpty) return [];
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final out = <Map<String, String>>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final map = <String, String>{};
      for (int j = 0; j < headers.length && j < row.length; j++) {
        map[headers[j]] = row[j]?.toString() ?? '';
      }
      // Skip fully empty rows
      if (map.values.every((v) => v.trim().isEmpty)) continue;
      out.add(map);
    }
    return out;
  }

  /// POST the parsed rows to the backend endpoint.
  static Future<ImportSummary> uploadRows({
    required ImportDataset dataset,
    required List<Map<String, String>> rows,
  }) async {
    final client = di.sl<AuthHttpClient>();
    final res = await client.post(
      Uri.parse('${ApiConfig.activeBaseUrl}${dataset.endpoint}'),
      body: json.encode({'rows': rows}),
    );
    if (res.statusCode >= 400) {
      throw Exception('Error al importar: ${res.statusCode} ${res.body}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return ImportSummary.fromJson(body);
  }
}
