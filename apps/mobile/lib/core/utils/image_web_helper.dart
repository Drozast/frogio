// lib/core/utils/image_web_helper.dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageWebHelper {
  static Future<Uint8List> compressImageBytes(
    Uint8List imageBytes, {
    int maxWidth = 500,
    int maxHeight = 500,
    int quality = 80,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('No se pudo decodificar la imagen');

      img.Image resized = image;
      if (image.width > maxWidth || image.height > maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxHeight : null,
        );
      }

      final compressedBytes = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw Exception('Error al comprimir imagen: $e');
    }
  }
}