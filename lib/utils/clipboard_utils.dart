import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';

/// Utility class for clipboard operations with toast notifications
class ClipboardUtils {
  // Private constructor to prevent instantiation
  ClipboardUtils._();

  /// Copies text to clipboard and shows a success toast
  ///
  /// [ref] - WidgetRef for accessing providers
  /// [textToCopy] - The text to copy to clipboard
  /// [message] - Optional custom message to show (defaults to "Copied to clipboard")
  static void copyWithToast({
    required WidgetRef ref,
    required String textToCopy,
    String? message,
  }) {
    Clipboard.setData(ClipboardData(text: textToCopy));
    ref
        .read(toastMessageProvider.notifier)
        .showRawToast(
          message: message ?? 'Copied to clipboard',
          type: ToastType.success,
          autoDismiss: true,
        );
  }
}
