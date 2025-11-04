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
      expect(pageView.controller!.initialPage, equals(0));
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
      expect(pageView.controller!.initialPage, equals(2));
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
  });
}
