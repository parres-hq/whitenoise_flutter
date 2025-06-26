// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:whitenoise/src/rust/api.dart';

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

  // Create ContactModel from Rust API Metadata
  factory ContactModel.fromMetadata({
    required String publicKey,
    MetadataData? metadata,
  }) {
    return ContactModel(
      name: metadata?.name ?? metadata?.displayName ?? 'Unknown',
      displayName: metadata?.displayName,
      publicKey: publicKey,
      imagePath: metadata?.picture,
      about: metadata?.about,
      website: metadata?.website,
      nip05: metadata?.nip05,
      lud16: metadata?.lud16,
    );
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
