import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart' as relays;

typedef FetchKeyPackageFunction =
    Future<relays.Event?> Function({
      required PublicKey pubkey,
      required List<RelayUrl> nip65Relays,
    });

class KeyPackageService {
  final _logger = Logger('KeyPackageService');
  final FetchKeyPackageFunction _fetchKeyPackage;
  final String _publicKey;
  final List<RelayUrl> _nip65Relays;

  KeyPackageService({
    required String publicKey,
    required List<RelayUrl> nip65Relays,
    FetchKeyPackageFunction? fetchKeyPackage,
  }) : _publicKey = publicKey,
       _nip65Relays = nip65Relays,
       _fetchKeyPackage = fetchKeyPackage ?? relays.fetchKeyPackage;

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
    _logger.info('Key package fetch attempt $attempt for $_publicKey');

    final keyPackage = await _fetchKeyPackage(pubkey: _publicKey, nip65Relays: _nip65Relays);

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
