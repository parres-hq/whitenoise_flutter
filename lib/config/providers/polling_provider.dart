import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';

class PollingNotifier extends Notifier<bool> {
  static final _logger = Logger('PollingNotifier');
  Timer? _pollingTimer;
  bool _hasInitialDataLoaded = false;
  bool _isDisposed = false;
  bool _isPollingInProgress = false;
  int _nextGroupIndexForIncremental = 0;

  static const Duration _pollingInterval = Duration(seconds: 2);
  static const int _maxGroupsForInitialMessagePreload = 50;
  static const int _maxGroupsPerIncrementalTick = 10;

  @override
  bool build() => false;

  void startPolling() {
    if (_isDisposed || state) return;
    _logger.info('Starting data polling');

    try {
      state = true;
    } catch (e) {
      _logger.warning('Failed to set polling state to true: $e');
      return;
    }

    // Load initial data if not already loaded
    if (!_hasInitialDataLoaded) {
      _loadInitialData();
    } else {
      _loadIncrementalData();
    }

    const Duration interval = _pollingInterval;

    _pollingTimer = Timer.periodic(interval, (_) async {
      if (_isPollingInProgress) {
        _logger.fine('Skipping polling tick because a previous run is still in progress');
        return;
      }
      _isPollingInProgress = true;
      try {
        await _loadIncrementalData();
      } finally {
        _isPollingInProgress = false;
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    if (_isDisposed || !state) return;

    _logger.info('Stopping data polling');

    // Cancel timer first before changing state
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingInProgress = false;
    _nextGroupIndexForIncremental = 0;

    // Try to set state, but don't fail if provider is being disposed
    try {
      state = false;
    } catch (e) {
      _logger.warning('Failed to set polling state to false (provider may be disposed): $e');
      // This is ok during disposal - the timer is already cancelled
    }
  }

  /// Safely dispose resources without modifying state
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingInProgress = false;
    _nextGroupIndexForIncremental = 0;
    _logger.info('Polling provider disposed');
  }

  /// Load initial data (full load on first run)
  Future<void> _loadInitialData() async {
    if (!state) return;

    try {
      _logger.info('Loading initial data');

      // Load all data fully on first run
      await ref.read(welcomesProvider.notifier).loadWelcomes();
      await ref.read(groupsProvider.notifier).loadGroups();
      await ref.read(relayStatusProvider.notifier).refreshStatuses();
      ref.invalidate(activeAccountProvider);

      // Load messages for all groups in a build-safe way
      // Schedule this in a microtask to ensure it happens after the current build cycle
      Future.microtask(() async {
        try {
          final groups = ref.read(groupsProvider).groups;
          if (groups != null && groups.isNotEmpty) {
            final groupIds = groups.map((g) => g.mlsGroupId).toList();
            final initialGroupIds = groupIds.take(_maxGroupsForInitialMessagePreload).toList();
            _logger.info(
              'PollingProvider: Loading messages for ${initialGroupIds.length} '
              'groups (of ${groupIds.length}) for chat previews',
            );
            await ref.read(chatProvider.notifier).loadMessagesForGroups(initialGroupIds);

            _logger.info('PollingProvider: Message loading completed for initial chat previews');
          }
        } catch (e) {
          _logger.warning('Error loading messages for chat previews: $e');
        }
      });

      _hasInitialDataLoaded = true;
      _logger.info('Initial data load completed');
    } catch (e) {
      _logger.warning('Error during initial data load: $e');
    }
  }

  /// Poll all data sources incrementally (for subsequent runs)
  Future<void> _loadIncrementalData() async {
    if (!state) return;

    try {
      // Check for new welcomes incrementally
      await ref.read(welcomesProvider.notifier).checkForNewWelcomes();

      // Check for new groups incrementally
      await ref.read(groupsProvider.notifier).checkForNewGroups();

      // Check relay status regularly
      await ref.read(relayStatusProvider.notifier).refreshStatuses();

      // Check for new messages incrementally
      final groups = ref.read(groupsProvider).groups;
      if (groups != null && groups.isNotEmpty) {
        final groupIds = groups.map((g) => g.mlsGroupId).toList();
        final batch = _getNextGroupBatch(groupIds);
        if (batch.isNotEmpty) {
          _logger.fine(
            'PollingProvider: Checking for new messages in ${batch.length} group(s) '
            'out of ${groupIds.length}',
          );
          await ref.read(chatProvider.notifier).checkForNewMessagesInGroups(batch);
        }
      }

      ref.invalidate(activeAccountProvider);

      _logger.fine('Incremental polling completed');
    } catch (e) {
      _logger.warning('Error during incremental polling: $e');
    }
  }

  Future<void> pollNow() async {
    if (!_hasInitialDataLoaded) {
      await _loadInitialData();
    } else {
      await _loadIncrementalData();
    }
  }

  List<String> _getNextGroupBatch(List<String> allGroupIds) {
    if (allGroupIds.isEmpty) {
      _nextGroupIndexForIncremental = 0;
      return <String>[];
    }

    if (_nextGroupIndexForIncremental >= allGroupIds.length) {
      _nextGroupIndexForIncremental = 0;
    }

    final List<String> batch = <String>[];
    for (int i = 0; i < _maxGroupsPerIncrementalTick; i++) {
      if (allGroupIds.isEmpty) {
        break;
      }
      if (_nextGroupIndexForIncremental >= allGroupIds.length) {
        _nextGroupIndexForIncremental = 0;
      }
      batch.add(allGroupIds[_nextGroupIndexForIncremental]);
      _nextGroupIndexForIncremental++;
      if (_nextGroupIndexForIncremental >= allGroupIds.length &&
          batch.length >= _maxGroupsPerIncrementalTick) {
        break;
      }
    }

    return batch;
  }
}

final pollingProvider = NotifierProvider<PollingNotifier, bool>(
  PollingNotifier.new,
);
