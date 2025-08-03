import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart' as relays;
import 'package:whitenoise/src/rust/api/utils.dart' as utils;

typedef FetchKeyPackageFunction = Future<relays.Event?> Function({required PublicKey pubkey});
typedef PublicKeyFromStringFunction = Future<PublicKey> Function({required String publicKeyString});

class KeyPackageService {
  final _logger = Logger('KeyPackageService');
  final FetchKeyPackageFunction _fetchKeyPackage;
  final PublicKeyFromStringFunction _publicKeyFromString;
  final String _publicKeyString;

  KeyPackageService({
    required String publicKeyString,
    FetchKeyPackageFunction? fetchKeyPackage,
    PublicKeyFromStringFunction? publicKeyFromString,
  }) : _publicKeyString = publicKeyString,
       _fetchKeyPackage = fetchKeyPackage ?? relays.fetchKeyPackage,
       _publicKeyFromString = publicKeyFromString ?? utils.publicKeyFromString;

  Future<relays.Event?> fetchWithRetry() async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final keyPackage = await _attemptToFetchKeyPackage(attempt);
        return keyPackage;
      } catch (e) {
        _handleFetchKeyPackageError(e, attempt, maxAttempts);
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return null;
  }

  Future<relays.Event?> _attemptToFetchKeyPackage(int attempt) async {
    _logger.info('Key package fetch attempt $attempt for $_publicKeyString');

    final freshPubkey = await _publicKeyFromString(publicKeyString: _publicKeyString);
    final keyPackage = await _fetchKeyPackage(pubkey: freshPubkey);

    _logger.info(
      'Key package fetch successful on attempt $attempt - result: ${keyPackage != null ? "found" : "null"}',
    );

    return keyPackage;
  }

  void _handleFetchKeyPackageError(
    Object e,
    int attempt,
    int maxAttempts,
  ) {
    _logger.warning('Key package fetch attempt $attempt failed: $e');

    if (e.toString().contains('DroppableDisposedException') || e.toString().contains('RustArc')) {
      _logger.warning('Detected disposal exception, will retry with fresh objects');
    } else {
      _logger.severe('Non-disposal error encountered, not retrying: $e');
      throw e;
    }

    if (attempt == maxAttempts) {
      _logger.severe('Failed to fetch key package after $maxAttempts attempts: $e');
      throw Exception('Failed to fetch key package after $maxAttempts attempts: $e');
    }
  }
}
