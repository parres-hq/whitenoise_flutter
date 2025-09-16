import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';

/// Utility class for clipboard operations with toast notifications
class ClipboardUtils {
  // Private constructor to prevent instantiation
  ClipboardUtils._();

  // Android-specific channel for sensitive clipboard copy
  static const MethodChannel _sensitiveChannel = MethodChannel('clipboard_sensitive');

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

  /// Copies text via platform-specific sensitive path (Android) with a success toast.
  /// Falls back to regular copy on non-Android platforms.
  ///
  /// [ref] - WidgetRef for accessing providers
  /// [textToCopy] - The text to copy to clipboard
  /// [successMessage] - Optional custom message to show (defaults to "Copied to clipboard")
  /// [noTextMessage] - Optional custom error message to show when there is no text to copy (defaults to "Nothing to copy")
  /// [errorMessage] - Optional custom error message to show when clipboard operation fails (defaults to "Failed to copy to clipboard")
  static Future<void> copySensitiveWithToast({
    required WidgetRef ref,
    required String? textToCopy,
    String? successMessage,
    String? noTextMessage,
    String? errorMessage,
  }) async {
    if (textToCopy == null || textToCopy.isEmpty) {
      ref.showErrorToast(noTextMessage ?? 'Nothing to copy');
      return;
    }

    try {
      // Try Android sensitive channel first; if it throws, fall back to Clipboard.setData
      await _sensitiveChannel.invokeMethod('setSensitive', {'text': textToCopy});
      ref.showSuccessToast(
        successMessage ?? 'Copied to clipboard',
        autoDismiss: true,
      );
    } catch (_) {
      // Fallback for non-Android or if channel not available
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

  /// Reads text from clipboard and shows appropriate toast messages
  ///
  /// [ref] - WidgetRef for accessing providers
  /// [onPaste] - Callback function that receives the pasted text
  /// [successMessage] - Optional custom message to show (defaults to "Pasted from clipboard")
  /// [noTextMessage] - Optional custom message to show when clipboard is empty (defaults to "Nothing to paste from clipboard")
  /// [errorMessage] - Optional custom error message to show when clipboard operation fails (defaults to "Clipboard unavailable")
  static Future<void> pasteWithToast({
    required WidgetRef ref,
    required Function(String) onPaste,
    String? successMessage,
    String? noTextMessage,
    String? errorMessage,
  }) async {
    final logger = Logger('ClipboardUtils');

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text ?? '';
      if (clipboardText.isNotEmpty) {
        onPaste(clipboardText);
        ref.showSuccessToast(
          successMessage ?? 'Pasted from clipboard',
          autoDismiss: true,
        );
      } else {
        ref.showInfoToast(
          noTextMessage ?? 'Nothing to paste from clipboard',
          autoDismiss: true,
        );
      }
    } on PlatformException catch (e) {
      logger.warning('Clipboard read failed: $e');
      ref.showErrorToast(
        errorMessage ?? 'Clipboard unavailable',
        autoDismiss: true,
      );
    }
  }
}
