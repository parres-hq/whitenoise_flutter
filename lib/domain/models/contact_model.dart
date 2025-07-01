// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:whitenoise/src/rust/api/utils.dart';

class ContactModel {
  final String name;
  final String publicKey;
  final String? imagePath;
  final String? displayName;
  final String? about;
  final String? website;
  final String? nip05;
  final String? lud16;

  ContactModel({
    required this.name,
    required this.publicKey,
    this.imagePath,
    this.displayName,
    this.about,
    this.website,
    this.nip05,
    this.lud16,
  });

  // Create ContactModel from Rust API Metadata with proper sanitization
  factory ContactModel.fromMetadata({
    required String publicKey,
    MetadataData? metadata,
  }) {
    // Sanitize and clean data
    final name = _sanitizeString(metadata?.name);
    final displayName = _sanitizeString(metadata?.displayName);
    final about = _sanitizeString(metadata?.about);
    final website = _sanitizeUrl(metadata?.website);
    final nip05 = _sanitizeString(metadata?.nip05);
    final lud16 = _sanitizeString(metadata?.lud16);
    final picture = _sanitizeUrl(metadata?.picture);

    // Determine the best name to use
    final effectiveName =
        name.isNotEmpty
            ? name
            : displayName.isNotEmpty
            ? displayName
            : 'Unknown User';

    return ContactModel(
      name: effectiveName,
      displayName: displayName.isNotEmpty ? displayName : null,
      publicKey: publicKey,
      imagePath: picture,
      about: about.isNotEmpty ? about : null,
      website: website,
      nip05: nip05.isNotEmpty ? nip05 : null,
      lud16: lud16.isNotEmpty ? lud16 : null,
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

  // Get display name with fallback
  String get displayNameOrName => displayName ?? name;

  // Get first letter for avatar
  String get avatarLetter => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  bool operator ==(covariant ContactModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.publicKey == publicKey &&
        other.imagePath == imagePath &&
        other.displayName == displayName &&
        other.about == about &&
        other.website == website &&
        other.nip05 == nip05 &&
        other.lud16 == lud16;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        publicKey.hashCode ^
        imagePath.hashCode ^
        displayName.hashCode ^
        about.hashCode ^
        website.hashCode ^
        nip05.hashCode ^
        lud16.hashCode;
  }
}
