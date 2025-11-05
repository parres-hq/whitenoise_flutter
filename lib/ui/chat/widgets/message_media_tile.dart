import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';

class MessageMediaTile extends ConsumerWidget {
  const MessageMediaTile({
    super.key,
    required this.mediaFile,
    required this.size,
  });

  final MediaFile mediaFile;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimension = size.w;
    return SizedBox(
      width: dimension,
      height: dimension,
      child: _buildContent(ref),
    );
  }

  Widget _buildContent(WidgetRef ref) {
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(mediaFile),
      ),
    );

    final fileToDisplay = download.mediaFile;
    final isDownloaded = _hasLocalFile(fileToDisplay);

    if (download.isDownloaded && isDownloaded) {
      return Image.file(
        File(fileToDisplay.filePath),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildBlurhash(),
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

  bool _hasLocalFile(MediaFile file) {
    if (file.filePath.isEmpty) return false;

    try {
      return File(file.filePath).existsSync();
    } catch (_) {
      return false;
    }
  }
}
