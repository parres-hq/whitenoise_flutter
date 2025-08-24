import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart' as wnRelaysApi;
import 'package:whitenoise/src/rust/api/accounts.dart' as wnAccountsApi;
import 'package:whitenoise/src/rust/api/utils.dart' as wnUtilsApi;

typedef FetchKeyPackageFunction =
    Future<wnAccountsApi.Event?> Function({
      required String pubkey,
      required List<wnUtilsApi.RelayUrl> nip65Relays,
    });

class KeyPackageService {
  // TODO: pepi need to use fetch user relays method.. Maybe delet this service and move to user
  final _logger = Logger('KeyPackageService');
  final String _pubkey;
  final List<wnUtilsApi.RelayUrl> _nip65Relays;

  KeyPackageService({
    required String pubkey,
    required List<wnUtilsApi.RelayUrl> nip65Relays,
  }) : _pubkey = pubkey,
       _nip65Relays = nip65Relays;

  Future<wnAccountsApi.Event?> fetchWithRetry() async {
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

  Future<wnAccountsApi.Event?> _attemptToFetchKeyPackage(int attempt) async {
    // TODO big plans: fetch key package
    // _logger.info('Key package fetch attempt $attempt for $_pubkey');

    // final freshPubkey = _pubkey;
    // final keyPackage = await _fetchKeyPackage(pubkey: freshPubkey, nip65Relays: _nip65Relays);

    // _logger.info(
    //   'Key package fetch successful on attempt $attempt - result: ${keyPackage != null ? "found" : "null"}',
    // );

    //return keyPackage;
    return null;
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
