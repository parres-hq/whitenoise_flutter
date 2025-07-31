import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';

/// Utility class for clipboard operations with toast notifications
class ClipboardUtils {
  // Private constructor to prevent instantiation
  ClipboardUtils._();

  /// Copies text to clipboard and shows a success toast
  ///
  /// [ref] - WidgetRef for accessing providers
  /// [textToCopy] - The text to copy to clipboard
  /// [successMessage] - Optional custom message to show (defaults to "Copied to clipboard")
  /// [noTextMessage] - Optional custom error message to show when there is no text to copy (defaults to "Nothing to copy")
  /// [errorMessage] - Optional custom error message to show when clipboard operation fails (defaults to "Failed to copy to clipboard")
  static Future<void> copyWithToast({
    required WidgetRef ref,
    String? textToCopy,
    String? successMessage,
    String? noTextMessage,
    String? errorMessage,
  }) async {
    if (textToCopy == null || textToCopy.isEmpty) {
      ref.showErrorToast(noTextMessage ?? 'Nothing to copy');
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: textToCopy));
      ref.showSuccessToast(
        successMessage ?? 'Copied to clipboard',
        autoDismiss: true,
      );
    } catch (e) {
      ref.showErrorToast(
        errorMessage ?? 'Failed to copy to clipboard',
        autoDismiss: true,
      );
    }
  }
}
