import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;

part 'media_file_download.freezed.dart';

@freezed
sealed class MediaFileDownload with _$MediaFileDownload {
  const factory MediaFileDownload.pending({
    required String originalFileHash,
    required MediaFile originalFile,
  }) = MediaFileDownloadPending;

  const factory MediaFileDownload.downloading({
    required String originalFileHash,
    required MediaFile originalFile,
  }) = MediaFileDownloadInProgress;

  const factory MediaFileDownload.downloaded({
    required String originalFileHash,
    required MediaFile downloadedFile,
  }) = MediaFileDownloaded;

  const factory MediaFileDownload.failed({
    required String originalFileHash,
    required MediaFile originalFile,
  }) = MediaFileDownloadFailed;
}

extension MediaFileDownloadExtension on MediaFileDownload {
  bool get isPending => maybeWhen(
    pending: (_, _) => true,
    orElse: () => false,
  );

  bool get isDownloading => maybeWhen(
    downloading: (_, _) => true,
    orElse: () => false,
  );

  bool get isDownloaded => maybeWhen(
    downloaded: (_, _) => true,
    orElse: () => false,
  );

  bool get isFailed => maybeWhen(
    failed: (_, _) => true,
    orElse: () => false,
  );

  MediaFile get mediaFile => when(
    pending: (_, originalFile) => originalFile,
    downloading: (_, originalFile) => originalFile,
    downloaded: (_, downloadedFile) => downloadedFile,
    failed: (_, originalFile) => originalFile,
  );

  String get originalFileHash => when(
    pending: (hash, _) => hash,
    downloading: (hash, _) => hash,
    downloaded: (hash, _) => hash,
    failed: (hash, _) => hash,
  );
}
