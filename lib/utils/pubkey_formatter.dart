import 'package:whitenoise/src/rust/api/utils.dart' as wn_utils_api;
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class PubkeyFormatter {
  final String? _pubkey;
  final String? Function({required String hexPubkey}) _npubFromHexPubkey;
  final String? Function({required String npub}) _hexPubkeyFromNpub;

  PubkeyFormatter({
    String? pubkey,
    String? Function({required String hexPubkey})? npubFromHexPubkey,
    String? Function({required String npub})? hexPubkeyFromNpub,
  }) : _pubkey = pubkey,
       _npubFromHexPubkey = npubFromHexPubkey ?? wn_utils_api.npubFromHexPubkey,
       _hexPubkeyFromNpub = hexPubkeyFromNpub ?? wn_utils_api.hexPubkeyFromNpub;

  String? toNpub() {
    if (_pubkey == null) return null;
    final trimmedPubkey = _pubkey.trim().toLowerCase();
    final PublicKeyType? pubkeyType = trimmedPubkey.publicKeyType;
    if (!trimmedPubkey.isValidPublicKey) return null;

    if (pubkeyType == PublicKeyType.npub) {
      return trimmedPubkey;
    } else if (pubkeyType == PublicKeyType.hex) {
      try {
        final npub = _npubFromHexPubkey(hexPubkey: trimmedPubkey);
        return npub;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? toHex() {
    if (_pubkey == null) return null;
    final trimmedPubkey = _pubkey.trim().toLowerCase();
    final PublicKeyType? pubkeyType = trimmedPubkey.publicKeyType;
    if (!trimmedPubkey.isValidPublicKey) return null;

    if (pubkeyType == PublicKeyType.hex) {
      return trimmedPubkey;
    } else if (pubkeyType == PublicKeyType.npub) {
      try {
        final hex = _hexPubkeyFromNpub(npub: trimmedPubkey);
        return hex;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
