import 'package:whitenoise/config/providers/active_pubkey_provider.dart';

class MockActivePubkeyNotifier extends ActivePubkeyNotifier {
  String? pubkey;

  MockActivePubkeyNotifier(this.pubkey);

  @override
  String? build() {
    return pubkey;
  }

  @override
  Future<void> setActivePubkey(String newPubkey) async {
    pubkey = newPubkey;
    state = newPubkey;
  }
}
