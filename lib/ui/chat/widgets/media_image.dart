import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.mediaFile,
    this.width,
    this.height,
  });

  final MediaFile mediaFile;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final hasLocalFile = _hasLocalFile();

    if (hasLocalFile) {
      return Image.file(
        File(mediaFile.filePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildBlurhash(),
      );
    }

    return _buildBlurhash();
  }

  Widget _buildBlurhash() {
    return BlurhashPlaceholder(
      hash: mediaFile.fileMetadata?.blurhash,
      width: width,
      height: height,
    );
  }

  bool _hasLocalFile() {
    if (mediaFile.filePath.isEmpty) return false;

    try {
      return File(mediaFile.filePath).existsSync();
    } catch (_) {
      return false;
    }
  }
}
