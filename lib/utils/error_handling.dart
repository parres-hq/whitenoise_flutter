import 'package:logging/logging.dart';
import 'package:whitenoise/services/localization_service.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;

/// Utility class for handling ApiError conversion and providing user-friendly error messages
class ErrorHandlingUtils {
  static final _logger = Logger('ErrorHandlingUtils');

  static String _tr(
    String key,
    String fallback, {
    Map<String, dynamic>? params,
  }) {
    final translated = LocalizationService.translate(key, params: params);
    return translated == key ? fallback : translated;
  }

  /// Attempts to convert any error (including ApiErrorImpl exceptions) to a user-friendly string
  ///
  /// This method handles:
  /// - Direct ApiError objects
  /// - ApiErrorImpl wrapped in generic exceptions (flutter_rust_bridge issue)
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
      if (error is ApiError) {
        return await _handleApiError(
          error: error,
          fallbackMessage: fallbackMessage,
          logPrefix: logPrefix,
        );
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

  /// Handles exceptions that may wrap ApiErrorImpl
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

      if (exceptionString.contains('ApiErrorImpl')) {
        _logger.severe(
          '${logPrefix}Detected wrapped ApiErrorImpl - attempting to extract error details',
        );

        // Try to extract actual error information from the exception string first
        // The actual error might be embedded in the exception message
        String baseErrorMessage = _tr(
          'errors.internalError',
          'Internal error occurred',
        );

        // Attempt to extract meaningful error text from the exception
        // This is a best-effort approach since ApiErrorImpl is opaque
        if (exceptionString.length > 'Exception: Instance of \'ApiErrorImpl\''.length) {
          // If there's more text beyond the generic message, try to use it
          final cleanedException =
              exceptionString.replaceFirst('Exception: Instance of \'ApiErrorImpl\'', '').trim();
          if (cleanedException.isNotEmpty) {
            baseErrorMessage = cleanedException;
          }
        }

        // Check for specific error patterns and augment the base error message with helpful context
        if (_containsKeyPackageError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getKeyPackageHelpText());
        } else if (_containsInvalidPubkeyError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getInvalidPubkeyHelpText());
        } else if (_containsAccountLookupError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getAccountLookupHelpText());
        } else if (_containsRelayConfigurationError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getRelayConfigurationHelpText());
        } else if (_containsNetworkError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getNetworkHelpText());
        } else if (_containsPermissionError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getPermissionHelpText());
        } else if (_containsRelayError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getRelayConnectivityHelpText());
        } else if (_containsDatabaseError(exceptionString, stackTraceString)) {
          return _appendHelpText(baseErrorMessage, _getDatabaseHelpText());
        } else {
          // Log full details for debugging but still try to show what we can to the user
          _logger.severe('${logPrefix}ApiErrorImpl details: $exceptionString');
          _logger.severe('${logPrefix}Raw error object: $error');
          if (stackTrace != null) {
            _logger.severe('${logPrefix}Stack trace: $stackTrace');
          }

          // Show the base error message with generic help text
          return '$baseErrorMessage\n\n${_getGenericHelpText()}';
        }
      } else {
        // Non-ApiError exception
        _logger.severe('${logPrefix}Non-ApiError exception type: ${error.runtimeType}');
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

  static Future<String> _handleApiError({
    required ApiError error,
    required String fallbackMessage,
    required String logPrefix,
  }) async {
    try {
      _logger.severe('${logPrefix}Handling ApiError variant: ${error.runtimeType}');
      return await error.map<Future<String>>(
        whitenoise: (value) async {
          final rawErrorMessage = await value.messageText();
          return _parseSpecificErrorPatterns(rawErrorMessage);
        },
        invalidKey: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.invalidPublicKeySummary',
            'One or more public keys are invalid. Please double-check all participant and admin keys, then try again.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        nostrUrl: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.relayUrlSummary',
            'There is a problem with a relay URL in your setup. Check your relay URLs in Settings and try again.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        nostrTag: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.nostrTagSummary',
            'A Nostr tag error occurred.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        nostrEvent: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.nostrEventSummary',
            'A Nostr event error occurred.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        nostrParse: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.nostrParseSummary',
            'We could not parse some Nostr data required for this action. Please verify your relays and data, then try again.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        nostrHex: (value) async {
          final message = await value.messageText();
          final summary = _tr(
            'errors.nostrHexSummary',
            'One of the hex values (likely a public key) is malformed. Please double-check the value and try again.',
          );
          return _formatSummaryWithDetails(
            summary,
            message,
          );
        },
        other: (value) async {
          final message = await value.messageText();
          return _parseSpecificErrorPatterns(message);
        },
      );
    } catch (conversionError) {
      _logger.severe(
        '${logPrefix}Failed to convert ApiError (${error.runtimeType}) to string: $conversionError',
      );
      return fallbackMessage;
    }
  }

  static String _appendHelpText(String message, String helpText) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return helpText;
    }
    return '$trimmedMessage\n\n$helpText';
  }

  static String _formatSummaryWithDetails(String summary, String details) {
    final trimmedDetails = details.trim();
    if (trimmedDetails.isEmpty) {
      return summary;
    }
    return '$summary\n\n$trimmedDetails';
  }

  /// Parses specific error patterns from converted ApiError strings
  static String _parseSpecificErrorPatterns(String rawErrorMessage) {
    try {
      if (_containsKeyPackageMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getKeyPackageHelpText());
      } else if (_containsInvalidPubkeyMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getInvalidPubkeyHelpText());
      } else if (_containsAccountLookupMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getAccountLookupHelpText());
      } else if (_containsRelayConfigurationMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getRelayConfigurationHelpText());
      } else if (_containsNetworkMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getNetworkHelpText());
      } else if (_containsPermissionMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getPermissionHelpText());
      } else if (_containsRelayMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getRelayConnectivityHelpText());
      } else if (_containsDatabaseMessage(rawErrorMessage)) {
        return _appendHelpText(rawErrorMessage, _getDatabaseHelpText());
      }
      return rawErrorMessage;
    } catch (_) {
      // If anything goes wrong in pattern parsing, just return the raw message
      return rawErrorMessage;
    }
  }

  // Helper methods for error pattern detection
  static bool _containsKeyPackageError(String exceptionString, String stackTraceString) {
    return _containsKeyPackageMessage(exceptionString) ||
        _containsKeyPackageMessage(stackTraceString);
  }

  static bool _containsInvalidPubkeyError(String exceptionString, String stackTraceString) {
    return _containsInvalidPubkeyMessage(exceptionString) ||
        _containsInvalidPubkeyMessage(stackTraceString);
  }

  static bool _containsAccountLookupError(String exceptionString, String stackTraceString) {
    return _containsAccountLookupMessage(exceptionString) ||
        _containsAccountLookupMessage(stackTraceString);
  }

  static bool _containsRelayConfigurationError(
    String exceptionString,
    String stackTraceString,
  ) {
    return _containsRelayConfigurationMessage(exceptionString) ||
        _containsRelayConfigurationMessage(stackTraceString);
  }

  static bool _containsNetworkError(String exceptionString, String stackTraceString) {
    return _containsNetworkMessage(exceptionString) || _containsNetworkMessage(stackTraceString);
  }

  static bool _containsPermissionError(String exceptionString, String stackTraceString) {
    return _containsPermissionMessage(exceptionString) ||
        _containsPermissionMessage(stackTraceString);
  }

  static bool _containsRelayError(String exceptionString, String stackTraceString) {
    return _containsRelayMessage(exceptionString) || _containsRelayMessage(stackTraceString);
  }

  static bool _containsDatabaseError(String exceptionString, String stackTraceString) {
    return _containsDatabaseMessage(exceptionString) || _containsDatabaseMessage(stackTraceString);
  }

  static bool _containsKeyPackageMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    final hasKeyPackage = normalized.contains('keypackage') || normalized.contains('key package');
    if (!hasKeyPackage) {
      return false;
    }
    const qualifiers = [
      'does not exist',
      'not found',
      'missing',
      'no key package',
      'no key packages',
      'without key package',
    ];
    return _containsAnyNormalized(normalized, qualifiers);
  }

  static bool _containsInvalidPubkeyMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'invalid public key',
        'invalid pubkey',
        'malformed public key',
        'malformed pubkey',
        'failed to parse public key',
        'failed to parse pubkey',
        'fromhexerror',
        'nostrhex',
        'wrong length for public key',
        'incorrect length for public key',
        'hex decode error',
      ],
    );
  }

  static bool _containsAccountLookupMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'find_account_by_pubkey',
        'account not found',
        'no account for pubkey',
        'missing account',
        'account lookup failed',
        'account lookup error',
      ],
    );
  }

  static bool _containsRelayConfigurationMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'nip65',
        'relaytype::nip65',
        'no relays configured',
        'no relays found',
        'missing relay',
        'relay list is empty',
        'invalid relay url',
        'bad relay url',
        'relay url is invalid',
        'failed to parse relay',
      ],
    );
  }

  static bool _containsNetworkMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'network',
        'connection',
      ],
    );
  }

  static bool _containsPermissionMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'permission',
        'unauthorized',
      ],
    );
  }

  static bool _containsRelayMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return normalized.contains('relay');
  }

  static bool _containsDatabaseMessage(String source) {
    if (source.isEmpty) {
      return false;
    }
    final normalized = _normalize(source);
    return _containsAnyNormalized(
      normalized,
      [
        'database',
        'storage',
      ],
    );
  }

  static bool _containsAnyNormalized(String normalizedSource, List<String> needles) {
    for (final needle in needles) {
      if (needle.isEmpty) {
        continue;
      }
      if (normalizedSource.contains(needle)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String source) {
    return source.toLowerCase();
  }

  // User-friendly error message templates

  /// Help text for KeyPackage-related errors (without the main error message)
  static String _getKeyPackageHelpText() {
    return _tr(
      'errors.keyPackageHelp',
      'Ask affected members to open WhiteNoise so their encryption keys refresh.',
    );
  }

  static String _getInvalidPubkeyHelpText() {
    return _tr(
      'errors.invalidPubkeyHelp',
      'Group creation failed because one of the public keys is invalid. '
          'Please double-check all member and admin keys, then try again.',
    );
  }

  static String _getAccountLookupHelpText() {
    return _tr(
      'errors.accountLookupHelp',
      'We could not find an account for your active key. '
          'Please log out and back in or create a new identity, then try again.',
    );
  }

  static String _getRelayConfigurationHelpText() {
    return _tr(
      'errors.relayConfigurationHelp',
      'Your account does not have any valid Nostr relays configured (NIP-65). '
          'Please add at least one relay in Settings and try again.',
    );
  }

  static String _getNetworkHelpText() {
    return _tr(
      'errors.networkHelp',
      'This appears to be a network connectivity issue. '
          'Please check your internet connection and try again.',
    );
  }

  static String _getPermissionHelpText() {
    return _tr(
      'errors.permissionHelp',
      'This appears to be a permission issue. '
          'You may not have permission to perform this operation.',
    );
  }

  static String _getRelayConnectivityHelpText() {
    return _tr(
      'errors.relayConnectivityHelp',
      'Unable to connect to Nostr relays. Please check your network connection.',
    );
  }

  static String _getDatabaseHelpText() {
    return _tr(
      'errors.databaseHelp',
      'There was an issue with local data storage. Please restart the app.',
    );
  }

  /// Generic help text for unknown ApiError types
  static String _getGenericHelpText() {
    return _tr(
      'errors.genericHelp',
      'Check your data, connection, and permissions, then try again.',
    );
  }

  /// Specific error messages for different operations

  /// Error message for group creation failures
  static String getGroupCreationFallbackMessage() {
    return _tr(
      'errors.groupCreationFallback',
      'Group creation failed; verify member keys, network, permissions, and try again.',
    );
  }

  /// Error message for message sending failures
  static String getMessageSendFallbackMessage() {
    return _tr(
      'errors.messageSendFallback',
      'Message failed to send; check your connection and try again.',
    );
  }
}
