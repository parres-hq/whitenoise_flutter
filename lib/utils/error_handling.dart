import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

/// Utility class for handling WhitenoiseError conversion and providing user-friendly error messages
class ErrorHandlingUtils {
  static final _logger = Logger('ErrorHandlingUtils');

  /// Attempts to convert any error (including WhitenoiseErrorImpl exceptions) to a user-friendly string
  ///
  /// This method handles:
  /// - Direct WhitenoiseError objects
  /// - WhitenoiseErrorImpl wrapped in generic exceptions (flutter_rust_bridge issue)
  /// - Generic exceptions with custom error messages
  ///
  /// [error] - The caught exception or error
  /// [stackTrace] - The stack trace for additional context (optional)
  /// [fallbackMessage] - Default message if conversion fails
  /// [context] - Context string for logging (e.g., "createGroup", "loadMessages")
  static Future<String> convertErrorToUserFriendlyMessage({
    required dynamic error,
    StackTrace? stackTrace,
    required String fallbackMessage,
    String context = '',
  }) async {
    final logPrefix = context.isNotEmpty ? '$context: ' : '';

    try {
      if (error is WhitenoiseError) {
        try {
          _logger.severe('${logPrefix}Converting WhitenoiseError to string...');
          final rawErrorMessage = await whitenoiseErrorToString(error: error);
          _logger.severe('${logPrefix}WhitenoiseError converted to: $rawErrorMessage');
          return _parseSpecificErrorPatterns(rawErrorMessage);
        } catch (conversionError) {
          _logger.severe(
            '${logPrefix}Failed to convert WhitenoiseError to string: $conversionError',
          );
          return fallbackMessage;
        }
      } else if (error is Exception) {
        return _handleWrappedException(
          error: error,
          stackTrace: stackTrace,
          fallbackMessage: fallbackMessage,
          logPrefix: logPrefix,
        );
      } else {
        _logger.severe('${logPrefix}Unknown error type: ${error.runtimeType}');
        _logger.severe('${logPrefix}Error details: $error');
        return '$fallbackMessage: $error';
      }
    } catch (unexpectedError) {
      _logger.severe('${logPrefix}Unexpected error in error handling: $unexpectedError');
      return fallbackMessage;
    }
  }

  /// Handles exceptions that may wrap WhitenoiseErrorImpl
  static String _handleWrappedException({
    required Exception error,
    StackTrace? stackTrace,
    required String fallbackMessage,
    required String logPrefix,
  }) {
    try {
      final exceptionString = error.toString();
      final stackTraceString = stackTrace?.toString() ?? '';

      _logger.severe('${logPrefix}Exception string: $exceptionString');
      _logger.severe('${logPrefix}Exception type: ${error.runtimeType}');

      if (exceptionString.contains('WhitenoiseErrorImpl')) {
        _logger.severe(
          '${logPrefix}Detected wrapped WhitenoiseErrorImpl - attempting to extract error details',
        );

        // Try to extract actual error information from the exception string first
        // The actual error might be embedded in the exception message
        String baseErrorMessage = 'Internal error occurred';

        // Attempt to extract meaningful error text from the exception
        // This is a best-effort approach since WhitenoiseErrorImpl is opaque
        if (exceptionString.length > 'Exception: Instance of \'WhitenoiseErrorImpl\''.length) {
          // If there's more text beyond the generic message, try to use it
          final cleanedException =
              exceptionString
                  .replaceFirst('Exception: Instance of \'WhitenoiseErrorImpl\'', '')
                  .trim();
          if (cleanedException.isNotEmpty) {
            baseErrorMessage = cleanedException;
          }
        }

        // Check for specific error patterns and augment the base error message with helpful context
        if (_containsKeyPackageError(exceptionString, stackTraceString)) {
          return '$baseErrorMessage\n\n${_getKeyPackageHelpText()}';
        } else if (_containsNetworkError(exceptionString, stackTraceString)) {
          return '$baseErrorMessage\n\nThis appears to be a network connectivity issue. Please check your internet connection and try again.';
        } else if (_containsPermissionError(exceptionString, stackTraceString)) {
          return '$baseErrorMessage\n\nThis appears to be a permission issue. You may not have permission to perform this operation.';
        } else if (_containsRelayError(exceptionString, stackTraceString)) {
          return '$baseErrorMessage\n\nUnable to connect to Nostr relays. Please check your network connection.';
        } else if (_containsDatabaseError(exceptionString, stackTraceString)) {
          return '$baseErrorMessage\n\nThere was an issue with local data storage. Please restart the app.';
        } else {
          // Log full details for debugging but still try to show what we can to the user
          _logger.severe('${logPrefix}WhitenoiseErrorImpl details: $exceptionString');
          _logger.severe('${logPrefix}Raw error object: $error');
          if (stackTrace != null) {
            _logger.severe('${logPrefix}Stack trace: $stackTrace');
          }

          // Show the base error message with generic help text
          return '$baseErrorMessage\n\n${_getGenericHelpText()}';
        }
      } else {
        // Non-WhitenoiseError exception
        _logger.severe('${logPrefix}Non-WhitenoiseError exception type: ${error.runtimeType}');
        _logger.severe('${logPrefix}Error details: $error');
        if (stackTrace != null) {
          _logger.severe('${logPrefix}Stack trace: $stackTrace');
        }
        return '$fallbackMessage: ${error.toString()}';
      }
    } catch (handlingError) {
      // If anything goes wrong in exception handling, just return the fallback
      _logger.severe('${logPrefix}Error in exception handling: $handlingError');
      return fallbackMessage;
    }
  }

  /// Parses specific error patterns from converted WhitenoiseError strings
  static String _parseSpecificErrorPatterns(String rawErrorMessage) {
    try {
      if (rawErrorMessage.contains('KeyPackage') && rawErrorMessage.contains('Does not exist')) {
        return '$rawErrorMessage\n\n${_getKeyPackageHelpText()}';
      } else if (rawErrorMessage.contains('Network') || rawErrorMessage.contains('Connection')) {
        return '$rawErrorMessage\n\nThis appears to be a network connectivity issue. Please check your internet connection and try again.';
      } else if (rawErrorMessage.contains('Permission') ||
          rawErrorMessage.contains('Unauthorized')) {
        return '$rawErrorMessage\n\nThis appears to be a permission issue. You may not have permission to perform this operation.';
      } else if (rawErrorMessage.contains('Relay')) {
        return '$rawErrorMessage\n\nUnable to connect to Nostr relays. Please check your network connection.';
      } else if (rawErrorMessage.contains('Database') || rawErrorMessage.contains('Storage')) {
        return '$rawErrorMessage\n\nThere was an issue with local data storage. Please restart the app.';
      } else {
        // Return the raw error message as-is for unknown error types
        return rawErrorMessage;
      }
    } catch (_) {
      // If anything goes wrong in pattern parsing, just return the raw message
      return rawErrorMessage;
    }
  }

  // Helper methods for error pattern detection
  static bool _containsKeyPackageError(String exceptionString, String stackTraceString) {
    try {
      return exceptionString.contains('KeyPackage') || stackTraceString.contains('KeyPackage');
    } catch (_) {
      return false;
    }
  }

  static bool _containsNetworkError(String exceptionString, String stackTraceString) {
    try {
      return exceptionString.contains('Network') ||
          exceptionString.contains('Connection') ||
          stackTraceString.contains('Network') ||
          stackTraceString.contains('Connection');
    } catch (_) {
      return false;
    }
  }

  static bool _containsPermissionError(String exceptionString, String stackTraceString) {
    try {
      return exceptionString.contains('Permission') ||
          exceptionString.contains('Unauthorized') ||
          stackTraceString.contains('Permission') ||
          stackTraceString.contains('Unauthorized');
    } catch (_) {
      return false;
    }
  }

  static bool _containsRelayError(String exceptionString, String stackTraceString) {
    try {
      return exceptionString.contains('Relay') || stackTraceString.contains('Relay');
    } catch (_) {
      return false;
    }
  }

  static bool _containsDatabaseError(String exceptionString, String stackTraceString) {
    try {
      return exceptionString.contains('Database') ||
          exceptionString.contains('Storage') ||
          stackTraceString.contains('Database') ||
          stackTraceString.contains('Storage');
    } catch (_) {
      return false;
    }
  }

  // User-friendly error message templates

  /// Help text for KeyPackage-related errors (without the main error message)
  static String _getKeyPackageHelpText() {
    return 'This typically means:\n'
        '• A user has not used the app recently\n'
        '• Their encryption keys have expired\n'
        '• They need to open the app to refresh their keys\n\n'
        'Please ask the affected user(s) to open WhiteNoise and try again.';
  }

  /// Generic help text for unknown WhitenoiseError types
  static String _getGenericHelpText() {
    return 'This could be due to:\n'
        '• Invalid user data or public keys\n'
        '• Network connectivity issues\n'
        '• Insufficient permissions\n'
        '• Backend service unavailable\n\n'
        'Please check your connection and try again.';
  }

  /// Specific error messages for different operations

  /// Error message for group creation failures
  static String getGroupCreationFallbackMessage() {
    return 'Group creation failed. This could be due to:\n'
        '• Invalid member public keys\n'
        '• Network connectivity issues\n'
        '• Insufficient permissions\n'
        '• Backend service unavailable\n\n'
        'Please check that all member public keys are valid and try again.';
  }

  /// Error message for message sending failures
  static String getMessageSendFallbackMessage() {
    return 'Failed to send message. This could be due to:\n'
        '• Network connectivity issues\n'
        '• Group synchronization problems\n'
        '• Encryption key issues\n\n'
        'Please check your connection and try again.';
  }

  /// Error message for contact loading failures
  static String getContactLoadFallbackMessage() {
    return 'Failed to load contacts. This could be due to:\n'
        '• Network connectivity issues\n'
        '• Relay connection problems\n'
        '• Local database issues\n\n'
        'Please check your connection and try again.';
  }
}
