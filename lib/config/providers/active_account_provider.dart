import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

final _logger = Logger('ActiveAccountProvider');

class ActiveAccountState {
  final accounts_api.Account? account;
  final FlutterMetadata? metadata;
  final bool isLoading;
  final String? error;

  const ActiveAccountState({
    this.account,
    this.metadata,
    this.isLoading = false,
    this.error,
  });

  ActiveAccountState copyWith({
    accounts_api.Account? account,
    FlutterMetadata? metadata,
    bool? isLoading,
    String? error,
  }) => ActiveAccountState(
    account: account ?? this.account,
    metadata: metadata ?? this.metadata,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

abstract class WnAccountsApi {
  Future<accounts_api.Account> getAccount({required String pubkey});
  Future<FlutterMetadata> getAccountMetadata({required String pubkey});
}

class DefaultWnAccountsApi implements WnAccountsApi {
  const DefaultWnAccountsApi();

  @override
  Future<accounts_api.Account> getAccount({required String pubkey}) {
    return accounts_api.getAccount(pubkey: pubkey);
  }

  @override
  Future<FlutterMetadata> getAccountMetadata({required String pubkey}) {
    return accounts_api.accountMetadata(pubkey: pubkey);
  }
}

final wnAccountsApiProvider = Provider<WnAccountsApi>((ref) => const DefaultWnAccountsApi());

Future<accounts_api.Account> _fetchAccount(WnAccountsApi accountsApi, String pubkey) async {
  try {
    _logger.fine('Fetching account for pubkey: $pubkey');
    final account = await accountsApi.getAccount(pubkey: pubkey);
    _logger.fine('Successfully fetched account for pubkey: $pubkey');
    return account;
  } catch (e) {
    _logger.warning('Failed to fetch account for pubkey: $pubkey - Error: $e');
    rethrow;
  }
}

Future<FlutterMetadata> _fetchMetadata(WnAccountsApi accountsApi, String pubkey) async {
  try {
    _logger.fine('Fetching metadata for pubkey: $pubkey');
    final metadata = await accountsApi.getAccountMetadata(pubkey: pubkey);
    _logger.fine('Successfully fetched metadata for pubkey: $pubkey');
    return metadata;
  } catch (e) {
    _logger.warning('Failed to fetch metadata for pubkey: $pubkey - Error: $e');
    rethrow;
  }
}

final activeAccountProvider = FutureProvider<ActiveAccountState>((ref) async {
  final activePubkey = ref.watch(activePubkeyProvider);
  final accountsApi = ref.read(wnAccountsApiProvider);

  if (activePubkey == null || activePubkey.isEmpty) {
    _logger.fine('No active pubkey set');
    return const ActiveAccountState();
  }

  try {
    final (account, metadata) = await (
      _fetchAccount(accountsApi, activePubkey),
      _fetchMetadata(accountsApi, activePubkey),
    ).wait;
    
    _logger.fine('ActiveAccountProvider: Successfully fetched account and metadata for ${account.pubkey}');
    
    return ActiveAccountState(
      account: account,
      metadata: metadata,
    );
  } catch (e) {
    _logger.warning('ActiveAccountProvider: Error fetching account/metadata for $activePubkey: $e');
    return ActiveAccountState(error: e.toString());
  }
});
