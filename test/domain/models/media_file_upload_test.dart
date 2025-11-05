import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

void main() {
  group('MediaFileUpload', () {
    const testFilePath = '/path/to/image.jpg';
    const testError = 'Upload failed';

    final testMediaFile = MediaFile(
      id: '123',
      accountPubkey: 'pubkey123',
      originalFileHash: 'file_hash',
      encryptedFileHash: 'test-encrypted-hash',
      mlsGroupId: 'group123',
      filePath: testFilePath,
      mimeType: 'image/jpeg',
      mediaType: 'image',
      blossomUrl: 'https://example.com/image.jpg',
      nostrKey: 'nostr_key',
      createdAt: DateTime.now(),
    );

    group('uploading', () {
      final upload = const MediaFileUpload.uploading(filePath: testFilePath);
      test('has expected file path', () {
        expect(upload.filePath, testFilePath);
      });

      test('is uploading', () {
        expect(upload.isUploading, true);
      });

      test('is not uploaded', () {
        expect(upload.isUploaded, false);
      });

      test('is not failed', () {
        expect(upload.isFailed, false);
      });

      test('does not have uploaded file', () {
        expect(upload.uploadedFile, isNull);
      });
    });

    group('uploaded', () {
      final upload = MediaFileUpload.uploaded(
        file: testMediaFile,
        originalFilePath: 'original.jpg',
      );
      test('has expected file path', () {
        expect(upload.filePath, testFilePath);
      });

      test('has expected original file path', () {
        expect(upload.originalFilePath, 'original.jpg');
      });
      test('is not uploading', () {
        expect(upload.isUploading, false);
      });
      test('is uploaded', () {
        expect(upload.isUploaded, true);
      });
      test('is not failed', () {
        expect(upload.isFailed, false);
      });
      test('has expected uploaded file', () {
        expect(upload.uploadedFile, testMediaFile);
      });
    });

    group('failed', () {
      final upload = const MediaFileUpload.failed(
        filePath: testFilePath,
        error: testError,
      );
      test('has expected file path', () {
        expect(upload.filePath, testFilePath);
      });
      test('is not uploading', () {
        expect(upload.isUploading, false);
      });
      test('is not uploaded', () {
        expect(upload.isUploaded, false);
      });
      test('is failed', () {
        expect(upload.isFailed, true);
      });
      test('does not have uploaded file', () {
        expect(upload.uploadedFile, isNull);
      });
    });
  });
}
