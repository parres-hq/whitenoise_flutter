import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';

extension ToastExtension on WidgetRef {
  /// Shows a success toast with message sanitization
  void showSuccessToast(
    String message, {
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    read(toastMessageProvider.notifier).showSuccess(
      message,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows an error toast with message sanitization and logging
  void showErrorToast(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    read(toastMessageProvider.notifier).showError(
      message,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows a warning toast with message sanitization
  void showWarningToast(
    String message, {
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    read(toastMessageProvider.notifier).showWarning(
      message,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows an info toast with message sanitization
  void showInfoToast(String message, {int? durationMs, bool? autoDismiss, bool? showBelowAppBar}) {
    read(toastMessageProvider.notifier).showInfo(
      message,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows a raw toast without sanitization (for development/debugging)
  /// Use this only when you're certain the message is already user-friendly
  void showRawSuccessToast(
    String message, {
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    read(toastMessageProvider.notifier).showRawToast(
      message: message,
      type: ToastType.success,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Shows a raw error toast without sanitization (for development/debugging)
  void showRawErrorToast(
    String message, {
    int? durationMs,
    bool? autoDismiss,
    bool? showBelowAppBar,
  }) {
    read(toastMessageProvider.notifier).showRawToast(
      message: message,
      type: ToastType.error,
      durationMs: durationMs,
      autoDismiss: autoDismiss,
      showBelowAppBar: showBelowAppBar,
    );
  }

  /// Convenience method for handling exceptions with proper logging
  void showExceptionToast(Object exception, {String? context}) {
    final message = context != null ? '$context: $exception' : exception.toString();
    showErrorToast(message);
  }

  void dismissAllToasts() {
    read(toastMessageProvider.notifier).dismissAll();
  }

  void setToastStackMode(ToastStackMode mode) {
    read(toastMessageProvider.notifier).setStackMode(mode);
  }
}
