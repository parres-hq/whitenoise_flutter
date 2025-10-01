import 'dart:async';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';

/// Manages efficient saving of last read timestamps for chat groups.
/// Uses debouncing and throttling to avoid excessive writes while ensuring
/// important user interactions are captured.
class LastReadManager {
  static final _logger = Logger('LastReadManager');

  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, Timer> _throttleTimers = {};
  static final Map<String, DateTime> _lastSavedTimestamps = {};
  static final Map<String, DateTime> _pendingTimestamps = {};

  static const Duration _scrollDebounceDelay = Duration(seconds: 2);
  static const Duration _scrollThrottleDelay = Duration(milliseconds: 500);
  static const Duration _minSaveInterval = Duration(seconds: 1);
  static const int _maxCachedGroups = 100;

  static Future<void> saveLastReadImmediate(String groupId, DateTime messageCreatedAt) async {
    try {
      final lastSaved = _lastSavedTimestamps[groupId];
      if (lastSaved != null && DateTime.now().difference(lastSaved) < _minSaveInterval) {
        _logger.fine('Skipping immediate save for $groupId - too recent');
        return;
      }
      await LastReadService.setLastRead(groupId: groupId, timestamp: messageCreatedAt);
      _lastSavedTimestamps[groupId] = messageCreatedAt;
      _pendingTimestamps.remove(groupId);
      _cleanupOldEntries();
      _logger.fine('Immediate save: Set last read for group $groupId at $messageCreatedAt');
    } catch (e) {
      _logger.warning('Failed to save last read immediately for group $groupId', e);
    }
  }

  static void saveLastReadDebounced(String groupId, DateTime messageCreatedAt) {
    _pendingTimestamps[groupId] = messageCreatedAt;
    _debounceTimers[groupId]?.cancel();
    _debounceTimers[groupId] = Timer(_scrollDebounceDelay, () async {
      final timestamp = _pendingTimestamps[groupId];
      if (timestamp != null) {
        await saveLastReadImmediate(groupId, timestamp);
      }
      _debounceTimers.remove(groupId);
    });
  }

  static void saveLastReadThrottled(String groupId, DateTime messageCreatedAt) {
    if (_throttleTimers.containsKey(groupId)) {
      return;
    }

    _pendingTimestamps[groupId] = messageCreatedAt;
    _throttleTimers[groupId] = Timer(_scrollThrottleDelay, () async {
      final timestamp = _pendingTimestamps[groupId];
      if (timestamp != null) {
        await saveLastReadImmediate(groupId, timestamp);
      }
      _throttleTimers.remove(groupId);
    });
  }

  static Future<void> saveLastReadForLatestMessage(
    String groupId,
    List<dynamic> messages,
  ) async {
    if (messages.isEmpty) return;

    DateTime? latestMessageCreatedAt;
    for (final message in messages) {
      final messageCreatedAt = message.createdAt;
      if (latestMessageCreatedAt == null || messageCreatedAt.isAfter(latestMessageCreatedAt)) {
        latestMessageCreatedAt = messageCreatedAt;
      }
    }

    if (latestMessageCreatedAt != null) {
      await saveLastReadImmediate(groupId, latestMessageCreatedAt);
    }
  }

  static void cancelPendingSaves(String groupId) {
    _debounceTimers[groupId]?.cancel();
    _throttleTimers[groupId]?.cancel();
    _debounceTimers.remove(groupId);
    _throttleTimers.remove(groupId);
  }

  static void cancelAllPendingSaves() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _throttleTimers.clear();
  }

  static void _cleanupOldEntries() {
    if (_lastSavedTimestamps.length > _maxCachedGroups) {
      final entries =
          _lastSavedTimestamps.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

      for (int i = 0; i < entries.length - _maxCachedGroups; i++) {
        _lastSavedTimestamps.remove(entries[i].key);
      }
    }
  }

  static void dispose() {
    cancelAllPendingSaves();
    _lastSavedTimestamps.clear();
    _pendingTimestamps.clear();
  }
}
