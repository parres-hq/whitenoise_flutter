import 'package:shared_preferences/shared_preferences.dart';

class NotificationIdService {
  static const String _counterKey = 'notification_id_counter';
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
    final int nextId = await _getAndIncrementCounter(prefs);
    await prefs.setInt(storageKey, nextId);
    return nextId;
  }

  static Future<int> _getAndIncrementCounter(SharedPreferences prefs) async {
    final int current = prefs.getInt(_counterKey) ?? _minId;
    final int next = current >= _maxId ? _minId : current + 1;
    await prefs.setInt(_counterKey, next);
    return current;
  }
}
