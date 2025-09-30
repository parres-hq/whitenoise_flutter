import 'package:shared_preferences/shared_preferences.dart';

class NotificationIdService {
  static const String _mapPrefix = 'notif_id_';
  static const int _minId = 1;
  static const int _maxId = 0x7fffffff;

  static Future<int> getIdFor({required String key}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String storageKey = '$_mapPrefix$key';
    final int? existingId = prefs.getInt(storageKey);
    if (existingId != null) {
      return existingId;
    }
    // Generate a deterministic, process-safe ID without relying on a shared counter
    final int hashedId = _stableHashToId(key);
    await prefs.setInt(storageKey, hashedId);
    return hashedId;
  }

  static int _stableHashToId(String input) {
    // FNV-1a 32-bit hash for stable, consistent IDs across isolates/sessions
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffset;
    final List<int> bytes = input.codeUnits;
    for (final int byte in bytes) {
      hash ^= byte & 0xFF;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // Map to positive 31-bit Android-friendly range [ _minId, _maxId ]
    final int positive = hash & 0x7FFFFFFF;
    final int range = _maxId - _minId;
    final int mapped = _minId + (positive % range);
    return mapped;
  }
}
