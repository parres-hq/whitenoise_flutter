import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

/// Mixin for handling errors in Riverpod notifiers
mixin ErrorHandlerMixin<T> on Notifier<T> {
  Future<void> safeExecute({
    required Future<void> Function() operation,
    required T Function(T state, {String? error, bool isLoading}) updateState,
    Logger? logger,
    String? operationName,
  }) async {
    final log = logger ?? Logger(runtimeType.toString());

    // Set loading to true
    state = updateState(state, isLoading: true);

    try {
      await operation();
      // Set loading to false on success
      state = updateState(state, isLoading: false);
    } catch (e, st) {
      String errorMessage;

      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
          if (errorMessage.contains('InvalidSecretKey')) {
            errorMessage = 'Invalid nsec or private key';
          }
        } catch (conversionError) {
          errorMessage = 'Invalid nsec or private key';
        }
        log.warning('${operationName ?? 'Operation'} failed: $errorMessage');
      } else {
        errorMessage = e.toString();
        log.severe('${operationName ?? 'Operation'} unexpected error', e, st);
      }

      state = updateState(state, error: errorMessage, isLoading: false);
    }
  }
}
