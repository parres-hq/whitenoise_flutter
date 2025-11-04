import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

ProviderContainer _createTestContainer(
  Future<MediaFile> Function(String hash) downloadFn,
) {
  return ProviderContainer(
    overrides: [
      mediaFileDownloadsProvider.overrideWith(
        () => MediaFileDownloadsNotifier(
          downloadMediaFn: ({
            required String accountPubkey,
            required String groupId,
            required String originalFileHash,
          }) async {
            return downloadFn(originalFileHash);
          },
        ),
      ),
    ],
  );
}

MediaFile _createMediaFile(String? hash) {
  return MediaFile(
    id: 'id_${hash ?? 'no_hash'}',
    mlsGroupId: 'test_group',
    accountPubkey: 'test_pubkey',
    filePath: '',
    originalFileHash: hash,
    encryptedFileHash: 'encrypted_${hash ?? 'no_hash'}',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://test.com/${hash ?? 'no_hash'}',
    nostrKey: 'test_key',
    createdAt: DateTime.now(),
  );
}

MediaFile _createMediaFileWithPath(String hash, String path) {
  return MediaFile(
    id: 'id_$hash',
    mlsGroupId: 'test_group',
    accountPubkey: 'test_pubkey',
    filePath: path,
    originalFileHash: hash,
    encryptedFileHash: 'encrypted_$hash',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://test.com/$hash',
    nostrKey: 'test_key',
    createdAt: DateTime.now(),
  );
}

void main() {
  group('MediaDownloadProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initially mediaFileDownloads is empty', () {
      final state = container.read(mediaFileDownloadsProvider);

      expect(state.mediaFileDownloadsMap, isEmpty);
    });

    group('copyWith', () {
      test('preserves existing mediaFileDownloadsMap when not provided', () {
        final originalMap = {
          'test_hash': MediaFileDownload.downloaded(
            originalFileHash: 'test_hash',
            downloadedFile: _createMediaFileWithPath('test_hash', '/path/to/file'),
          ),
        };
        final state = MediaFileDownloadsState(mediaFileDownloadsMap: originalMap);

        final copiedState = state.copyWith();

        expect(copiedState.mediaFileDownloadsMap, equals(originalMap));
        expect(identical(copiedState.mediaFileDownloadsMap, originalMap), true);
      });
    });

    group('getMediaFileDownload', () {
      test('returns pending media file download for file without hash', () {
        final state = container.read(mediaFileDownloadsProvider);
        final file = _createMediaFile(null);

        final download = state.getMediaFileDownload(file);

        expect(download.isPending, true);
        expect(download.originalFileHash, '');
        expect(download.mediaFile, file);
      });

      test('returns pending media file download for file with empty hash', () {
        final state = container.read(mediaFileDownloadsProvider);
        final file = _createMediaFile('');

        final download = state.getMediaFileDownload(file);

        expect(download.isPending, true);
        expect(download.originalFileHash, '');
        expect(download.mediaFile, file);
      });

      test('returns downloaded media file download for file with path', () {
        final state = container.read(mediaFileDownloadsProvider);
        final file = _createMediaFileWithPath('test_hash', '/path/to/file');

        final download = state.getMediaFileDownload(file);

        expect(download.isDownloaded, true);
        expect(download.originalFileHash, 'test_hash');
        expect(download.mediaFile, file);
      });

      test('returns pending media file donwload for file not in state without path', () {
        final state = container.read(mediaFileDownloadsProvider);
        final file = _createMediaFile('test_hash');

        final download = state.getMediaFileDownload(file);

        expect(download.isPending, true);
        expect(download.originalFileHash, 'test_hash');
        expect(download.mediaFile, file);
      });

      test('returns downloading media file download from state when present', () {
        final notifier = container.read(mediaFileDownloadsProvider.notifier);
        final file = _createMediaFile('test_hash');

        notifier.state = MediaFileDownloadsState(
          mediaFileDownloadsMap: {
            'test_hash': MediaFileDownload.downloading(
              originalFileHash: 'test_hash',
              originalFile: file,
            ),
          },
        );

        final state = container.read(mediaFileDownloadsProvider);
        final download = state.getMediaFileDownload(file);

        expect(download.isDownloading, true);
        expect(download.originalFileHash, 'test_hash');
      });

      test(
        'returns downloaded media file downloadfor file with path when state is downloading',
        () {
          final notifier = container.read(mediaFileDownloadsProvider.notifier);
          final fileWithoutPath = _createMediaFile('test_hash');
          final fileWithPath = _createMediaFileWithPath('test_hash', '/downloaded/file');

          notifier.state = MediaFileDownloadsState(
            mediaFileDownloadsMap: {
              'test_hash': MediaFileDownload.downloading(
                originalFileHash: 'test_hash',
                originalFile: fileWithoutPath,
              ),
            },
          );

          final state = container.read(mediaFileDownloadsProvider);
          final download = state.getMediaFileDownload(fileWithPath);

          expect(download.isDownloaded, true);
          expect(download.originalFileHash, 'test_hash');
          expect(download.mediaFile.filePath, '/downloaded/file');
        },
      );
    });

    group('downloadMediaFiles', () {
      test('returns empty list for empty input', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles([]);

        expect(results, isEmpty);
      });

      test('does not update state when input is empty', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles([]);

        expect(container.read(mediaFileDownloadsProvider).mediaFileDownloadsMap, isEmpty);
      });

      test('does not download again for files with path', () async {
        bool downloadCalled = false;
        final container = _createTestContainer((hash) async {
          downloadCalled = true;
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final fileWithPath = _createMediaFileWithPath('hash1', '/existing/path');
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles([
          fileWithPath,
        ]);

        expect(downloadCalled, false);
      });

      test('returns downloaded status for files with existing path', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final fileWithPath = _createMediaFileWithPath('hash1', '/existing/path');
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(
              [
                fileWithPath,
              ],
            );

        expect(results.single.isDownloaded, true);
      });

      test('updatesstate for files with existing path', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final fileWithPath = _createMediaFileWithPath('hash1', '/existing/path');
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles([
          fileWithPath,
        ]);

        expect(
          container.read(mediaFileDownloadsProvider).mediaFileDownloadsMap.length,
          equals(1),
        );
      });

      test('sets downloading state when downloads are in progress', () async {
        final container = _createTestContainer((hash) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('test_hash')];
        final downloadFuture = container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);
        await Future.delayed(const Duration(milliseconds: 1));

        final stateDuringDownload = container.read(mediaFileDownloadsProvider);
        expect(stateDuringDownload.mediaFileDownloadsMap.length, 1);
        expect(stateDuringDownload.mediaFileDownloadsMap['test_hash']?.isDownloading, true);

        await downloadFuture;
      });

      test('updates state after download completes', () async {
        final container = _createTestContainer((hash) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return _createMediaFileWithPath(hash, '/path/to/$hash');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('test_hash')];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final finalState = container.read(mediaFileDownloadsProvider);
        expect(finalState.mediaFileDownloadsMap['test_hash']?.isDownloaded, true);
      });

      test('returns downloaded result after successful download', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('test_hash')];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results.single.isDownloaded, true);
      });

      test('calls download function for files without path', () async {
        bool downloadCalled = false;
        final container = _createTestContainer((hash) async {
          downloadCalled = true;
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('test_hash')];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        expect(downloadCalled, true);
      });

      test('stores failed download in state', () async {
        final container = _createTestContainer((hash) async {
          throw Exception('Download failed');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('failed_hash')];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final state = container.read(mediaFileDownloadsProvider);
        expect(state.mediaFileDownloadsMap['failed_hash']?.isFailed, true);
      });

      test('returns failed result when download fails', () async {
        final container = _createTestContainer((hash) async {
          throw Exception('Download failed');
        });
        addTearDown(container.dispose);

        final files = [_createMediaFile('failed_hash')];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results.single.isFailed, true);
      });

      test('downloads all files when multiple files provided', () async {
        final downloadedHashes = <String>[];
        final container = _createTestContainer((hash) async {
          downloadedHashes.add(hash);
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        expect(downloadedHashes, containsAll(['hash1', 'hash2', 'hash3']));
      });

      test('stores all successful downloads in state', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final state = container.read(mediaFileDownloadsProvider);
        expect(state.mediaFileDownloadsMap['hash1']?.isDownloaded, true);
      });

      test('returns results in same order as input', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results[0].originalFileHash, 'hash1');
      });

      test('continues downloading after one file fails', () async {
        final downloadedHashes = <String>[];
        final container = _createTestContainer((hash) async {
          downloadedHashes.add(hash);
          if (hash == 'hash2') {
            throw Exception('Download failed for hash2');
          }
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        expect(downloadedHashes, containsAll(['hash1', 'hash2', 'hash3']));
      });

      test('stores both successful and failed downloads in state', () async {
        final container = _createTestContainer((hash) async {
          if (hash == 'hash2') {
            throw Exception('Download failed for hash2');
          }
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final state = container.read(mediaFileDownloadsProvider);
        expect(state.mediaFileDownloadsMap['hash2']?.isFailed, true);
      });

      test('returns failed status for files that failed to download', () async {
        final container = _createTestContainer((hash) async {
          if (hash == 'hash2') {
            throw Exception('Download failed for hash2');
          }
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
        ];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results[1].isFailed, true);
      });

      test('skips download for already downloaded files in mixed batch', () async {
        final downloadedHashes = <String>[];
        final container = _createTestContainer((hash) async {
          downloadedHashes.add(hash);
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFileWithPath('hash1', '/existing/hash1'),
          _createMediaFile('hash2'),
          _createMediaFileWithPath('hash3', '/existing/hash3'),
          _createMediaFile('hash4'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        expect(downloadedHashes, ['hash2', 'hash4']);
      });

      test('maintains result order with mixed downloaded and pending files', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFileWithPath('hash1', '/existing/hash1'),
          _createMediaFile('hash2'),
          _createMediaFileWithPath('hash3', '/existing/hash3'),
          _createMediaFile('hash4'),
        ];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results[0].mediaFile.filePath, '/existing/hash1');
      });

      test('adds downloaded files to state', () async {
        final container = _createTestContainer((hash) async {
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFileWithPath('hash1', '/existing/hash1'),
          _createMediaFile('hash2'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final state = container.read(mediaFileDownloadsProvider);
        expect(state.mediaFileDownloadsMap.containsKey('hash1'), true);
      });

      test('stores all concurrent downloads in final state', () async {
        final container = _createTestContainer((hash) async {
          await Future.delayed(
            Duration(milliseconds: hash == 'hash1' ? 50 : 10),
          );
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
        ];
        await container.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(files);

        final finalState = container.read(mediaFileDownloadsProvider);
        expect(finalState.mediaFileDownloadsMap['hash1']?.isDownloaded, true);
      });

      test('completes all downloads despite single failure', () async {
        final container = _createTestContainer((hash) async {
          await Future.delayed(const Duration(milliseconds: 5));
          if (hash == 'hash2') {
            throw Exception('Network error for hash2');
          }
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final files = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
          _createMediaFile('hash3'),
          _createMediaFile('hash4'),
        ];
        final results = await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(files);

        expect(results.length, 4);
      });

      test('keeps both first and second batch downloads in state when called twice', () async {
        final container = _createTestContainer((hash) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return _createMediaFileWithPath(hash, '/downloaded/$hash');
        });
        addTearDown(container.dispose);

        final firstBatchFiles = [
          _createMediaFile('hash1'),
          _createMediaFile('hash2'),
        ];
        final secondBatchFiles = [
          _createMediaFile('hash3'),
          _createMediaFile('hash4'),
        ];

        await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(firstBatchFiles);
        await container
            .read(mediaFileDownloadsProvider.notifier)
            .downloadMediaFiles(secondBatchFiles);

        final finalState = container.read(mediaFileDownloadsProvider);

        expect(finalState.mediaFileDownloadsMap['hash1']?.isDownloaded, true);
        expect(finalState.mediaFileDownloadsMap['hash2']?.isDownloaded, true);
        expect(finalState.mediaFileDownloadsMap['hash3']?.isDownloaded, true);
        expect(finalState.mediaFileDownloadsMap['hash4']?.isDownloaded, true);
        expect(finalState.mediaFileDownloadsMap.length, 4);
      });
    });
  });
}
