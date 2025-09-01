import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class AccountSecureStorageService {
  static const String _activePubkey = 'active_account_pubkey';
  static final _logger = Logger('AccountSecureStorageService');

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> getActivePubkey({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final activePubkey = await secureStorage.read(key: _activePubkey);
      _logger.fine('AccountSecureStorageService: Read active pubkey $activePubkey');
      return activePubkey;
    } catch (e) {
      _logger.severe('AccountSecureStorageService: Error reading active pubkey $e');
      return null;
    }
  }

  static Future<void> setActivePubkey(String pubkey, {FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      await secureStorage.write(key: _activePubkey, value: pubkey);
      _logger.info('AccountSecureStorageService: Wrote active pubkey: $pubkey');
    } catch (e) {
      _logger.severe('Error writing active pubkey: $e');
      rethrow;
    }
  }

  static Future<void> clearActivePubkey({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      await secureStorage.delete(key: _activePubkey);
      _logger.info('AccountSecureStorageService: Cleared active pubkey');
    } catch (e) {
      _logger.severe('AccountSecureStorageService: Error clearing active pubkey $e');
      rethrow;
    }
  }

  static Future<void> clearAllSecureStorage({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      await secureStorage.deleteAll();
      _logger.info('AccountSecureStorageService: Cleared all secure storage data');
    } catch (e) {
      _logger.severe('AccountSecureStorageService: Error clearing all secure storage: $e');
      rethrow;
    }
  }
}
