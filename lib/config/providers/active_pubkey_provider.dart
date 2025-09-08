import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

// Default FlutterSecureStorage instance
const _defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

PubkeyFormatter _defaultPubkeyFormatter({String? pubkey}) => PubkeyFormatter(pubkey: pubkey);

class ActivePubkeyNotifier extends Notifier<String?> {
  final FlutterSecureStorage storage;
  final PubkeyFormatter Function({String? pubkey}) pubkeyFormatter;

  ActivePubkeyNotifier({
    FlutterSecureStorage? storage,
    PubkeyFormatter Function({String? pubkey})? pubkeyFormatter,
  }) : storage = storage ?? _defaultSecureStorage,
       pubkeyFormatter = pubkeyFormatter ?? _defaultPubkeyFormatter;

  @override
  String? build() {
    loadActivePubkey();
    return null;
  }

  Future<void> loadActivePubkey() async {
    final pubkey = await AccountSecureStorageService.getActivePubkey(storage: storage);
    final hexPubkey = pubkeyFormatter(pubkey: pubkey).toHex();
    state = hexPubkey;
  }

  Future<void> setActivePubkey(String pubkey) async {
    final hexPubkey = pubkeyFormatter(pubkey: pubkey).toHex();
    if (hexPubkey == null) {
      await clearActivePubkey();
    } else {
      await AccountSecureStorageService.setActivePubkey(hexPubkey, storage: storage);
    }
    state = hexPubkey;
  }

  Future<void> clearActivePubkey() async {
    await AccountSecureStorageService.clearActivePubkey(storage: storage);
    state = null;
  }

  Future<void> clearAllSecureStorage() async {
    await AccountSecureStorageService.clearAllSecureStorage(storage: storage);
    state = null;
  }
}

final activePubkeyProvider = NotifierProvider<ActivePubkeyNotifier, String?>(
  ActivePubkeyNotifier.new,
);
