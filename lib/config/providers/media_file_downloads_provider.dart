import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' as media_files_api;
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;

class MediaFileDownloadsState {
  const MediaFileDownloadsState({
    required this.mediaFileDownloadsMap,
  });

  final Map<String, MediaFileDownload> mediaFileDownloadsMap;

  MediaFileDownloadsState copyWith({
    Map<String, MediaFileDownload>? mediaFileDownloadsMap,
  }) {
    return MediaFileDownloadsState(
      mediaFileDownloadsMap: mediaFileDownloadsMap ?? this.mediaFileDownloadsMap,
    );
  }

  MediaFileDownload getMediaFileDownload(MediaFile file) {
    final hash = file.originalFileHash;

    if (hash == null || hash.isEmpty) {
      return MediaFileDownload.pending(
        originalFileHash: '',
        originalFile: file,
      );
    }

    if (file.filePath.isNotEmpty) {
      return MediaFileDownload.downloaded(
        originalFileHash: hash,
        downloadedFile: file,
      );
    }

    final existingMediaFileDownload = mediaFileDownloadsMap[hash];
    if (existingMediaFileDownload != null) {
      return existingMediaFileDownload;
    }

    return MediaFileDownload.pending(
      originalFileHash: hash,
      originalFile: file,
    );
  }
}

class MediaFileDownloadsNotifier extends Notifier<MediaFileDownloadsState> {
  MediaFileDownloadsNotifier({
    Future<MediaFile> Function({
      required String accountPubkey,
      required String groupId,
      required String originalFileHash,
    })?
    downloadMediaFn,
  }) : _downloadMediaFn = downloadMediaFn ?? media_files_api.downloadChatMedia;

  final Future<MediaFile> Function({
    required String accountPubkey,
    required String groupId,
    required String originalFileHash,
  })
  _downloadMediaFn;

  final _logger = Logger('MediaFileDownloadsNotifier');

  @override
  MediaFileDownloadsState build() => const MediaFileDownloadsState(
    mediaFileDownloadsMap: {},
  );

  Future<List<MediaFileDownload>> downloadMediaFiles(List<MediaFile> mediaFiles) async {
    if (mediaFiles.isEmpty) {
      return [];
    }

    // Mark all files as downloading immediately
    final updatedMediaFileDownloadsMap = Map<String, MediaFileDownload>.from(
      state.mediaFileDownloadsMap,
    );
    for (final file in mediaFiles) {
      final hash = file.originalFileHash;
      if (hash != null && hash.isNotEmpty) {
        updatedMediaFileDownloadsMap[hash] = MediaFileDownload.downloading(
          originalFileHash: hash,
          originalFile: file,
        );
      }
    }
    state = state.copyWith(mediaFileDownloadsMap: updatedMediaFileDownloadsMap);

    final downloadResults = await Future.wait(
      mediaFiles.map(
        (file) => _downloadMediaFile(
          originalFile: file,
          accountPubkey: file.accountPubkey,
          groupId: file.mlsGroupId,
          originalFileHash: file.originalFileHash ?? '',
        ),
      ),
    );

    final finalMediaFileDownloadsMap = Map<String, MediaFileDownload>.from(
      state.mediaFileDownloadsMap,
    );
    for (final mediaFileDownload in downloadResults) {
      finalMediaFileDownloadsMap[mediaFileDownload.originalFileHash] = mediaFileDownload;
    }

    state = state.copyWith(mediaFileDownloadsMap: finalMediaFileDownloadsMap);

    return downloadResults;
  }

  Future<MediaFileDownload> _downloadMediaFile({
    required MediaFile originalFile,
    required String accountPubkey,
    required String groupId,
    required String originalFileHash,
  }) async {
    if (originalFile.filePath.isNotEmpty) {
      return MediaFileDownload.downloaded(
        originalFileHash: originalFileHash,
        downloadedFile: originalFile,
      );
    }

    try {
      _logger.info('Starting download for $originalFileHash');
      final downloadedFile = await _downloadMediaFn(
        accountPubkey: accountPubkey,
        groupId: groupId,
        originalFileHash: originalFileHash,
      );
      _logger.info('Successfully downloaded $originalFileHash');

      return MediaFileDownload.downloaded(
        originalFileHash: originalFileHash,
        downloadedFile: downloadedFile,
      );
    } catch (e) {
      _logger.warning('Download failed for $originalFileHash: $e');

      return MediaFileDownload.failed(
        originalFileHash: originalFileHash,
        originalFile: originalFile,
      );
    }
  }
}

final mediaFileDownloadsProvider =
    NotifierProvider<MediaFileDownloadsNotifier, MediaFileDownloadsState>(
      () => MediaFileDownloadsNotifier(),
    );
