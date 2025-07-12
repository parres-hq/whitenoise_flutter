import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

extension StringExtensions on String {
  /// Formats the public key by adding a space every 5 characters
  String formatPublicKey() {
    return replaceAllMapped(
      RegExp(r'.{5}'),
      (match) => '${match.group(0)} ',
    );
  }

  /// Converts a hex pubkey to npub format
  /// Returns null if conversion fails
  Future<String?> toNpub() async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: this);
      return await exportAccountNpub(pubkey: publicKey);
    } catch (e) {
      return null;
    }
  }

  /// Capitalizes the first letter of the string
  String get capitalizeFirst {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
