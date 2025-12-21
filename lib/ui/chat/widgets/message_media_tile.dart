import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(mediaFile),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          download.isDownloaded
              ? Image.file(
                File(download.mediaFile.filePath),
                key: ValueKey('image_${download.mediaFile.originalFileHash}'),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, _, _) => _buildBlurhash(size),
              )
              : _buildBlurhash(size),
    );
  }

  Widget _buildBlurhash(double dimension) {
    return BlurhashPlaceholder(
      key: ValueKey('blurhash_${mediaFile.originalFileHash}'),
      hash: mediaFile.fileMetadata?.blurhash,
      width: dimension,
      height: dimension,
    );
  }
}
