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
    final downloads = <String, MediaFileDownload>{};
    for (final file in mediaFiles) {
      final hash = file.originalFileHash ?? '';
      downloads[hash] = MediaFileDownload.downloaded(
        originalFileHash: hash,
        downloadedFile: file,
      );
    }
    state = state.copyWith(mediaFileDownloadsMap: downloads);
    return downloads.values.toList();
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

    group('layout', () {
      testWidgets('image view is vertically centered using Stack with Positioned.fill', (
        WidgetTester tester,
      ) async {
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

        expect(find.byType(Stack), findsWidgets);

        final positionedFillFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Positioned &&
              widget.top == 0 &&
              widget.bottom == 0 &&
              widget.left == 0 &&
              widget.right == 0,
        );
        expect(positionedFillFinder, findsAtLeast(1));
      });

      testWidgets('header is positioned at top', (WidgetTester tester) async {
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

        final headerPositioned = find.byWidgetPredicate(
          (widget) => widget is Positioned && widget.top == 0 && widget.bottom == null,
        );
        expect(headerPositioned, findsOneWidget);
      });

      testWidgets('thumbnail strip is positioned at bottom', (WidgetTester tester) async {
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

        final thumbnailPositioned = find.byWidgetPredicate(
          (widget) => widget is Positioned && widget.bottom == 0 && widget.top == null,
        );
        expect(thumbnailPositioned, findsOneWidget);
      });
    });

    group('overlay fade behavior', () {
      final testTimestampOverlay = DateTime(2024, 10, 30, 14, 30);

      List<MediaFile> createOverlayTestMediaFiles(int count) {
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
            createdAt: testTimestampOverlay,
            fileMetadata: const FileMetadata(
              blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
            ),
          ),
        );
      }

      testWidgets('header and thumbnailStrip use FadeTransition for smooth animation', (
        WidgetTester tester,
      ) async {
        final mediaFiles = createOverlayTestMediaFiles(3);

        await tester.pumpWidget(
          createTestWidget(
            MediaModal(
              mediaFiles: mediaFiles,
              initialIndex: 0,
              senderName: 'Test User',
              senderImagePath: null,
              timestamp: testTimestampOverlay,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(FadeTransition), findsAtLeast(2));
      });

      testWidgets('IgnorePointer wraps header and thumbnails', (
        WidgetTester tester,
      ) async {
        final mediaFiles = createOverlayTestMediaFiles(3);

        await tester.pumpWidget(
          createTestWidget(
            MediaModal(
              mediaFiles: mediaFiles,
              initialIndex: 0,
              senderName: 'Test User',
              senderImagePath: null,
              timestamp: testTimestampOverlay,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(IgnorePointer), findsAtLeast(2));
      });

      testWidgets('IgnorePointer is not ignoring initially', (
        WidgetTester tester,
      ) async {
        final mediaFiles = createOverlayTestMediaFiles(3);

        await tester.pumpWidget(
          createTestWidget(
            MediaModal(
              mediaFiles: mediaFiles,
              initialIndex: 0,
              senderName: 'Test User',
              senderImagePath: null,
              timestamp: testTimestampOverlay,
            ),
          ),
        );
        await tester.pump();

        final ignorePointers = tester.widgetList<IgnorePointer>(find.byType(IgnorePointer));
        final notIgnoringPointers = ignorePointers.where((ip) => ip.ignoring == false);
        expect(notIgnoringPointers.isNotEmpty, isTrue);
      });

      testWidgets('single tap on image hides header and thumbnails strip', (
        WidgetTester tester,
      ) async {
        final tempDir = Directory.systemTemp.createTempSync('test_media_modal_tap_');
        final imageFiles = List.generate(3, (index) {
          final file = File('${tempDir.path}/test_image_$index.jpg');
          file.writeAsBytesSync([0xFF, 0xD8, 0xFF]);
          return file;
        });

        final mediaFiles =
            imageFiles
                .asMap()
                .entries
                .map(
                  (entry) => MediaFile(
                    id: 'test-id-${entry.key}',
                    mlsGroupId: 'group-id',
                    accountPubkey: 'pubkey',
                    filePath: entry.value.path,
                    originalFileHash: 'hash-${entry.key}',
                    encryptedFileHash: 'encrypted-hash-${entry.key}',
                    mimeType: 'image/jpeg',
                    mediaType: 'image',
                    blossomUrl: 'https://example.com/image.jpg',
                    nostrKey: 'key-${entry.key}',
                    createdAt: testTimestampOverlay,
                    fileMetadata: const FileMetadata(
                      blurhash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
                    ),
                  ),
                )
                .toList();

        final mockNotifier = _MockMediaFileDownloadsNotifier();

        await tester.pumpWidget(
          createTestWidget(
            MediaModal(
              mediaFiles: mediaFiles,
              initialIndex: 0,
              senderName: 'Test User',
              senderImagePath: null,
              timestamp: testTimestampOverlay,
            ),
            overrides: [
              mediaFileDownloadsProvider.overrideWith(() => mockNotifier),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('media_image_gesture_detector_${mediaFiles[0].id}')));

        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        final headerFade = tester.widget<FadeTransition>(
          find.byKey(const Key('media_modal_header_fade')),
        );
        expect(headerFade.opacity.value, equals(0.0));
        final headerIgnorePointer = tester.widget<IgnorePointer>(
          find.descendant(
            of: find.byKey(const Key('media_modal_header_fade')),
            matching: find.byType(IgnorePointer),
          ),
        );
        expect(headerIgnorePointer.ignoring, isTrue);

        final thumbnailFade = tester.widget<FadeTransition>(
          find.byKey(const Key('media_modal_thumbnail_fade')),
        );
        expect(thumbnailFade.opacity.value, equals(0.0));

        final thumbnailIgnorePointer = tester.widget<IgnorePointer>(
          find
              .descendant(
                of: find.byKey(const Key('media_modal_thumbnail_fade')),
                matching: find.byType(IgnorePointer),
              )
              .first,
        );
        expect(thumbnailIgnorePointer.ignoring, isTrue);

        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
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
