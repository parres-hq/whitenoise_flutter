import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/domain/models/media_file_download.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_grid.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

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
  group('MessageMediaGrid', () {
    final testCreatedAt = DateTime.now();

    MediaFile createTestMediaFile({required String id}) {
      return MediaFile(
        id: id,
        mlsGroupId: 'group-id',
        accountPubkey: 'pubkey',
        filePath: '/path/to/file-$id.jpg',
        originalFileHash: 'hash-$id',
        encryptedFileHash: 'encrypted-hash-$id',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/image-$id.jpg',
        nostrKey: 'key-$id',
        createdAt: testCreatedAt,
      );
    }

    group('without media files', () {
      testWidgets('renders nothing', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            const MessageMediaGrid(mediaFiles: []),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNothing);
      });
    });

    group('with 1 media file', () {
      testWidgets('renders 1 tile', (WidgetTester tester) async {
        final mediaFiles = [createTestMediaFile(id: '1')];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsOneWidget);
      });

      testWidgets('does not show overlay', (WidgetTester tester) async {
        final mediaFiles = [createTestMediaFile(id: '1')];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.textContaining('+'), findsNothing);
      });

      testWidgets('has correct grid width', (WidgetTester tester) async {
        final mediaFiles = [createTestMediaFile(id: '1')];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(MessageMediaGrid),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
        final maxBubbleWidth = screenWidth * 0.74;
        final padding = 16.w;
        final maxMediaWidth = maxBubbleWidth - padding;
        final layoutConfig = MediaLayoutCalculator.calculateLayout(1, maxMediaWidth);

        expect(sizedBox.width, closeTo(layoutConfig.gridWidth, 0.1));
      });
    });

    group('with 2 media files', () {
      testWidgets('renders 2 tiles', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(2));
      });

      testWidgets('does not show + text overlay', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.textContaining('+'), findsNothing);
      });

      testWidgets('has correct grid width', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(MessageMediaGrid),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
        final maxBubbleWidth = screenWidth * 0.74;
        final padding = 16.w;
        final maxMediaWidth = maxBubbleWidth - padding;
        final layoutConfig = MediaLayoutCalculator.calculateLayout(2, maxMediaWidth);

        expect(sizedBox.width, closeTo(layoutConfig.gridWidth, 0.1));
      });
    });

    group('with 3 media files', () {
      testWidgets('renders 3 tiles', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
          createTestMediaFile(id: '3'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(3));
      });

      testWidgets('does not show overlay', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
          createTestMediaFile(id: '3'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.textContaining('+'), findsNothing);
      });

      testWidgets('has correct grid width', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
          createTestMediaFile(id: '3'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(MessageMediaGrid),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
        final maxBubbleWidth = screenWidth * 0.74;
        final padding = 16.w;
        final maxMediaWidth = maxBubbleWidth - padding;
        final layoutConfig = MediaLayoutCalculator.calculateLayout(3, maxMediaWidth);

        expect(sizedBox.width, closeTo(layoutConfig.gridWidth, 0.1));
      });
    });

    group('with 4 media files', () {
      testWidgets('renders 3 tiles', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          4,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(3));
      });

      testWidgets('shows overlay with +1', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          4,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.text('+1'), findsOneWidget);
      });
    });

    group('with 5 media files', () {
      testWidgets('renders 3 tiles', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          5,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(3));
      });

      testWidgets('shows overlay with +2', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          5,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.text('+2'), findsOneWidget);
      });
    });

    group('with 6 media files', () {
      testWidgets('renders 6 tiles', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          6,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(6));
      });

      testWidgets('does not show overlay', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          6,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.textContaining('+'), findsNothing);
      });

      testWidgets('has correct grid width', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          6,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        await tester.pumpAndSettle();

        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(MessageMediaGrid),
                matching: find.byType(SizedBox),
              )
              .first,
        );

        final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
        final maxBubbleWidth = screenWidth * 0.74;
        final padding = 16.w;
        final maxMediaWidth = maxBubbleWidth - padding;
        final layoutConfig = MediaLayoutCalculator.calculateLayout(6, maxMediaWidth);

        expect(sizedBox.width, closeTo(layoutConfig.gridWidth, 0.1));
      });
    });

    group('with 7 media files', () {
      testWidgets('renders 6 tiles', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          7,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(6));
      });

      testWidgets('shows overlay with +1', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          7,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.text('+1'), findsOneWidget);
      });
    });

    group('with 10 media files', () {
      testWidgets('renders 6 tiles', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          10,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNWidgets(6));
      });

      testWidgets('shows overlay with +4', (WidgetTester tester) async {
        final mediaFiles = List.generate(
          10,
          (index) => createTestMediaFile(id: '${index + 1}'),
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
          ),
        );

        expect(find.text('+4'), findsOneWidget);
      });
    });

    group('downloads', () {
      late _MockMediaFileDownloadsNotifier mockNotifier;

      setUp(() {
        mockNotifier = _MockMediaFileDownloadsNotifier();
      });

      testWidgets('downloads media files when grid has files', (WidgetTester tester) async {
        final mediaFiles = [
          createTestMediaFile(id: '1'),
          createTestMediaFile(id: '2'),
        ];

        await tester.pumpWidget(
          createTestWidget(
            MessageMediaGrid(mediaFiles: mediaFiles),
            overrides: [
              mediaFileDownloadsProvider.overrideWith(() => mockNotifier),
            ],
          ),
        );

        expect(mockNotifier.downloadedMediaFiles, equals(mediaFiles));
      });
    });
  });
}
