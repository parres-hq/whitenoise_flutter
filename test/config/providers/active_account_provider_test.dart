import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api show Account;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class MockWnImageUtils implements WnImageUtils {
  String? _mimeType = 'image/jpeg';
  bool _shouldFail = false;

  void setMimeType(String? mimeType) {
    _mimeType = mimeType;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<String?> getMimeTypeFromPath(String filePath) async {
    if (_shouldFail) {
      throw Exception('Failed to get MIME type');
    }
    return _mimeType;
  }
}

class MockWnUtils implements WnUtils {
  @override
  Future<String> getDefaultBlossomServerUrl() async {
    return 'https://test.blossom.server';
  }
}

class MockWnAccountsApi implements WnAccountsApi {
  final Map<String, accounts_api.Account> _accounts = {};
  final Map<String, FlutterMetadata> _metadata = {};
  final List<String> _errorPubkeys = [];
  final List<String> _updateErrorPubkeys = [];
  final List<String> _uploadErrorPubkeys = [];

  void setAccount(String pubkey, accounts_api.Account account) {
    _accounts[pubkey] = account;
  }

  void setMetadata(String pubkey, FlutterMetadata metadata) {
    _metadata[pubkey] = metadata;
  }

  void setError(String pubkey) {
    _errorPubkeys.add(pubkey);
  }

  void setUpdateError(String pubkey) {
    _updateErrorPubkeys.add(pubkey);
  }

  void setUploadError(String pubkey) {
    _uploadErrorPubkeys.add(pubkey);
  }

  @override
  Future<accounts_api.Account> getAccount({required String pubkey}) async {
    if (_errorPubkeys.contains(pubkey)) {
      throw Exception('Network error');
    }

    final account = _accounts[pubkey];
    if (account == null) {
      throw StateError('Account not found');
    }
    
    return account;
  }

  @override
  Future<FlutterMetadata> getAccountMetadata({
    required String pubkey,
  }) async {
    if (_errorPubkeys.contains(pubkey)) {
      throw Exception('Network error');
    }

    return _metadata[pubkey] ?? const FlutterMetadata(
      name: '',
      displayName: '',
      about: '',
      picture: '',
      banner: '',
      website: '',
      nip05: '',
      lud06: '',
      lud16: '',
      custom: {},
    );
  }

  @override
  Future<void> updateAccountMetadata({
    required String pubkey,
    required FlutterMetadata metadata,
  }) async {
    if (_updateErrorPubkeys.contains(pubkey)) {
      throw Exception('Update error');
    }

    _metadata[pubkey] = metadata;
  }

  @override
  Future<String> uploadAccountProfilePicture({
    required String pubkey,
    required String serverUrl,
    required String filePath,
    required String imageType,
  }) async {
    if (_uploadErrorPubkeys.contains(pubkey)) {
      throw Exception('Upload error');
    }

    return 'https://example.com/profile-pictures/$pubkey.jpg';
  }
}

class MockActivePubkeyNotifier extends ActivePubkeyNotifier {
  String? _pubkey;

  MockActivePubkeyNotifier(this._pubkey);

  @override
  String? build() {
    return _pubkey;
  }

  @override
  Future<void> setActivePubkey(String pubkey) async {
    _pubkey = pubkey;
    state = pubkey;
  }
}

final testAccount = accounts_api.Account(
  pubkey: 'test_pubkey_123',
  lastSyncedAt: DateTime.now(),
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
  updatedAt: DateTime.now().subtract(const Duration(days: 1)),
);

final testMetadata = const FlutterMetadata(
  name: 'test_name',
  displayName: 'test_display_name',
  about: 'test_about',
  picture: 'test_picture',
  banner: 'test_banner',
  website: 'test_website',
  nip05: 'test_nip05',
  lud06: 'test_lud06',
  lud16: 'test_lud16',
  custom: {},
);

final otherTestMetadata = const FlutterMetadata(
  name: 'other_name',
  displayName: 'other_display_name',
  about: 'other_about',
  picture: 'other_picture',
  banner: 'other_banner',
  website: 'other_website',
  nip05: 'other_nip05',
  lud06: 'other_lud06',
  lud16: 'other_lud16',
  custom: {},
);

void main() {
  group('ActiveAccountProvider Tests', () {
    late ProviderContainer container;
    late MockWnAccountsApi mockAccountsApi;
    late MockWnImageUtils mockImageUtils;
    late MockWnUtils mockUtils;

    ProviderContainer createContainer({
      String? activePubkey,
      MockWnAccountsApi? accountsApi,
      MockWnImageUtils? imageUtils,
      MockWnUtils? utils,
    }) {
      final api = accountsApi ?? mockAccountsApi;
      final imgUtils = imageUtils ?? mockImageUtils;
      final utilsImpl = utils ?? mockUtils;

      return ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(activePubkey)),
          wnAccountsApiProvider.overrideWithValue(api),
          wnImageUtilsProvider.overrideWithValue(imgUtils),
          wnUtilsProvider.overrideWithValue(utilsImpl),
        ],
      );
    }

    setUp(() {
      mockAccountsApi = MockWnAccountsApi();
      mockImageUtils = MockWnImageUtils();
      mockUtils = MockWnUtils();
    });

    tearDown(() {
      container.dispose();
    });

    group('account', () {

      group('with null active pubkey', () {
        setUp(() {
          container = createContainer();
        });

        test('returns null account', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final activeAccount = activeAccountState.account;
          expect(activeAccount, isNull);
        });
      });

      group('with empty active pubkey', () {
        setUp(() {
          container = createContainer(activePubkey: '');
        });

        test('returns null account', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final activeAccount = activeAccountState.account;
          expect(activeAccount, isNull);
        });
      });

      group('with active pubkey', () {
        const testPubkey = 'test_pubkey_123';

        setUp(() {
          mockAccountsApi.setAccount(testPubkey, testAccount);
          mockAccountsApi.setMetadata(testPubkey, testMetadata);

          container = createContainer(
            activePubkey: testPubkey,
            accountsApi: mockAccountsApi,
          );
        });

        test('returns account', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final activeAccount = activeAccountState.account;
          expect(activeAccount?.pubkey, 'test_pubkey_123');
          expect(activeAccount?.createdAt, testAccount.createdAt);
          expect(activeAccount?.updatedAt, testAccount.updatedAt);
          expect(activeAccount?.lastSyncedAt, testAccount.lastSyncedAt);
        });
      });

      group('with error', () {
        const testPubkey = 'test_pubkey_123';

        setUp(() {
          mockAccountsApi.setAccount(testPubkey, testAccount);
          mockAccountsApi.setMetadata(testPubkey, testMetadata);
          mockAccountsApi.setError(testPubkey);

          container = createContainer(
            activePubkey: testPubkey,
            accountsApi: mockAccountsApi,
          );
        });

        test('returns null account', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final activeAccount = activeAccountState.account;
          expect(activeAccount, isNull);
        });
      });

      group('when active pubkey changes', () {
        final otherTestAccount = accounts_api.Account(
          pubkey: 'test_pubkey_456',
          lastSyncedAt: DateTime.now(),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setAccount('test_pubkey_456', otherTestAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          mockAccountsApi.setMetadata('test_pubkey_456', otherTestMetadata);
          container = createContainer(activePubkey: 'test_pubkey_123');
        });
        test('updates account', () async {
          final initialActiveAccountState = await container.read(activeAccountProvider.future);
          final initialActiveAccount = initialActiveAccountState.account;
          expect(initialActiveAccount?.pubkey, 'test_pubkey_123');
          await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_456');
          final updatedActiveAccountState = await container.read(activeAccountProvider.future);
          final updatedActiveAccount = updatedActiveAccountState.account;
          expect(updatedActiveAccount?.pubkey, 'test_pubkey_456');
        });
      });
    });

    group('metadata', () {

      group('with null active pubkey', () {
        setUp(() {
          container = createContainer();
        });

        test('returns null metadata', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final metadata = activeAccountState.metadata;
          expect(metadata, isNull);
        });
      });

      group('with empty active pubkey', () {
        setUp(() {
          container = createContainer(activePubkey: '');
        });

        test('returns null metadata', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final metadata = activeAccountState.metadata;
          expect(metadata, isNull);
        });
      });

      group('with active pubkey', () {
        const testPubkey = 'test_pubkey_123';

        setUp(() {
          mockAccountsApi.setAccount(testPubkey, testAccount);
          mockAccountsApi.setMetadata(testPubkey, testMetadata);

          container = createContainer(
            activePubkey: testPubkey,
            accountsApi: mockAccountsApi,
          );
        });

        test('returns metadata', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final metadata = activeAccountState.metadata;
          expect(metadata?.name, 'test_name');
          expect(metadata?.displayName, 'test_display_name');
          expect(metadata?.about, 'test_about');
          expect(metadata?.picture, 'test_picture');
        });
      });

      group('with error', () {
        const testPubkey = 'test_pubkey_123';

        setUp(() {
          mockAccountsApi.setAccount(testPubkey, testAccount);
          mockAccountsApi.setMetadata(testPubkey, testMetadata);
          mockAccountsApi.setError(testPubkey);

          container = createContainer(
            activePubkey: testPubkey,
            accountsApi: mockAccountsApi,
          );
        });

        test('returns null metadata', () async {
          final activeAccountState = await container.read(activeAccountProvider.future);
          final metadata = activeAccountState.metadata;
          expect(metadata, isNull);
        });
      });

      group('when active pubkey changes', () {
        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setAccount('test_pubkey_456', accounts_api.Account(
            pubkey: 'test_pubkey_456',
            lastSyncedAt: DateTime.now(),
            createdAt: DateTime.now().subtract(const Duration(days: 60)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ));
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          mockAccountsApi.setMetadata('test_pubkey_456', otherTestMetadata);
          container = createContainer(activePubkey: 'test_pubkey_123');
        });
        test('updates metadata', () async {
          final initialActiveAccountState = await container.read(activeAccountProvider.future);
          final initialMetadata = initialActiveAccountState.metadata;
          expect(initialMetadata?.name, 'test_name');
          await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_456');
          final updatedActiveAccountState = await container.read(activeAccountProvider.future);
          final updatedMetadata = updatedActiveAccountState.metadata;
          expect(updatedMetadata?.name, 'other_name');
        });
      });
    });

    group('updateMetadata', () {
      const newMetadata = FlutterMetadata(
        name: 'New Name',
        displayName: 'New Display Name',
        about: 'New About',
        picture: 'New Picture',
        nip05: 'New Nip05',
        lud16: 'New Lud16',
        website: 'New Website',
        banner: 'New Banner',
        custom: {},
      );

      group('with null active pubkey', () {
        setUp(() {
          container = createContainer();
        });

        test('throws exception for null pubkey', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.updateMetadata(metadata: newMetadata),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('with empty active pubkey', () {
        setUp(() {
          container = createContainer(activePubkey: '');
        });

        test('throws exception for empty pubkey', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.updateMetadata(metadata: newMetadata),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('with valid pubkey', () {
        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          container = createContainer(
            activePubkey: 'test_pubkey_123',
            accountsApi: mockAccountsApi,
          );
        });

        test('updates metadata', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          final initialState = await container.read(activeAccountProvider.future);
          expect(initialState.account?.pubkey, 'test_pubkey_123');
          expect(initialState.metadata?.displayName, 'test_display_name');
          await notifier.updateMetadata(metadata: newMetadata);
          final updatedActiveAccountState = await container.read(activeAccountProvider.future);
          final updatedMetadata = updatedActiveAccountState.metadata;
          expect(updatedMetadata?.displayName, 'New Display Name');
        });
      });

      group('when update fails', () {
        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          mockAccountsApi.setUpdateError('test_pubkey_123');
          container = createContainer(
            activePubkey: 'test_pubkey_123',
            accountsApi: mockAccountsApi,
          );
        });

        test('thows error but does not update state', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          expect(
            () => notifier.updateMetadata(metadata: newMetadata),
            throwsA(isA<Exception>()),
          );
          final currentState = await container.read(activeAccountProvider.future);
          expect(currentState.metadata?.displayName, 'test_display_name');
          expect(currentState.metadata?.about, 'test_about');
        });
      });
    });

    group('uploadProfilePicture', () {
      const testFilePath = '/path/to/test/image.jpg';

      group('with null active pubkey', () {
        setUp(() {
          container = createContainer();
        });

        test('throws exception for null pubkey', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.uploadProfilePicture(filePath: testFilePath),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('with empty active pubkey', () {
        setUp(() {
          container = createContainer(activePubkey: '');
        });

        test('throws exception for empty pubkey', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.uploadProfilePicture(filePath: testFilePath),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('with valid pubkey', () {
        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          container = createContainer(
            activePubkey: 'test_pubkey_123',
            accountsApi: mockAccountsApi,
          );
        });

        test('returns profile picture URL when upload is successful', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          final profilePictureUrl = await notifier.uploadProfilePicture(filePath: testFilePath);
          
          expect(profilePictureUrl, 'https://example.com/profile-pictures/test_pubkey_123.jpg');
        });
      });

      group('when upload fails', () {
        setUp(() {
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          mockAccountsApi.setUploadError('test_pubkey_123');
          container = createContainer(
            activePubkey: 'test_pubkey_123',
            accountsApi: mockAccountsApi,
          );
        });

        test('throws error when upload fails', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.uploadProfilePicture(filePath: testFilePath),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('when getMimeTypeFromPath returns null', () {
        setUp(() {
          final mockImageUtilsForNull = MockWnImageUtils();
          mockImageUtilsForNull.setMimeType(null);
          
          mockAccountsApi.setAccount('test_pubkey_123', testAccount);
          mockAccountsApi.setMetadata('test_pubkey_123', testMetadata);
          container = createContainer(
            activePubkey: 'test_pubkey_123',
            accountsApi: mockAccountsApi,
            imageUtils: mockImageUtilsForNull,
          );
        });

        test('throws error when image type cannot be determined', () async {
          final notifier = container.read(activeAccountProvider.notifier);
          
          expect(
            () => notifier.uploadProfilePicture(filePath: testFilePath),
            throwsA(predicate((e) => 
              e is Exception && 
              e.toString().contains('Could not determine image type')
            )),
          );
        });
      });
    });
  });
}
