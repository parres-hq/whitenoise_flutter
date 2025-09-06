import 'package:whitenoise/src/rust/api/utils.dart' show hexPubkeyFromNpub, npubFromHexPubkey;

/// Extension for validating public keys in various formats
/// Supports both hex format (64 characters) and npub format (bech32)

extension PublicKeyValidationExtension on String {
  /// Validates if the string is a valid public key
  ///
  /// Supports:
  /// - Hex format: 64 hexadecimal characters (0-9, a-f, A-F)
  /// - Npub format: starts with 'npub1' and has more than 10 characters
  ///
  /// Returns true if the string is a valid public key format
  bool get isValidPublicKey {
    final trimmed = trim();

    // Check if it's a hex key (64 characters)
    if (trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) {
      return true;
    }

    // Check if it's an npub format (bech32)
    if (trimmed.startsWith('npub1') && trimmed.length > 10) {
      return true;
    }

    return false;
  }

  /// Validates if the string is a valid hex public key (64 characters)
  bool get isValidHexPublicKey {
    final trimmed = trim();
    return trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed);
  }

  /// Validates if the string is a valid npub format public key
  bool get isValidNpubPublicKey {
    final trimmed = trim();
    return trimmed.startsWith('npub1') && trimmed.length > 10;
  }

  /// Returns the public key type if valid, null otherwise
  PublicKeyType? get publicKeyType {
    if (isValidHexPublicKey) return PublicKeyType.hex;
    if (isValidNpubPublicKey) return PublicKeyType.npub;
    return null;
  }

  /// Converts a hex pubkey to npub format
  /// If the pubkey is already in npub format, returns the original pubkey
  /// Returns null if conversion fails
  String? toNpub() {
    final trimmedPubkey = trim().toLowerCase();
    final PublicKeyType? pubkeyType = trimmedPubkey.publicKeyType;
    if (!trimmedPubkey.isValidPublicKey) return null;

    if (pubkeyType == PublicKeyType.npub) {
      return trimmedPubkey;
    } else if (pubkeyType == PublicKeyType.hex) {
      try {
        final npub = npubFromHexPubkey(hexPubkey: trimmedPubkey);
        return npub;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Converts a npub pubkey to hex format
  /// If the pubkey is already in hex format, returns the original pubkey
  /// Returns null if conversion fails
  String? toHex() {
    final trimmedPubkey = trim().toLowerCase();
    final PublicKeyType? pubkeyType = trimmedPubkey.publicKeyType;
    if (!trimmedPubkey.isValidPublicKey) return null;

    if (pubkeyType == PublicKeyType.hex) {
      return trimmedPubkey;
    } else if (pubkeyType == PublicKeyType.npub) {
      try {
        final hex = hexPubkeyFromNpub(npub: trimmedPubkey);
        return hex;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Enum representing different public key formats
enum PublicKeyType {
  /// Hexadecimal format (64 characters)
  hex,

  /// Npub format (bech32)
  npub,
}
