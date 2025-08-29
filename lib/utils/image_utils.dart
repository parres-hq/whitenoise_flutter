import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mime/mime.dart' show lookupMimeType;

class ImageUtils {
  static final _logger = Logger('ImageUtils');

  static Future<String?> getMimeTypeFromPath(String filePath) async {
    try {
      final file = File(filePath);
      final fileExists = file.existsSync();
      if (!fileExists) {
        _logger.warning('File does not exist: $filePath');
        return null;
      }
      List<int>? headerBytes;
      try {
        headerBytes = await file.openRead(0, 12).first;
      } catch (_) {
        // best-effort; fall back to extension-only detection
      }
      final mimeType = lookupMimeType(filePath, headerBytes: headerBytes);
      return mimeType;
    } catch (e, st) {
      _logger.severe('Error reading file for MIME type detection: $filePath', e, st);
      return null;
    }
  }
}
