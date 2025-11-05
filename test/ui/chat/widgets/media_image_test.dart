import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/chat/widgets/media_image.dart';

import '../../../test_helpers.dart';

class TestMediaFileDownloadsNotifier extends MediaFileDownloadsNotifier {
  TestMediaFileDownloadsNotifier(this._state) : super();

  final MediaFileDownloadsState _state;

  @override
  MediaFileDownloadsState build() => _state;
}

void main() {
  group('MediaImage', () {
    final testCreatedAt = DateTime.now();

    MediaFile createTestMediaFile({
      required String filePath,
      FileMetadata? fileMetadata,
    }) {
      return MediaFile(
        id: 'test-id',
        mlsGroupId: 'group-id',
        accountPubkey: 'pubkey',
        filePath: filePath,
        originalFileHash: 'hash',
        encryptedFileHash: 'encrypted-hash',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/image.jpg',
        nostrKey: 'key',
        fileMetadata: fileMetadata,
        createdAt: testCreatedAt,
      );
    }

    group('when file is not downloaded', () {
      const testBlurhash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
      final mediaFile = createTestMediaFile(
        filePath: '/non/existent/path.jpg',
        fileMetadata: const FileMetadata(
          blurhash: testBlurhash,
        ),
      );
      group('when file path does not exist', () {
        testWidgets('shows blurhash placeholder', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              MediaImage(
                mediaFile: mediaFile,
              ),
            ),
          );
          expect(find.byType(BlurhashPlaceholder), findsOneWidget);
          final placeholder = tester.widget<BlurhashPlaceholder>(find.byType(BlurhashPlaceholder));
          expect(placeholder.hash, testBlurhash);
        });

        testWidgets('does not render image', (WidgetTester tester) async {
          final mediaFile = createTestMediaFile(
            filePath: '/non/existent/path.jpg',
            fileMetadata: const FileMetadata(
              blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
            ),
          );

          await tester.pumpWidget(
            createTestWidget(
              MediaImage(
                mediaFile: mediaFile,
              ),
            ),
          );

          expect(find.byType(Image), findsNothing);
        });
      });

      group('when file path is empty', () {
        testWidgets('does not render image', (WidgetTester tester) async {
          final mediaFile = createTestMediaFile(
            filePath: '',
          );

          await tester.pumpWidget(
            createTestWidget(MediaImage(mediaFile: mediaFile)),
          );

          expect(find.byType(Image), findsNothing);
        });

        testWidgets('shows blurhash placeholder', (WidgetTester tester) async {
          const testBlurhash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
          final mediaFile = createTestMediaFile(
            filePath: '',
            fileMetadata: const FileMetadata(
              blurhash: testBlurhash,
            ),
          );

          await tester.pumpWidget(
            createTestWidget(
              MediaImage(
                mediaFile: mediaFile,
              ),
            ),
          );

          expect(find.byType(BlurhashPlaceholder), findsOneWidget);
          final placeholder = tester.widget<BlurhashPlaceholder>(find.byType(BlurhashPlaceholder));
          expect(placeholder.hash, testBlurhash);
        });

        group('without file metadata', () {
          testWidgets('shows blurhash placeholder without hash', (WidgetTester tester) async {
            final mediaFile = createTestMediaFile(
              filePath: '',
            );

            await tester.pumpWidget(
              createTestWidget(
                MediaImage(
                  mediaFile: mediaFile,
                ),
              ),
            );

            expect(find.byType(BlurhashPlaceholder), findsOneWidget);
            final placeholder = tester.widget<BlurhashPlaceholder>(
              find.byType(BlurhashPlaceholder),
            );
            expect(placeholder.hash, isNull);
          });
        });

        group('without blurhash in file metadata', () {
          testWidgets('renders blurhash placeholder without hash', (WidgetTester tester) async {
            final mediaFile = createTestMediaFile(
              filePath: '',
              fileMetadata: const FileMetadata(),
            );

            await tester.pumpWidget(
              createTestWidget(
                MediaImage(
                  mediaFile: mediaFile,
                ),
              ),
            );

            expect(find.byType(BlurhashPlaceholder), findsOneWidget);
            final placeholder = tester.widget<BlurhashPlaceholder>(
              find.byType(BlurhashPlaceholder),
            );
            expect(placeholder.hash, isNull);
          });
        });
      });
    });

    group('when file is downloading', () {
      testWidgets('renders blurhash placeholder with spinner', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: '',
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        final download = MediaFileDownload.downloading(
          originalFileHash: mediaFile.originalFileHash!,
          originalFile: mediaFile,
        );

        final testState = MediaFileDownloadsState(
          mediaFileDownloadsMap: {
            mediaFile.originalFileHash!: download,
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mediaFileDownloadsProvider.overrideWith(
                () => TestMediaFileDownloadsNotifier(testState),
              ),
            ],
            child: createTestWidget(
              MediaImage(mediaFile: mediaFile),
            ),
          ),
        );

        expect(find.byType(BlurhashPlaceholder), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('when file is pending', () {
      testWidgets('renders blurhash placeholder with spinner', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: '',
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        final download = MediaFileDownload.pending(
          originalFileHash: mediaFile.originalFileHash!,
          originalFile: mediaFile,
        );

        final testState = MediaFileDownloadsState(
          mediaFileDownloadsMap: {
            mediaFile.originalFileHash!: download,
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mediaFileDownloadsProvider.overrideWith(
                () => TestMediaFileDownloadsNotifier(testState),
              ),
            ],
            child: createTestWidget(
              MediaImage(mediaFile: mediaFile),
            ),
          ),
        );

        expect(find.byType(BlurhashPlaceholder), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('when file download failed', () {
      testWidgets('renders blurhash placeholder without spinner', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: '',
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        final download = MediaFileDownload.failed(
          originalFileHash: mediaFile.originalFileHash!,
          originalFile: mediaFile,
        );

        final testState = MediaFileDownloadsState(
          mediaFileDownloadsMap: {
            mediaFile.originalFileHash!: download,
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mediaFileDownloadsProvider.overrideWith(
                () => TestMediaFileDownloadsNotifier(testState),
              ),
            ],
            child: createTestWidget(
              MediaImage(mediaFile: mediaFile),
            ),
          ),
        );

        expect(find.byType(BlurhashPlaceholder), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('when file is downloaded', () {
      late Directory tempDir;
      late File validImageFile;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('test_media_viewer_');
        validImageFile = File('${tempDir.path}/test_image.jpg');
        validImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF]);
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      testWidgets('renders image', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: validImageFile.path,
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MediaImage(
              mediaFile: mediaFile,
            ),
          ),
        );
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('does not show blurhash placeholder', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: validImageFile.path,
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MediaImage(
              mediaFile: mediaFile,
            ),
          ),
        );

        expect(find.byType(BlurhashPlaceholder), findsNothing);
      });
    });
  });
}
