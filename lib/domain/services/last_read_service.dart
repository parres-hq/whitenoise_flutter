import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class LastReadService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _lastReadPrefix = 'last_read_';
  static final _logger = Logger('LastReadService');

  static Future<void> setLastRead({
    required String groupId,
    required String activePubkey,
    DateTime? timestamp,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final readTimestamp = timestamp ?? DateTime.now();
      final key = '$_lastReadPrefix${activePubkey}_$groupId';
      await secureStorage.write(
        key: key,
        value: readTimestamp.millisecondsSinceEpoch.toString(),
      );
      _logger.fine('Set last read for group $groupId (pubkey: $activePubkey): $readTimestamp');
    } catch (e) {
      _logger.severe('Error setting last read for group $groupId (pubkey: $activePubkey): $e');
    }
  }

  static Future<DateTime?> getLastRead({
    required String groupId,
    required String activePubkey,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final key = '$_lastReadPrefix${activePubkey}_$groupId';
      final value = await secureStorage.read(key: key);
      if (value == null) return null;
      final milliseconds = int.tryParse(value);
      if (milliseconds == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      _logger.severe('Error getting last read for group $groupId (pubkey: $activePubkey): $e');
      return null;
    }
  }
}
