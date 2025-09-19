import 'package:whitenoise/utils/pubkey_formatter.dart';

class PubkeyUtils {
  static bool isMe({required String myPubkey, required String otherPubkey}) {
    final myHexPubkey = PubkeyFormatter(pubkey: myPubkey).toHex();
    final otherHexPubkey = PubkeyFormatter(pubkey: otherPubkey).toHex();
    if (myHexPubkey == null ||
        myHexPubkey.isEmpty ||
        otherHexPubkey == null ||
        otherHexPubkey.isEmpty) {
      return false;
    }

    return myHexPubkey == otherHexPubkey;
  }
}
