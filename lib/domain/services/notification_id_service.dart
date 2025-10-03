import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class NotificationIdService {
  static const String _mapPrefix = 'notif_id_';
  static const String _reverseMapPrefix = 'notif_id_rev_';
  static const int _minId = 1;
  static const int _maxId = 0x7fffffff;
  static final Lock _lock = Lock();

  static Future<int> getIdFor({required String key}) async {
    return await _lock.synchronized(() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String storageKey = '$_mapPrefix$key';
      final int? existingId = prefs.getInt(storageKey);
      if (existingId != null) {
        return existingId;
      }
      // Generate a deterministic, process-safe ID without relying on a shared counter
      final int preferredId = _stableHashToId(key);
      final int allocated = await _allocateId(prefs: prefs, key: key, preferredId: preferredId);
      await prefs.setInt(storageKey, allocated);
      return allocated;
    });
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

  static Future<int> _allocateId({
    required SharedPreferences prefs,
    required String key,
    required int preferredId,
  }) async {
    // If preferredId is unused or already mapped to this key, claim it
    final String revKeyPreferred = '$_reverseMapPrefix$preferredId';
    final String? existingKeyForPreferred = prefs.getString(revKeyPreferred);
    if (existingKeyForPreferred == null || existingKeyForPreferred == key) {
      await _setReverseMapping(prefs: prefs, id: preferredId, key: key);
      return preferredId;
    }

    // Collision: probe deterministically to find a free ID
    // Linear probing within the allowed range to avoid requiring randomness
    final int range = _maxId - _minId;
    for (int i = 1; i <= 1024; i++) {
      final int candidate = _minId + (((preferredId - _minId) + i) % range);
      final String revKey = '$_reverseMapPrefix$candidate';
      final String? existingKey = prefs.getString(revKey);
      if (existingKey == null || existingKey == key) {
        await _setReverseMapping(prefs: prefs, id: candidate, key: key);
        return candidate;
      }
    }

    // Fallback: last resort, overwrite own mapping using a salted hash
    // This reduces the likelihood of repeated collisions across sessions
    for (int salt = 1; salt <= 5; salt++) {
      final int salted = _stableHashToId('$key#$salt');
      final String revKey = '$_reverseMapPrefix$salted';
      final String? existingKey = prefs.getString(revKey);
      if (existingKey == null || existingKey == key) {
        await _setReverseMapping(prefs: prefs, id: salted, key: key);
        return salted;
      }
    }

    throw Exception('Unable to allocate unique notification ID for key: $key');
  }

  static Future<void> _setReverseMapping({
    required SharedPreferences prefs,
    required int id,
    required String key,
  }) async {
    await prefs.setString('$_reverseMapPrefix$id', key);
  }
}
