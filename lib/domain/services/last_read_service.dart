import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastReadService {
  static final Future<SharedPreferences> _preferences = SharedPreferences.getInstance();
  static const String _lastReadPrefix = 'last_read_';
  static final _logger = Logger('LastReadService');

  static Future<void> setLastRead({
    required String groupId,
    required String activePubkey,
    DateTime? timestamp,
  }) async {
    try {
      final readTimestamp = timestamp ?? DateTime.now();
      final key = '$_lastReadPrefix${activePubkey}_$groupId';
      final prefs = await _preferences;
      await prefs.setInt(key, readTimestamp.millisecondsSinceEpoch);
      _logger.fine('Set last read for group $groupId (pubkey: $activePubkey): $readTimestamp');
    } catch (e) {
      _logger.severe('Error setting last read for group $groupId (pubkey: $activePubkey): $e');
    }
  }

  static Future<DateTime?> getLastRead({
    required String groupId,
    required String activePubkey,
  }) async {
    try {
      final key = '$_lastReadPrefix${activePubkey}_$groupId';
      final prefs = await _preferences;
      final milliseconds = prefs.getInt(key);
      if (milliseconds == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      _logger.severe('Error getting last read for group $groupId (pubkey: $activePubkey): $e');
      return null;
    }
  }
}
