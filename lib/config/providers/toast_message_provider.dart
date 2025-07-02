import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:whitenoise/config/states/toast_state.dart';

class ToastMessageNotifier extends Notifier<ToastState> {
  static const _uuid = Uuid();
  static final _logger = Logger('ToastMessage');

  @override
  ToastState build() {
    return const ToastState();
  }

  /// Converts technical error messages to human-friendly ones
  String _sanitizeMessage(String message, ToastType type) {
    final lowerMessage = message.toLowerCase();

    // Log the original technical message for debugging
    switch (type) {
      case ToastType.error:
        _logger.severe('Error toast: $message');
        break;
      case ToastType.warning:
        _logger.warning('Warning toast: $message');
        break;
      case ToastType.info:
        _logger.info('Info toast: $message');
        break;
      case ToastType.success:
        _logger.info('Success toast: $message');
        break;
    }

    // Return human-friendly messages for common technical errors
    if (type == ToastType.error) {
      // Network/Connection errors
      if (lowerMessage.contains('connection') ||
          lowerMessage.contains('network') ||
          lowerMessage.contains('timeout') ||
          lowerMessage.contains('unreachable')) {
        return 'Connection failed. Please check your internet and try again.';
      }

      // Authentication errors
      if (lowerMessage.contains('unauthorized') ||
          lowerMessage.contains('forbidden') ||
          lowerMessage.contains('authentication') ||
          lowerMessage.contains('invalid key') ||
          lowerMessage.contains('login')) {
        return 'Authentication failed. Please check your credentials.';
      }

      // Parsing/Format errors
      if (lowerMessage.contains('parse') ||
          lowerMessage.contains('format') ||
          lowerMessage.contains('invalid') ||
          lowerMessage.contains('malformed')) {
        return 'Invalid format. Please check your input and try again.';
      }

      // Database/Storage errors
      if (lowerMessage.contains('database') ||
          lowerMessage.contains('storage') ||
          lowerMessage.contains('failed to save') ||
          lowerMessage.contains('failed to load')) {
        return 'Failed to save data. Please try again.';
      }

      // Generic server errors
      if (lowerMessage.contains('server') ||
          lowerMessage.contains('internal error') ||
          lowerMessage.contains('500') ||
          lowerMessage.contains('503')) {
        return 'Server error. Please try again later.';
      }

      // Exception stack traces or technical details
      if (message.contains('Exception:') ||
          message.contains('Error:') ||
          message.contains('at ') ||
          message.length > 100) {
        return 'Something went wrong. Please try again.';
      }
    }

    // If message is already user-friendly (short and descriptive), keep it as is
    if (message.length <= 80 && !message.contains(':') && !lowerMessage.contains('exception')) {
      return message;
    }

    // Default fallback for unhandled technical messages
    switch (type) {
      case ToastType.error:
        return 'An error occurred. Please try again.';
      case ToastType.warning:
        return 'Warning: Please check your input.';
      case ToastType.info:
        return 'Information updated.';
      case ToastType.success:
        return 'Operation completed successfully.';
    }
  }

  void showToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Sanitize the message to be user-friendly and log the original
    final sanitizedMessage = _sanitizeMessage(message, type);

    final toast = ToastMessage(
      id: _uuid.v4(),
      message: sanitizedMessage,
      type: type,
      durationMs: durationMs ?? state.config.defaultDurationMs,
      autoDismiss: autoDismiss ?? state.config.autoDismiss,
      showBelowAppBar: showBelowAppBar ?? state.config.defaultShowBelowAppBar,
    );

    final updatedMessages =
        state.config.stackMode == ToastStackMode.stack ? [...state.messages, toast] : [toast];

    state = state.copyWith(messages: updatedMessages);

    if (toast.autoDismiss) {
      _scheduleAutoDismiss(toast.id, toast.durationMs);
    }
  }

  void showSuccess(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    showToast(
      message: message,
      type: ToastType.success,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  void showError(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    showToast(
      message: message,
      type: ToastType.error,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  void showWarning(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    showToast(
      message: message,
      type: ToastType.warning,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  void showInfo(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    showToast(
      message: message,
      type: ToastType.info,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows a raw message without sanitization (for development/debugging)
  /// Use this only when you're certain the message is already user-friendly
  void showRawToast({
    required String message,
    required ToastType type,
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    // Log the raw message but don't sanitize it
    _logger.info('Raw ${type.name} toast: $message');

    final toast = ToastMessage(
      id: _uuid.v4(),
      message: message,
      type: type,
      durationMs: durationMs ?? state.config.defaultDurationMs,
      autoDismiss: autoDismiss ?? state.config.autoDismiss,
      showBelowAppBar: showBelowAppBar ?? state.config.defaultShowBelowAppBar,
    );

    final updatedMessages =
        state.config.stackMode == ToastStackMode.stack ? [...state.messages, toast] : [toast];

    state = state.copyWith(messages: updatedMessages);

    if (toast.autoDismiss) {
      _scheduleAutoDismiss(toast.id, toast.durationMs);
    }
  }

  void dismissToast(String id) {
    final updatedMessages = state.messages.where((msg) => msg.id != id).toList();
    state = state.copyWith(messages: updatedMessages);
  }

  void dismissAll() {
    state = state.copyWith(messages: []);
  }

  void updateConfig(ToastConfig config) {
    state = state.copyWith(config: config);
  }

  void setStackMode(ToastStackMode mode) {
    state = state.copyWith(
      config: state.config.copyWith(stackMode: mode),
    );
  }

  void setDefaultShowBelowAppBar(bool showBelowAppBar) {
    state = state.copyWith(
      config: state.config.copyWith(defaultShowBelowAppBar: showBelowAppBar),
    );
  }

  void _scheduleAutoDismiss(String id, int durationMs) {
    Future.delayed(Duration(milliseconds: durationMs), () {
      if (state.messages.any((msg) => msg.id == id)) {
        dismissToast(id);
      }
    });
  }
}

final toastMessageProvider = NotifierProvider<ToastMessageNotifier, ToastState>(
  () => ToastMessageNotifier(),
);
