import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.mediaFile,
    required this.isActive,
    required this.onTap,
    required this.size,
  });

  final MediaFile mediaFile;
  final bool isActive;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _buildThumbnail(context),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final hasLocalFile = _hasLocalFile();
    final size = 36.w;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? context.colors.borderAccent : Colors.transparent,
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        child: hasLocalFile ? _buildImage() : _buildBlurhash(),
      ),
    );
  }

  Widget _buildImage() {
    return Image.file(
      File(mediaFile.filePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildBlurhash(),
    );
  }

  Widget _buildBlurhash() {
    return BlurhashPlaceholder(
      hash: mediaFile.fileMetadata?.blurhash,
      width: size,
      height: size,
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
