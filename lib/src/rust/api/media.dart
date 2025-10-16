import 'dart:io';
import 'package:whitenoise/utils/image_utils.dart';

class FileMetadata {
  final String blurhash;
  final String dimensions;

  const FileMetadata({
    required this.blurhash,
    required this.dimensions,
  });
}

Future<MediaFile> uploadMedia({
  required String accountPubkey,
  required String groupId,
  required String filePath,
}) async {
  final file = File(filePath);

  if (!file.existsSync()) {
    throw Exception('File not found: $filePath');
  }

  final mimeType = await ImageUtils.getMimeTypeFromPath(filePath) ?? 'image/jpeg';

  final metadata = const FileMetadata(
    blurhash: 'PLACEHOLDER_BLURHASH',
    dimensions: '250x200',
  );

  final blossomUrl = 'whitenoise.chat';

  // sleep for 3 seconds
  await Future.delayed(const Duration(seconds: 3));

  return MediaFile(
    filePath: filePath,
    mediaType: MediaType.chatMedia,
    fileMetadata: metadata,
    blossomUrl: blossomUrl,
    mimeType: mimeType,
  );
}

class MediaFile {
  final String filePath;
  final MediaType mediaType;
  final FileMetadata fileMetadata;
  final String mimeType;
  final String blossomUrl;

  const MediaFile({
    required this.filePath,
    required this.mediaType,
    required this.fileMetadata,
    required this.mimeType,
    required this.blossomUrl,
  });
}

enum MediaType { chatMedia, groupImage }
