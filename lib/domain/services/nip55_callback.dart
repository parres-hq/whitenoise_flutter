import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/nip55_service.dart';
import 'package:whitenoise/src/rust/api/nip55.dart' as nip55_api;
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

/// Initializes the NIP-55 callback and registers it with the Rust core
///
/// This sets up the bridge between Rust and the Android NIP-55 signer app
class Nip55CallbackInitializer {
  static final Logger _logger = Logger('Nip55CallbackInitializer');
  static bool _initialized = false;

  /// Initialize and register the NIP-55 callback with Rust
  static Future<void> initialize() async {
    if (_initialized) {
      _logger.info('NIP-55 callback already initialized');
      return;
    }

    try {
      _logger.info('Initializing NIP-55 callback');

      // Register the callback with Rust
      // The actual callback handling is done via the FlutterNip55Callback implementation
      // which calls back to Dart through the method channel
      await nip55_api.setNip55FlutterCallback(
        callback: _handleNip55MethodCall,
      );

      _initialized = true;
      _logger.info('NIP-55 callback initialized successfully');
    } catch (e, st) {
      _logger.severe('Failed to initialize NIP-55 callback', e, st);
      rethrow;
    }
  }

  /// Handle NIP-55 method calls from Rust
  ///
  /// This function is called by the Rust core when it needs to delegate
  /// a signing operation to an external Android signer app.
  static Future<String> _handleNip55MethodCall(
    String method,
    String params,
  ) async {
    try {
      print('=== NIP-55 CALLBACK TRIGGERED ===');
      print('Method: $method');
      print('Raw params (length ${params.length}): $params');
      print('Params type: ${params.runtimeType}');

      // Log that we're about to call the NIP55 service
      print('About to call NIP55 service for method: $method');

      // Normalize params - Android expects a JSONObject, not JSONArray
      // However, Rust may send arrays for certain methods like sign_event: [event_json, current_user]
      String normalizedParams = params.trim();

      // Handle empty or null cases
      if (normalizedParams.isEmpty ||
          normalizedParams == 'null' ||
          normalizedParams == 'Null' ||
          normalizedParams == 'NULL') {
        normalizedParams = '{}';
      } else {
        // Try to parse and handle different formats
        try {
          final parsed = jsonDecode(normalizedParams);
          if (parsed is List) {
            // Handle array format - common for sign_event: [event_json_string, current_user_pubkey]
            if (method == 'sign_event' && parsed.length >= 1) {
              print('=== SIGN_EVENT ARRAY DETECTED ===');
              print('Array length: ${parsed.length}');
              print('First element type: ${parsed[0].runtimeType}');

              // Extract event JSON string (first element)
              final eventJsonString =
                  parsed[0] is String ? parsed[0] as String : jsonEncode(parsed[0]);

              // Extract current_user if provided (second element)
              final currentUser =
                  parsed.length >= 2 && parsed[1] is String ? parsed[1] as String : '';

              print('Event JSON string length: ${eventJsonString.length}');
              print('Current user: $currentUser');

              // Build proper Android params object
              final paramsMap = <String, dynamic>{
                'event': eventJsonString,
              };
              if (currentUser.isNotEmpty) {
                paramsMap['current_user'] = currentUser;
              }

              normalizedParams = jsonEncode(paramsMap);
              print(
                'Normalized sign_event params (first 200 chars): ${normalizedParams.length > 200 ? normalizedParams.substring(0, 200) : normalizedParams}',
              );
            } else {
              // For other methods, arrays are not expected - convert to empty object
              _logger.warning(
                'Params was an array (${parsed.length} items) for method $method, converting to empty object',
              );
              normalizedParams = '{}';
            }
          } else if (parsed is Map) {
            // Valid object, use as-is (re-encode to ensure proper formatting)
            normalizedParams = jsonEncode(parsed);
          } else if (parsed == null) {
            // Null value, use empty object
            normalizedParams = '{}';
          } else {
            // Other types (string, number, bool), wrap in object or use empty
            _logger.warning(
              'Params was non-object type (${parsed.runtimeType}), using empty object',
            );
            normalizedParams = '{}';
          }
        } catch (e) {
          // Invalid JSON or parse error, use empty object
          _logger.warning('Invalid JSON params "$normalizedParams", using empty object: $e');
          normalizedParams = '{}';
        }
      }

      print('Normalized params: $normalizedParams');
      _logger.info('Normalized params: $normalizedParams');

      // Call the Android NIP-55 service
      print('=== CALLING NIP55 SERVICE === method: $method, params: $normalizedParams');
      final resultJson = await Nip55Service.callNip55Method(
        method: method,
        params: normalizedParams,
      );

      print('=== NIP55 SERVICE RETURNED ===');
      print('Result length: ${resultJson.length}');
      print('Raw result: $resultJson');
      _logger.info('NIP-55 method call succeeded: $method');
      _logger.info('Raw result: $resultJson');

      // Parse the result and format according to method requirements
      try {
        final resultMap = jsonDecode(resultJson) as Map<String, dynamic>;

        // For sign_event, Rust expects a JSON response with a "result" field containing the signed event
        if (method == 'sign_event') {
          // Check if we have the full signed event JSON
          final signedEventJson = resultMap['event'] as String?;
          if (signedEventJson != null && signedEventJson.isNotEmpty) {
            print('=== RETURNING SIGNED EVENT IN RESULT FIELD ===');
            print('Signed event JSON length: ${signedEventJson.length}');
            // Return JSON with "result" field containing the signed event JSON
            return jsonEncode({'result': signedEventJson});
          } else {
            // Fallback: the signature is already in the result field, keep it
            _logger.warning('sign_event result missing event field, returning signature in result');
            return jsonEncode(resultMap); // Return as-is with signature in result
          }
        }

        // If this is a get_public_key result, convert npub to hex
        if (method == 'get_public_key' && resultMap.containsKey('result')) {
          final pubkey = resultMap['result'] as String?;
          if (pubkey != null && pubkey.isValidNpubPublicKey) {
            _logger.info('Converting npub to hex: $pubkey');
            final hexPubkey = PubkeyFormatter(pubkey: pubkey).toHex();
            if (hexPubkey != null) {
              resultMap['result'] = hexPubkey;
              _logger.info('Converted to hex: $hexPubkey');
            } else {
              _logger.warning('Failed to convert npub to hex: $pubkey');
            }
          }
        }

        // Return the normalized result as JSON for other methods
        return jsonEncode(resultMap);
      } catch (e) {
        // If parsing fails, return the original result
        _logger.warning('Failed to parse result JSON, returning as-is: $e');
        return resultJson;
      }
    } catch (e, st) {
      _logger.severe('NIP-55 method call failed: $method', e, st);
      // Return error as JSON string for Rust to handle
      return jsonEncode({
        'error': e.toString(),
      });
    }
  }
}
