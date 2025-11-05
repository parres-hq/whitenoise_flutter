import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

void main() {
  group('MediaFileDownload', () {
    const testHash = 'file_hash_123';

    late MediaFile originalMediaFile;
    late MediaFile downloadedMediaFile;

    setUp(() {
      originalMediaFile = MediaFile(
        id: '123',
        accountPubkey: 'pubkey123',
        originalFileHash: testHash,
        encryptedFileHash: 'encrypted_hash',
        mlsGroupId: 'group123',
        filePath: '',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/image.jpg',
        nostrKey: 'nostr_key',
        createdAt: DateTime.now(),
      );

      downloadedMediaFile = MediaFile(
        id: '123',
        accountPubkey: 'pubkey123',
        originalFileHash: testHash,
        encryptedFileHash: 'encrypted_hash',
        mlsGroupId: 'group123',
        filePath: '/local/path/image.jpg',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/image.jpg',
        nostrKey: 'nostr_key',
        createdAt: DateTime.now(),
      );
    });

    group('pending', () {
      late MediaFileDownload download;

      setUp(() {
        download = MediaFileDownload.pending(
          originalFileHash: testHash,
          originalFile: originalMediaFile,
        );
      });

      test('is pending', () {
        expect(download.isPending, true);
      });

      test('is not downloading', () {
        expect(download.isDownloading, false);
      });

      test('is not downloaded', () {
        expect(download.isDownloaded, false);
      });

      test('is not failed', () {
        expect(download.isFailed, false);
      });

      test('has original file hash', () {
        expect(download.originalFileHash, testHash);
      });

      test('returns original media file', () {
        expect(download.mediaFile, originalMediaFile);
      });
    });

    group('downloading', () {
      late MediaFileDownload download;

      setUp(() {
        download = MediaFileDownload.downloading(
          originalFileHash: testHash,
          originalFile: originalMediaFile,
        );
      });

      test('is not pending', () {
        expect(download.isPending, false);
      });

      test('is downloading', () {
        expect(download.isDownloading, true);
      });

      test('is not downloaded', () {
        expect(download.isDownloaded, false);
      });

      test('is not failed', () {
        expect(download.isFailed, false);
      });

      test('has original file hash', () {
        expect(download.originalFileHash, testHash);
      });

      test('returns original media file', () {
        expect(download.mediaFile, originalMediaFile);
      });
    });

    group('downloaded', () {
      late MediaFileDownload download;

      setUp(() {
        download = MediaFileDownload.downloaded(
          originalFileHash: testHash,
          downloadedFile: downloadedMediaFile,
        );
      });

      test('is not pending', () {
        expect(download.isPending, false);
      });

      test('is not downloading', () {
        expect(download.isDownloading, false);
      });

      test('is downloaded', () {
        expect(download.isDownloaded, true);
      });

      test('is not failed', () {
        expect(download.isFailed, false);
      });

      test('has original file hash', () {
        expect(download.originalFileHash, testHash);
      });

      test('returns downloaded media file', () {
        expect(download.mediaFile, downloadedMediaFile);
      });
    });

    group('failed', () {
      late MediaFileDownload download;

      setUp(() {
        download = MediaFileDownload.failed(
          originalFileHash: testHash,
          originalFile: originalMediaFile,
        );
      });

      test('is not pending', () {
        expect(download.isPending, false);
      });

      test('is not downloading', () {
        expect(download.isDownloading, false);
      });

      test('is not downloaded', () {
        expect(download.isDownloaded, false);
      });

      test('is failed', () {
        expect(download.isFailed, true);
      });

      test('has original file hash', () {
        expect(download.originalFileHash, testHash);
      });

      test('returns original media file', () {
        expect(download.mediaFile, originalMediaFile);
      });
    });
  });
}
