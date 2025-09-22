import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:whitenoise/config/providers/relay_status_provider.dart';

class DelayedRelayErrorState {
  final bool shouldShowBanner;
  final bool isDelayActive;

  const DelayedRelayErrorState({
    this.shouldShowBanner = false,
    this.isDelayActive = false,
  });

  DelayedRelayErrorState copyWith({
    bool? shouldShowBanner,
    bool? isDelayActive,
  }) {
    return DelayedRelayErrorState(
      shouldShowBanner: shouldShowBanner ?? this.shouldShowBanner,
      isDelayActive: isDelayActive ?? this.isDelayActive,
    );
  }
}

class DelayedRelayErrorNotifier extends Notifier<DelayedRelayErrorState> {
  static const Duration _delayDuration = Duration(seconds: 30);
  final _logger = Logger('DelayedRelayErrorNotifier');

  Timer? _delayTimer;
  bool _lastConnectionStatus = true;

  @override
  DelayedRelayErrorState build() {
    ref.listen<AsyncValue<bool>>(allRelayTypesConnectionProvider, (previous, next) {
      next.when(
        data: (isConnected) => _handleConnectionStatusChange(isConnected),
        loading: () {
          _logger.info('Relay connection status is loading');
        },
        error: (error, stackTrace) {
          _logger.warning('Error in relay connection status: $error');
          _handleConnectionStatusChange(false);
        },
      );
    });

    return const DelayedRelayErrorState();
  }

  void _handleConnectionStatusChange(bool isConnected) {
    _logger.info('Relay connection status changed: $isConnected (was: $_lastConnectionStatus)');

    if (isConnected && !_lastConnectionStatus) {
      _logger.info('Connection restored - hiding banner immediately');
      _cancelDelayTimer();
      state = state.copyWith(shouldShowBanner: false, isDelayActive: false);
    } else if (!isConnected && _lastConnectionStatus) {
      _logger.info('Connection lost - starting 30-second delay timer');
      _startDelayTimer();
    }

    _lastConnectionStatus = isConnected;
  }

  void _startDelayTimer() {
    _cancelDelayTimer();
    state = state.copyWith(isDelayActive: true, shouldShowBanner: false);
    _delayTimer = Timer(_delayDuration, () {
      _logger.info('30-second delay completed - checking if banner should still be shown');
      final currentConnectionAsync = ref.read(allRelayTypesConnectionProvider);
      currentConnectionAsync.when(
        data: (isConnected) {
          if (!isConnected) {
            _logger.info('Still disconnected after delay - showing banner');
            state = state.copyWith(shouldShowBanner: true, isDelayActive: false);
          } else {
            _logger.info('Connection restored during delay - not showing banner');
            state = state.copyWith(shouldShowBanner: false, isDelayActive: false);
          }
        },
        loading: () {
          state = state.copyWith(shouldShowBanner: false, isDelayActive: false);
        },
        error: (error, stackTrace) {
          _logger.warning('Error checking connection status after delay: $error');
          state = state.copyWith(shouldShowBanner: true, isDelayActive: false);
        },
      );
    });
  }

  void _cancelDelayTimer() {
    if (_delayTimer != null) {
      _logger.info('Cancelling delay timer');
      _delayTimer!.cancel();
      _delayTimer = null;
    }
  }

  void dispose() {
    _cancelDelayTimer();
  }
}

final delayedRelayErrorProvider =
    NotifierProvider<DelayedRelayErrorNotifier, DelayedRelayErrorState>(
      DelayedRelayErrorNotifier.new,
    );
