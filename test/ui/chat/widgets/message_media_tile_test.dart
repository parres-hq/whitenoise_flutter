import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';

import '../../../test_helpers.dart';

void main() {
  group('MessageMediaTile', () {
    const testSize = 100.0;
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
      group('when file path does not exist', () {
        testWidgets('shows blurhash placeholder', (WidgetTester tester) async {
          const testBlurhash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
          final mediaFile = createTestMediaFile(
            filePath: '/non/existent/path.jpg',
            fileMetadata: const FileMetadata(
              blurhash: testBlurhash,
            ),
          );

          await tester.pumpWidget(
            createTestWidget(
              MessageMediaTile(
                mediaFile: mediaFile,
                size: testSize,
              ),
            ),
          );

          expect(find.byType(BlurhashPlaceholder), findsOneWidget);
          final placeholder = tester.widget<BlurhashPlaceholder>(find.byType(BlurhashPlaceholder));
          expect(placeholder.hash, testBlurhash);
        });
      });

      group('when file path is empty', () {
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
              MessageMediaTile(
                mediaFile: mediaFile,
                size: testSize,
              ),
            ),
          );

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
                MessageMediaTile(
                  mediaFile: mediaFile,
                  size: testSize,
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
                MessageMediaTile(
                  mediaFile: mediaFile,
                  size: testSize,
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

    group('when file is downloaded', () {
      late Directory tempDir;
      late File validImageFile;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('test_media_');
        validImageFile = File('${tempDir.path}/test_image.jpg');
        validImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF]);
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      testWidgets('shows image from file path', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: validImageFile.path,
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaTile(
              mediaFile: mediaFile,
              size: testSize,
            ),
          ),
        );
        expect(find.byType(Image), findsOneWidget);
      });

      testWidgets('does not show blurhash', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: validImageFile.path,
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaTile(
              mediaFile: mediaFile,
              size: testSize,
            ),
          ),
        );
        expect(find.byType(BlurhashPlaceholder), findsNothing);
      });
    });
  });
}
