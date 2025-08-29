import 'package:whitenoise/src/rust/api/utils.dart' as wn_utils_api;

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
      return await wn_utils_api.npubFromHexPubkey(hexPubkey: this);
    } catch (e) {
      return null;
    }
  }

  /// Capitalizes the first letter of the string
  String get capitalizeFirst {
    if (isEmpty) return '';
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Sanitizes a URL for display by removing protocol prefix but preserving port
  /// Example: "wss://relay.example.com:443" -> "relay.example.com:443"
  String get sanitizedUrl {
    String url = this;

    // Remove protocol prefixes
    final prefixes = ['wss://', 'ws://', 'https://', 'http://'];
    for (final prefix in prefixes) {
      if (url.startsWith(prefix)) {
        url = url.substring(prefix.length);
        break;
      }
    }

    return url;
  }
}
