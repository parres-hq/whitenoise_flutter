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

  static Future<void> setLastRead({required String groupId, FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final timestamp = DateTime.now();
      final key = '$_lastReadPrefix$groupId';
      await secureStorage.write(
        key: key,
        value: timestamp.millisecondsSinceEpoch.toString(),
      );
      _logger.fine('Set last read for group $groupId: $timestamp');
    } catch (e) {
      _logger.warning('Error setting last read for group $groupId: $e');
    }
  }

  static Future<DateTime?> getLastRead({
    required String groupId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final key = '$_lastReadPrefix$groupId';
      final value = await secureStorage.read(key: key);
      if (value == null) return null;
      final milliseconds = int.tryParse(value);
      if (milliseconds == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      _logger.warning('Error getting last read for group $groupId: $e');
      return null;
    }
  }

  static Future<void> clearLastRead({
    required String groupId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final key = '$_lastReadPrefix$groupId';
      await secureStorage.delete(key: key);
      _logger.fine('Cleared last read for group $groupId');
    } catch (e) {
      _logger.warning('Error clearing last read for group $groupId: $e');
    }
  }

  static Future<void> clearAllLastReads({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final allKeys = await secureStorage.readAll();
      final lastReadKeys = allKeys.keys.where((key) => key.startsWith(_lastReadPrefix));
      for (final key in lastReadKeys) {
        await secureStorage.delete(key: key);
      }
      _logger.info('Cleared all last read timestamps');
    } catch (e) {
      _logger.warning('Error clearing all last reads: $e');
      rethrow;
    }
  }
}
