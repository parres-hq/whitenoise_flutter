import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whitenoise/domain/services/account_secure_storage_service.dart';

// Default FlutterSecureStorage instance
const _defaultSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

class ActivePubkeyNotifier extends Notifier<String?> {
  final FlutterSecureStorage storage;

  ActivePubkeyNotifier({FlutterSecureStorage? storage})
    : storage = storage ?? _defaultSecureStorage;

  @override
  String? build() {
    loadActivePubkey();
    return null;
  }

  Future<void> loadActivePubkey() async {
    final pubkey = await AccountSecureStorageService.getActivePubkey(storage: storage);
    state = pubkey?.trim();
  }

  Future<void> setActivePubkey(String pubkey) async {
    final trimmedPubkey = pubkey.trim();
    await AccountSecureStorageService.setActivePubkey(trimmedPubkey, storage: storage);
    state = trimmedPubkey;
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
