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

class MediaImage extends ConsumerStatefulWidget {
  const MediaImage({
    super.key,
    required this.mediaFile,
    this.width,
    this.height,
    this.onZoomChanged,
  });

  final MediaFile mediaFile;
  final double? width;
  final double? height;
  final void Function(bool isZoomed)? onZoomChanged;

  @override
  ConsumerState<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends ConsumerState<MediaImage> {
  static final _logger = Logger('MediaImage');
  late TransformationController _transformationController;
  bool _isZoomed = false;
  final maxScale = 4.0;
  final minScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final wasZoomed = _isZoomed;
    _isZoomed = scale > minScale;

    if (wasZoomed != _isZoomed) {
      widget.onZoomChanged?.call(_isZoomed);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isZoomed) {
      _zoomOut();
    } else {
      _zoomIn(details);
    }
  }

  void _zoomOut() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn(TapDownDetails details) {
    _transformationController.value = _zoomInTransformation(details);
  }

  Matrix4 _zoomInTransformation(TapDownDetails details) {
    final position = details.localPosition;
    final x = -position.dx * (maxScale - 1);
    final y = -position.dy * (maxScale - 1);

    final matrix =
        Matrix4.identity()
          ..setEntry(0, 0, maxScale)
          ..setEntry(1, 1, maxScale)
          ..setEntry(0, 3, x)
          ..setEntry(1, 3, y);
    return matrix;
  }

  @override
  Widget build(BuildContext context) {
    final download = ref.watch(
      mediaFileDownloadsProvider.select(
        (state) => state.getMediaFileDownload(widget.mediaFile),
      ),
    );

    final fileToDisplay = download.mediaFile;
    final hasLocalFile = _hasLocalFile(fileToDisplay);

    if (download.isDownloaded && hasLocalFile) {
      final image = Image.file(
        File(fileToDisplay.filePath),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildBlurhash(),
      );

      return GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: minScale,
          maxScale: maxScale,
          clipBehavior: Clip.none,
          child: image,
        ),
      );
    }

    if (download.isFailed) {
      _logger.warning('Download failed for ${fileToDisplay.originalFileHash}');
      return _buildBlurhash();
    }

    if (download.isDownloading || download.isPending) {
      _logger.info('Download in progress for ${fileToDisplay.originalFileHash}');
      return _BlurhashWithSpinner(
        hash: widget.mediaFile.fileMetadata?.blurhash,
        width: widget.width,
        height: widget.height,
      );
    }

    return _buildBlurhash();
  }

  Widget _buildBlurhash() {
    return BlurhashPlaceholder(
      hash: widget.mediaFile.fileMetadata?.blurhash,
      width: widget.width,
      height: widget.height,
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
