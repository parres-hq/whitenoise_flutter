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

  @override
  bool build() => false;

  void startPolling() {
    if (state) return;
    _logger.info('Starting data polling');
    state = true;

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
    if (!state) return;

    _logger.info('Stopping data polling');
    state = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Load initial data (full load on first run)
  Future<void> _loadInitialData() async {
    if (!state) return;

    try {
      _logger.info('Loading initial data');

      // Load all data fully on first run
      await ref.read(welcomesProvider.notifier).loadWelcomes();
      await ref.read(groupsProvider.notifier).loadGroups();

      // Load messages for all groups
      final groups = ref.read(groupsProvider).groups;
      if (groups != null && groups.isNotEmpty) {
        final groupIds = groups.map((g) => g.mlsGroupId).toList();
        await ref.read(chatProvider.notifier).loadMessagesForGroups(groupIds);
      }

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
