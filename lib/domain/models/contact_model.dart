// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class ContactModel {
  final String publicKey;
  final String displayName;
  final String? imagePath;
  final String? about;
  final String? website;
  final String? nip05;
  final String? lud16;

  ContactModel({
    required this.publicKey,
    required this.displayName,
    this.imagePath,
    this.about,
    this.website,
    this.nip05,
    this.lud16,
  });

  // Create ContactModel from Rust API Metadata with proper sanitization
  factory ContactModel.fromMetadata({
    required String pubkey,
    FlutterMetadata? metadata,
  }) {
    // Sanitize and clean data
    final displayName = _sanitizeString(metadata?.displayName);
    final about = _sanitizeString(metadata?.about);
    final website = _sanitizeUrl(metadata?.website);
    final nip05 = _sanitizeString(metadata?.nip05);
    final lud16 = _sanitizeString(metadata?.lud16);
    final picture = _sanitizeUrl(metadata?.picture);
    final npub = pubkey.toNpub() ?? '';

    return ContactModel(
      displayName: displayName.isNotEmpty ? displayName : 'Unknown User',
      publicKey: npub,
      imagePath: picture,
      about: about,
      website: website,
      nip05: nip05,
      lud16: lud16,
    );
  }

  factory ContactModel.fromUser({
    required User user,
  }) {
    final metadata = user.metadata;
    final displayName = _sanitizeString(metadata.displayName);
    final about = _sanitizeString(metadata.about);
    final website = _sanitizeUrl(metadata.website);
    final nip05 = _sanitizeString(metadata.nip05);
    final lud16 = _sanitizeString(metadata.lud16);
    final picture = _sanitizeUrl(metadata.picture);

    return ContactModel(
      displayName: displayName.isNotEmpty ? displayName : 'Unknown User',
      publicKey: user.pubkey,
      imagePath: picture,
      about: about,
      website: website,
      nip05: nip05,
      lud16: lud16,
    );
  }

  // Helper method to sanitize strings
  static String _sanitizeString(String? input) {
    if (input == null) return '';
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Helper method to sanitize URLs
  static String? _sanitizeUrl(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final sanitized = input.trim();
    // Basic URL validation - could be enhanced
    if (sanitized.startsWith('http://') ||
        sanitized.startsWith('https://') ||
        sanitized.startsWith('data:image/')) {
      return sanitized;
    }
    return null;
  }

  // Get first letter for avatar
  String get avatarLetter => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

  @override
  bool operator ==(covariant ContactModel other) {
    if (identical(this, other)) return true;

    return other.publicKey == publicKey &&
        other.imagePath == imagePath &&
        other.displayName == displayName &&
        other.about == about &&
        other.website == website &&
        other.nip05 == nip05 &&
        other.lud16 == lud16;
  }

  @override
  int get hashCode {
    return Object.hash(publicKey, imagePath, displayName, about, website, nip05, lud16);
  }
}
