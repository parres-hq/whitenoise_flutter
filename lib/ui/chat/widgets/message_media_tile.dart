import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';

class MessageMediaTile extends StatelessWidget {
  const MessageMediaTile({
    super.key,
    required this.mediaFile,
    required this.size,
  });

  final MediaFile mediaFile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dimension = size.w; // Use same value for width and height to create square
    return SizedBox(
      width: dimension,
      height: dimension,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final isDownloaded = _hasLocalFile();

    if (isDownloaded) {
      return Image.file(
        File(mediaFile.filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildBlurhash(),
      );
    }

    return _buildBlurhash();
  }

  Widget _buildBlurhash() {
    final dimension = size.w;
    return BlurhashPlaceholder(
      hash: mediaFile.fileMetadata?.blurhash,
      width: dimension,
      height: dimension,
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
