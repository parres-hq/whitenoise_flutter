import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mime/mime.dart' show lookupMimeType;

class ImageUtils {
  static final _logger = Logger('ImageUtils');

  static Future<String?> getMimeTypeFromPath(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        _logger.warning('File does not exist: $filePath, defaulting to image/jpeg');
        return null;
      }

      final mimeType = lookupMimeType(filePath);
      return mimeType;
    } catch (e) {
      _logger.severe('Error reading file for MIME type detection: $filePath, error: $e');
      return null;
    }
  }
}
