// lib/core/utils/image_helper.dart
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  static const int maxFileSize = 1024 * 1024; // 1MB
  static const int profileImageQuality = 80;
  static const int reportImageQuality = 70;

  /// Comprimir imagen para foto de perfil
  static Future<File> compressProfileImage(File file) async {
    if (kIsWeb) {
      return file;
    }
    return await _compressImage(file, profileImageQuality, maxWidth: 500, maxHeight: 500);
  }

  /// Comprimir imagen para reportes
  static Future<File> compressReportImage(File file) async {
    if (kIsWeb) {
      return file;
    }
    return await _compressImage(file, reportImageQuality, maxWidth: 1024, maxHeight: 1024);
  }

  /// Comprimir imagen general usando el paquete image
  static Future<File> _compressImage(
    File file,
    int quality, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    if (kIsWeb) {
      return file;
    }

    try {
      // Leer la imagen
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // Redimensionar si es necesario
      img.Image resized = image;
      if (maxWidth != null || maxHeight != null) {
        final targetWidth = maxWidth ?? image.width;
        final targetHeight = maxHeight ?? image.height;

        // Mantener proporcion
        final aspectRatio = image.width / image.height;
        int newWidth = targetWidth;
        int newHeight = targetHeight;

        if (image.width > targetWidth || image.height > targetHeight) {
          if (aspectRatio > 1) {
            newWidth = targetWidth;
            newHeight = (targetWidth / aspectRatio).round();
          } else {
            newHeight = targetHeight;
            newWidth = (targetHeight * aspectRatio).round();
          }
          resized = img.copyResize(image, width: newWidth, height: newHeight);
        }
      }

      // Codificar como JPEG con la calidad especificada
      final compressedBytes = img.encodeJpg(resized, quality: quality);

      // Guardar en archivo temporal
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(tempDir.path, 'compressed_$timestamp.jpg');

      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      throw Exception('Error en compresion: ${e.toString()}');
    }
  }

  /// Verificar tamano de archivo
  static Future<bool> isFileSizeValid(File file, {int? maxSizeBytes}) async {
    if (kIsWeb) {
      return true;
    }

    final size = await file.length();
    return size <= (maxSizeBytes ?? maxFileSize);
  }

  /// Obtener tamano legible de archivo
  static String getReadableFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
