import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

/// Service for handling NIP-55 (Android Signer Application) communication
class Nip55Service {
  static const MethodChannel _channel = MethodChannel('nip55_signer');
  static final Logger _logger = Logger('Nip55Service');

  /// Check if an external signer app is installed
  static Future<bool> isExternalSignerInstalled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('isExternalSignerInstalled');
      return result ?? false;
    } catch (e) {
      _logger.warning('Error checking if external signer is installed: $e');
      return false;
    }
  }

  /// Call a NIP-55 method via Android Intent
  ///
  /// [method] - The method name (e.g., "sign_event", "get_public_key")
  /// [params] - JSON string containing method parameters
  ///
  /// Returns a JSON string with the result
  static Future<String> callNip55Method({
    required String method,
    required String params,
  }) async {
    _logger.info('NIP55 service called: method=$method, params=$params');
    if (!Platform.isAndroid) {
      throw UnsupportedError('NIP-55 is only supported on Android');
    }

    try {
      _logger.fine('Invoking Android method channel for NIP55');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'callNip55Method',
        {
          'method': method,
          'params': params,
        },
      );

      if (result == null) {
        throw Exception('No result returned from NIP-55 method call');
      }

      // Convert result map to JSON string
      return jsonEncode(result);
    } on PlatformException catch (e) {
      _logger.severe('Platform error calling NIP-55 method: ${e.message}', e);
      throw Exception('NIP-55 method call failed: ${e.message}');
    } catch (e) {
      _logger.severe('Error calling NIP-55 method: $e');
      rethrow;
    }
  }

  /// Clear the cached public key result
  ///
  /// This should be called when:
  /// - User logs out
  /// - User switches accounts
  /// - User disables the external signer
  static Future<void> clearCache() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod('clearCache');
      _logger.fine('NIP55 cache cleared');
    } catch (e) {
      _logger.warning('Error clearing NIP55 cache: $e');
      // Don't throw - cache clearing is not critical
    }
  }
}
