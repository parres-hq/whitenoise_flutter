import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;

part 'media_file_upload.freezed.dart';

@freezed
sealed class MediaFileUpload with _$MediaFileUpload {
  const factory MediaFileUpload.uploading({
    required String filePath,
  }) = MediaFileUploading;

  const factory MediaFileUpload.uploaded({
    required MediaFile file,
    required String originalFilePath,
  }) = MediaFileUploaded;

  const factory MediaFileUpload.failed({
    required String filePath,
    required String error,
  }) = MediaFileUploadFailed;
}

extension MediaFileUploadExtension on MediaFileUpload {
  String get filePath => when(
    uploading: (path) => path,
    uploaded: (file, originalFilePath) => file.filePath,
    failed: (path, _) => path,
  );

  String get originalFilePath => when(
    uploading: (path) => path,
    uploaded: (file, originalFilePath) => originalFilePath,
    failed: (path, _) => path,
  );

  bool get isUploading => maybeWhen(
    uploading: (_) => true,
    orElse: () => false,
  );

  bool get isUploaded => maybeWhen(
    uploaded: (_, _) => true,
    orElse: () => false,
  );

  bool get isFailed => maybeWhen(
    failed: (path, error) => true,
    orElse: () => false,
  );

  MediaFile? get uploadedFile => maybeWhen(
    uploaded: (file, originalFilePath) => file,
    orElse: () => null,
  );
}
