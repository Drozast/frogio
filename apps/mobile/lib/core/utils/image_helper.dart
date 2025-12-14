// lib/core/utils/image_helper.dart
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static const int maxFileSize = 1024 * 1024; // 1MB
  static const int profileImageQuality = 80;
  static const int reportImageQuality = 70;

  /// Comprimir imagen para foto de perfil
  static Future<File> compressProfileImage(File file) async {
    if (kIsWeb) {
      // En web, retornar el archivo sin comprimir
      return file;
    }
    return await _compressImage(file, profileImageQuality, maxWidth: 500, maxHeight: 500);
  }

  /// Comprimir imagen para reportes
  static Future<File> compressReportImage(File file) async {
    if (kIsWeb) {
      // En web, retornar el archivo sin comprimir
      return file;
    }
    return await _compressImage(file, reportImageQuality, maxWidth: 1024, maxHeight: 1024);
  }

  /// Comprimir imagen general
  static Future<File> _compressImage(
    File file, 
    int quality, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    // Solo comprimir en plataformas móviles
    if (kIsWeb) {
      return file;
    }

    try {
      final dir = path.dirname(file.path);
      final ext = path.extension(file.path);
      final fileName = path.basenameWithoutExtension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(dir, '${fileName}_compressed_$timestamp$ext');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth != null ? min(maxWidth, 2048) : 2048,
        minHeight: maxHeight != null ? min(maxHeight, 2048) : 2048,
        rotate: 0,
      );

      if (result != null) {
        return File(result.path);
      } else {
        throw Exception('Error al comprimir imagen');
      }
    } catch (e) {
      throw Exception('Error en compresión: ${e.toString()}');
    }
  }

  /// Verificar tamaño de archivo
  static Future<bool> isFileSizeValid(File file, {int? maxSizeBytes}) async {
    if (kIsWeb) {
      // En web, siempre retornar true o implementar lógica alternativa
      return true;
    }
    
    final size = await file.length();
    return size <= (maxSizeBytes ?? maxFileSize);
  }

  /// Obtener tamaño legible de archivo
  static String getReadableFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}