import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class MediaThumbnail extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: _buildThumbnail(context, ref),
    );
  }

  Widget _buildThumbnail(BuildContext context, WidgetRef ref) {
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(mediaFile),
      ),
    );

    final fileToDisplay = download.mediaFile;
    final hasLocalFile = _hasLocalFile(fileToDisplay);
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
        child:
            (download.isDownloaded && hasLocalFile) ? _buildImage(fileToDisplay) : _buildBlurhash(),
      ),
    );
  }

  Widget _buildImage(MediaFile file) {
    return Image.file(
      File(file.filePath),
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

  bool _hasLocalFile(MediaFile file) {
    if (file.filePath.isEmpty) return false;

    try {
      return File(file.filePath).existsSync();
    } catch (_) {
      return false;
    }
  }
}
