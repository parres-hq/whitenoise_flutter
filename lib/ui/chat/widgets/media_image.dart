import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class MediaImage extends ConsumerWidget {
  const MediaImage({
    super.key,
    required this.mediaFile,
    this.width,
    this.height,
  });

  final MediaFile mediaFile;
  final double? width;
  final double? height;

  static final _logger = Logger('MediaImage');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(mediaFile),
      ),
    );

    final fileToDisplay = download.mediaFile;
    final hasLocalFile = _hasLocalFile(fileToDisplay);

    if (download.isDownloaded && hasLocalFile) {
      return Image.file(
        File(fileToDisplay.filePath),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildBlurhash(),
      );
    }

    if (download.isFailed) {
      _logger.warning('Download failed for ${fileToDisplay.originalFileHash}');
      return _buildBlurhash();
    }

    if (download.isDownloading || download.isPending) {
      _logger.info('Download in progress for ${fileToDisplay.originalFileHash}');
      return _BlurhashWithSpinner(
        hash: mediaFile.fileMetadata?.blurhash,
        width: width,
        height: height,
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

  bool _hasLocalFile(MediaFile file) {
    if (file.filePath.isEmpty) return false;

    try {
      return File(file.filePath).existsSync();
    } catch (e) {
      _logger.warning('Error checking file existence: $e');
      return false;
    }
  }
}

class _BlurhashWithSpinner extends StatelessWidget {
  const _BlurhashWithSpinner({
    required this.hash,
    required this.width,
    required this.height,
  });

  final String? hash;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final blurhashPlaceholder = BlurhashPlaceholder(
      hash: hash,
      width: width,
      height: height,
    );

    return Stack(
      children: [
        blurhashPlaceholder,
        Positioned.fill(
          child: Container(
            color: context.colors.solidNeutralBlack.withValues(alpha: 0.75),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32.w,
                  height: 32.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.w,
                    color: context.colors.solidPrimary,
                    backgroundColor: context.colors.mutedForeground.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
