import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/utils/image_utils.dart';

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

abstract class WnImageUtils {
  Future<String?> getMimeTypeFromPath(String filePath);
}

class DefaultWnImageUtils implements WnImageUtils {
  const DefaultWnImageUtils();

  @override
  Future<String?> getMimeTypeFromPath(String filePath) {
    return ImageUtils.getMimeTypeFromPath(filePath);
  }
}

abstract class WnUtils {
  Future<String> getDefaultBlossomServerUrl();
}

class DefaultWnUtils implements WnUtils {
  const DefaultWnUtils();

  @override
  Future<String> getDefaultBlossomServerUrl() {
    // TODO: Replace with the actual implementation (e.g., read from settings).
    throw UnimplementedError('getDefaultBlossomServerUrl not implemented');
  }
}

abstract class WnAccountsApi {
  Future<accounts_api.Account> getAccount({required String pubkey});
  Future<FlutterMetadata> getAccountMetadata({required String pubkey});
  Future<void> updateAccountMetadata({required String pubkey, required FlutterMetadata metadata});
  Future<String> uploadAccountProfilePicture({
    required String pubkey,
    required String serverUrl,
    required String filePath,
    required String imageType,
  });
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

  @override
  Future<void> updateAccountMetadata({required String pubkey, required FlutterMetadata metadata}) {
    return accounts_api.updateAccountMetadata(pubkey: pubkey, metadata: metadata);
  }

  @override
  Future<String> uploadAccountProfilePicture({
    required String pubkey,
    required String serverUrl,
    required String filePath,
    required String imageType,
  }) {
    return accounts_api.uploadAccountProfilePicture(
      pubkey: pubkey,
      serverUrl: serverUrl,
      filePath: filePath,
      imageType: imageType,
    );
  }
}

final wnAccountsApiProvider = Provider<WnAccountsApi>((ref) => const DefaultWnAccountsApi());
final wnImageUtilsProvider = Provider<WnImageUtils>((ref) => const DefaultWnImageUtils());
final wnUtilsProvider = Provider<WnUtils>((ref) => const DefaultWnUtils());

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

class ActiveAccountNotifier extends AsyncNotifier<ActiveAccountState> {
  @override
  Future<ActiveAccountState> build() async {
    final activePubkey = ref.watch(activePubkeyProvider) ?? '';
    final accountsApi = ref.read(wnAccountsApiProvider);

    if (activePubkey.isEmpty) {
      _logger.fine('No active pubkey set');
      return const ActiveAccountState();
    }

    try {
      final (account, metadata) =
          await (
            _fetchAccount(accountsApi, activePubkey),
            _fetchMetadata(accountsApi, activePubkey),
          ).wait;

      _logger.fine(
        'ActiveAccountProvider: Successfully fetched account and metadata for ${account.pubkey}',
      );

      return ActiveAccountState(
        account: account,
        metadata: metadata,
      );
    } catch (e) {
      _logger.warning(
        'ActiveAccountProvider: Error fetching account/metadata for $activePubkey: $e',
      );
      return ActiveAccountState(error: e.toString());
    }
  }

  Future<void> updateMetadata({
    required FlutterMetadata metadata,
  }) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';

    if (activePubkey.isEmpty) {
      _logger.fine('No active pubkey set');
      throw Exception('No active pubkey available');
    }

    final accountsApi = ref.read(wnAccountsApiProvider);
    try {
      await accountsApi.updateAccountMetadata(
        pubkey: activePubkey,
        metadata: metadata,
      );
      ref.invalidateSelf();
    } catch (e) {
      _logger.severe('Failed to update metadata: $e');
      rethrow;
    }
  }

  Future<String> uploadProfilePicture({
    required String filePath,
  }) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';

    if (activePubkey.isEmpty) {
      _logger.fine('No active pubkey set');
      throw Exception('No active pubkey available');
    }

    try {
      _logger.fine('Uploading profile picture for pubkey: $activePubkey');

      final imageUtils = ref.read(wnImageUtilsProvider);
      final imageType = await imageUtils.getMimeTypeFromPath(filePath);
      if (imageType == null) {
        throw Exception('Could not determine image type from file path: $filePath');
      }
      final utils = ref.read(wnUtilsProvider);
      final serverUrl = await utils.getDefaultBlossomServerUrl();

      final accountsApi = ref.read(wnAccountsApiProvider);
      final profilePictureUrl = await accountsApi.uploadAccountProfilePicture(
        pubkey: activePubkey,
        serverUrl: serverUrl,
        filePath: filePath,
        imageType: imageType,
      );

      _logger.fine(
        'Successfully uploaded profile picture for pubkey: $activePubkey, URL: $profilePictureUrl',
      );
      return profilePictureUrl;
    } catch (e) {
      _logger.severe('Failed to upload profile picture: $e');
      rethrow;
    }
  }
}

final activeAccountProvider = AsyncNotifierProvider<ActiveAccountNotifier, ActiveAccountState>(
  ActiveAccountNotifier.new,
);
