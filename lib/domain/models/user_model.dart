// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class User {
  final String id;
  final String displayName;
  final String nip05;
  final String publicKey;
  final String? imagePath;

  User({
    required this.id,
    required this.displayName,
    required this.nip05,
    required this.publicKey,
    this.imagePath,
  });

  factory User.fromMetadata(FlutterMetadata metadata, String publicKey) {
    return User(
      id: publicKey,
      displayName: metadata.displayName ?? 'Unknown',
      nip05: metadata.nip05 ?? '',
      publicKey: publicKey,
      imagePath: metadata.picture,
    );
  }

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.displayName == displayName &&
        other.nip05 == nip05 &&
        other.publicKey == publicKey &&
        other.imagePath == imagePath;
  }

  @override
  int get hashCode {
    return Object.hash(id, displayName, nip05, publicKey, imagePath);
  }
}
