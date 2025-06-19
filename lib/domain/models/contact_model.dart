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
    Metadata? metadata,
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
}
