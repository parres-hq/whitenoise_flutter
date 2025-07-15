import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';

/// A mixin that provides safe toast methods that won't cause deactivated widget errors
mixin SafeToastMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Safely shows an error toast only if the widget is still mounted
  void safeShowErrorToast(String message) {
    if (!mounted) return;

    try {
      ref.showErrorToast(message);
    } catch (e) {
      // If the ref access fails, fall back to a different method
      debugPrint('Failed to show error toast: $message (Error: $e)');
    }
  }

  /// Safely shows a success toast only if the widget is still mounted
  void safeShowSuccessToast(String message) {
    if (!mounted) return;

    try {
      ref.showSuccessToast(message);
    } catch (e) {
      // If the ref access fails, fall back to a different method
      debugPrint('Failed to show success toast: $message (Error: $e)');
    }
  }

  /// Safely shows a warning toast only if the widget is still mounted
  void safeShowWarningToast(String message) {
    if (!mounted) return;

    try {
      ref.showWarningToast(message);
    } catch (e) {
      // If the ref access fails, fall back to a different method
      debugPrint('Failed to show warning toast: $message (Error: $e)');
    }
  }
}
