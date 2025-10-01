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
    DateTime? timestamp,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _secureStorage;
    try {
      final readTimestamp = timestamp ?? DateTime.now();
      final key = '$_lastReadPrefix$groupId';
      await secureStorage.write(
        key: key,
        value: readTimestamp.millisecondsSinceEpoch.toString(),
      );
      _logger.fine('Set last read for group $groupId: $readTimestamp');
    } catch (e) {
      _logger.warning('Error setting last read for group $groupId: $e');
      rethrow;
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
}
