import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';

class PollingNotifier extends Notifier<bool> {
  static final _logger = Logger('PollingNotifier');
  Timer? _pollingTimer;
  bool _hasInitialDataLoaded = false;
  bool _isDisposed = false;

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

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadIncrementalData();
    });
  }

  /// Stop polling
  void stopPolling() {
    if (_isDisposed || !state) return;

    _logger.info('Stopping data polling');

    // Cancel timer first before changing state
    _pollingTimer?.cancel();
    _pollingTimer = null;

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

      // Load messages for all groups in a build-safe way
      // Schedule this in a microtask to ensure it happens after the current build cycle
      Future.microtask(() async {
        try {
          final groups = ref.read(groupsProvider).groups;
          if (groups != null && groups.isNotEmpty) {
            final groupIds = groups.map((g) => g.mlsGroupId).toList();
            _logger.info(
              'PollingProvider: Loading messages for ${groupIds.length} groups for chat previews',
            );
            await ref.read(chatProvider.notifier).loadMessagesForGroups(groupIds);
            _logger.info('PollingProvider: Message loading completed for chat previews');
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

      // Check for new messages incrementally
      final groups = ref.read(groupsProvider).groups;
      if (groups != null && groups.isNotEmpty) {
        final groupIds = groups.map((g) => g.mlsGroupId).toList();
        await ref.read(chatProvider.notifier).checkForNewMessagesInGroups(groupIds);
      }

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
}

final pollingProvider = NotifierProvider<PollingNotifier, bool>(
  PollingNotifier.new,
);
