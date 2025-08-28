import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('ActiveAccountProvider');

abstract class WnAccountsApi {
  Future<accounts_api.Account> getAccount({required String pubkey});
}

class DefaultWnAccountsApi implements WnAccountsApi {
  const DefaultWnAccountsApi();

  @override
  Future<accounts_api.Account> getAccount({required String pubkey}) {
    return accounts_api.getAccount(pubkey: pubkey);
  }
}

final wnAccountsApiProvider = Provider<WnAccountsApi>((ref) => const DefaultWnAccountsApi());

final activeAccountProvider = FutureProvider<accounts_api.Account?>((ref) async {
  final activePubkey = ref.watch(activePubkeyProvider);
  final accountsApi = ref.read(wnAccountsApiProvider);

  if (activePubkey == null || activePubkey.isEmpty) {
    _logger.fine('No active pubkey set');
    return null;
  }

  try {
    _logger.fine('Fetching account data for pubkey: $activePubkey');
    final account = await accountsApi.getAccount(pubkey: activePubkey);
    _logger.fine('ActiveAccountProvider: Successfully fetched account data for ${account.pubkey}');
    return account;
  } catch (e) {
    _logger.warning('ActiveAccountProvider: Error with getAccount API for $activePubkey $e');
    return null;
  }
});
