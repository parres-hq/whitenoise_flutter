import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/blurhash_placeholder.dart';
import 'package:whitenoise/ui/chat/widgets/media_thumbnail.dart';

import '../../../test_helpers.dart';

void main() {
  group('MediaThumbnail', () {
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
      testWidgets('renders blurhash placeholder', (WidgetTester tester) async {
        const testBlurhash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
        final mediaFile = createTestMediaFile(
          filePath: '/non/existent/path.jpg',
          fileMetadata: const FileMetadata(
            blurhash: testBlurhash,
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MediaThumbnail(
              mediaFile: mediaFile,
              isActive: false,
              onTap: () {},
            ),
          ),
        );

        expect(find.byType(BlurhashPlaceholder), findsOneWidget);
      });
    });

    group('when file is downloaded', () {
      late Directory tempDir;
      late File validImageFile;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('test_thumbnail_');
        validImageFile = File('${tempDir.path}/test_image.jpg');
        // Write minimal valid JPEG header
        validImageFile.writeAsBytesSync([0xFF, 0xD8, 0xFF]);
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      testWidgets('renders Image', (WidgetTester tester) async {
        final mediaFile = createTestMediaFile(
          filePath: validImageFile.path,
        );

        await tester.pumpWidget(
          createTestWidget(
            MediaThumbnail(
              mediaFile: mediaFile,
              isActive: false,
              onTap: () {},
            ),
          ),
        );

        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('tap handling', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        bool tapped = false;
        final mediaFile = createTestMediaFile(
          filePath: '/non/existent/path.jpg',
          fileMetadata: const FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
          ),
        );

        await tester.pumpWidget(
          createTestWidget(
            MediaThumbnail(
              mediaFile: mediaFile,
              isActive: false,
              onTap: () => tapped = true,
            ),
          ),
        );

        await tester.tap(find.byType(MediaThumbnail));
        expect(tapped, isTrue);
      });
    });
  });
}
