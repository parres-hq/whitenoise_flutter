import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/media_modal.dart';
import 'package:whitenoise/ui/chat/widgets/media_thumbnail.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import '../../../test_helpers.dart';

class _MockMediaFileDownloadsNotifier extends MediaFileDownloadsNotifier {
  List<MediaFile>? downloadedMediaFiles;

  @override
  Future<List<MediaFileDownload>> downloadMediaFiles(List<MediaFile> mediaFiles) async {
    downloadedMediaFiles = mediaFiles;
    return [];
  }
}

void main() {
  group('MediaModal', () {
    final testTimestamp = DateTime(2024, 10, 30, 14, 30);

    List<MediaFile> createTestMediaFiles(int count) {
      return List.generate(
        count,
        (index) => MediaFile(
          id: 'test-id-$index',
          mlsGroupId: 'group-id',
          accountPubkey: 'pubkey',
          filePath: '/path/to/image$index.jpg',
          originalFileHash: 'hash-$index',
          encryptedFileHash: 'encrypted-hash-$index',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://example.com/image$index.jpg',
          nostrKey: 'key-$index',
          createdAt: testTimestamp,
          fileMetadata: FileMetadata(
            blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
            originalFilename: 'image$count.jpg',
          ),
        ),
      );
    }

    testWidgets('shows image from initial index 0', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(3);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, equals(0));
    });

    testWidgets('shows image from other index', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(5);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 2,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
        ),
      );

      expect(find.byType(PageView), findsOneWidget);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.initialPage, equals(2));
    });

    testWidgets('displays thumbnails', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(4);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MediaThumbnail), findsNWidgets(4));
    });

    testWidgets('displays sender name', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(1);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'John Doe',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('displays sender avatar', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(1);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'John Doe',
            senderImagePath: '/path/to/avatar.jpg',
            timestamp: testTimestamp,
          ),
        ),
      );

      expect(find.byType(WnAvatar), findsOneWidget);
    });

    testWidgets('formats local time with correct pattern dd/MM/yyyy - HH:mm', (
      WidgetTester tester,
    ) async {
      final mediaFiles = createTestMediaFiles(1);
      final timestamp = DateTime(2024, 3, 15, 9, 5, 30);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: timestamp,
          ),
        ),
      );
      expect(find.text('15/03/2024 - 09:05'), findsOneWidget);
    });

    testWidgets('hides thumbnail when only one media file', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(1);

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
        ),
      );

      expect(find.byType(MediaThumbnail), findsNothing);
    });

    testWidgets('downloads media files on init', (WidgetTester tester) async {
      final mediaFiles = createTestMediaFiles(3);
      final mockNotifier = _MockMediaFileDownloadsNotifier();

      await tester.pumpWidget(
        createTestWidget(
          MediaModal(
            mediaFiles: mediaFiles,
            initialIndex: 0,
            senderName: 'Test User',
            senderImagePath: null,
            timestamp: testTimestamp,
          ),
          overrides: [
            mediaFileDownloadsProvider.overrideWith(() => mockNotifier),
          ],
        ),
      );

      expect(mockNotifier.downloadedMediaFiles, equals(mediaFiles));
    });

    group('zoom', () {
      late Directory tempDir;
      late List<File> imageFiles;
      late List<MediaFile> mediaFiles;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('test_media_modal_');
        imageFiles = List.generate(3, (index) {
          final file = File('${tempDir.path}/test_image_$index.jpg');
          file.writeAsBytesSync([0xFF, 0xD8, 0xFF]);
          return file;
        });

        mediaFiles =
            imageFiles
                .map(
                  (file) => MediaFile(
                    id: 'test-id-${imageFiles.indexOf(file)}',
                    mlsGroupId: 'group-id',
                    accountPubkey: 'pubkey',
                    filePath: file.path,
                    originalFileHash: 'hash-${imageFiles.indexOf(file)}',
                    encryptedFileHash: 'encrypted-hash-${imageFiles.indexOf(file)}',
                    mimeType: 'image/jpeg',
                    mediaType: 'image',
                    blossomUrl: 'https://example.com/image.jpg',
                    nostrKey: 'key-${imageFiles.indexOf(file)}',
                    createdAt: testTimestamp,
                    fileMetadata: const FileMetadata(
                      blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
                    ),
                  ),
                )
                .toList();
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      Future<void> pumpMediaModal(WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MediaModal(
              mediaFiles: mediaFiles,
              initialIndex: 0,
              senderName: 'Test User',
              senderImagePath: null,
              timestamp: testTimestamp,
            ),
          ),
        );
      }

      Future<void> doubleTapImage(WidgetTester tester) async {
        final interactiveViewer = find.byType(InteractiveViewer).first;
        final center = tester.getCenter(interactiveViewer);
        await tester.tapAt(center);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(center);
        await tester.pumpAndSettle();
      }

      Future<void> swipeImage(WidgetTester tester) async {
        final swipeOffset = const Offset(-400, 0);
        final swipeSpeed = 500.0;
        await tester.fling(find.byType(PageView), swipeOffset, swipeSpeed);
        await tester.pumpAndSettle();
      }

      double getCurrentPageIndex(WidgetTester tester) {
        final pageView = tester.widget<PageView>(find.byType(PageView));
        return pageView.controller?.page ?? -1;
      }

      testWidgets('allows page swiping when not zoomed', (
        WidgetTester tester,
      ) async {
        await pumpMediaModal(tester);
        await swipeImage(tester);
        expect(getCurrentPageIndex(tester), equals(1));
      });

      testWidgets('prevents page swiping when zoomed', (
        WidgetTester tester,
      ) async {
        await pumpMediaModal(tester);
        await doubleTapImage(tester);
        await swipeImage(tester);
        expect(getCurrentPageIndex(tester), equals(0));
      });

      testWidgets('re enables page swiping after zooming out', (
        WidgetTester tester,
      ) async {
        await pumpMediaModal(tester);
        await doubleTapImage(tester);
        await doubleTapImage(tester);
        await swipeImage(tester);
        expect(getCurrentPageIndex(tester), equals(1));
      });
    });
  });
}
