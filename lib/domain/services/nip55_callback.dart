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
      await nip55_api.setNip55FlutterCallback(callback: _handleNip55MethodCall);
      _initialized = true;
      _logger.info('NIP-55 callback initialized successfully');
    } catch (e, st) {
      _logger.severe('Failed to initialize NIP-55 callback', e, st);
      rethrow;
    }
  }

  static Future<String> _handleNip55MethodCall(
    String method,
    String params,
  ) async {
    try {
      _logger.info('NIP-55 callback triggered: $method');
      _logger.fine('Raw params (length ${params.length}): $params');

      String normalizedParams = params.trim();

      if (normalizedParams.isEmpty ||
          normalizedParams == 'null' ||
          normalizedParams == 'Null' ||
          normalizedParams == 'NULL') {
        normalizedParams = '{}';
      } else {
        try {
          final parsed = jsonDecode(normalizedParams);
          if (parsed is List) {
            if (method == 'sign_event' && parsed.isNotEmpty) {
              _logger.fine('sign_event array detected with ${parsed.length} elements');
              final eventJsonString =
                  parsed[0] is String ? parsed[0] as String : jsonEncode(parsed[0]);

              // Extract current_user if provided (second element)
              final currentUser =
                  parsed.length >= 2 && parsed[1] is String ? parsed[1] as String : '';

              final paramsMap = <String, dynamic>{'event': eventJsonString};
              if (currentUser.isNotEmpty) {
                paramsMap['current_user'] = currentUser;
              }

              normalizedParams = jsonEncode(paramsMap);
              _logger.fine(
                'Normalized sign_event params (first 200 chars): ${normalizedParams.length > 200 ? normalizedParams.substring(0, 200) : normalizedParams}',
              );
            } else if ((method == 'nip44_encrypt' || method == 'nip44_decrypt') &&
                parsed.length >= 2) {
              _logger.fine('$method array detected with ${parsed.length} elements');
              final pubkey = parsed[0] as String;
              final text = parsed[1] as String;
              final paramsMap = <String, dynamic>{
                'pubkey': pubkey,
                method == 'nip44_encrypt' ? 'plaintext' : 'ciphertext': text,
              };

              // Extract current_user if provided (third element)
              if (parsed.length >= 3 && parsed[2] is String) {
                paramsMap['current_user'] = parsed[2] as String;
              }

              normalizedParams = jsonEncode(paramsMap);
            } else {
              _logger.warning(
                'Params was an array (${parsed.length} items) for method $method, converting to empty object',
              );
              normalizedParams = '{}';
            }
          } else if (parsed is Map) {
            normalizedParams = jsonEncode(parsed);
          } else if (parsed == null) {
            normalizedParams = '{}';
          } else {
            _logger.warning(
              'Params was non-object type (${parsed.runtimeType}), using empty object',
            );
            normalizedParams = '{}';
          }
        } catch (e) {
          _logger.warning('Invalid JSON params "$normalizedParams", using empty object: $e');
          normalizedParams = '{}';
        }
      }

      _logger.fine('Normalized params: $normalizedParams');
      _logger.info('Calling NIP-55 service for method: $method');
      final resultJson = await Nip55Service.callNip55Method(
        method: method,
        params: normalizedParams,
      );

      _logger.info('NIP-55 service returned for method: $method');
      _logger.fine('Result length: ${resultJson.length}');
      _logger.fine('Raw result: $resultJson');

      try {
        final resultMap = jsonDecode(resultJson) as Map<String, dynamic>;

        if (method == 'sign_event') {
          final signedEventJson = resultMap['event'] as String?;
          if (signedEventJson != null && signedEventJson.isNotEmpty) {
            _logger.info(
              'Returning signed event in result field (length: ${signedEventJson.length})',
            );
            return jsonEncode({'result': signedEventJson});
          } else {
            _logger.warning('sign_event result missing event field, returning signature in result');
            return jsonEncode(resultMap);
          }
        }

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

        return jsonEncode(resultMap);
      } catch (e) {
        _logger.warning('Failed to parse result JSON, returning as-is: $e');
        return resultJson;
      }
    } catch (e, st) {
      _logger.severe('NIP-55 method call failed: $method', e, st);
      return jsonEncode({'error': e.toString()});
    }
  }
}
