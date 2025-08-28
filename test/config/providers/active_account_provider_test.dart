import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class MockWnAccountsApi implements WnAccountsApi {
  final Map<String, Account> _accounts = {};
  final Map<String, FlutterMetadata> _metadata = {};
  final List<String> _errorPubkeys = [];

  void setAccount(String pubkey, Account account) {
    _accounts[pubkey] = account;
  }

  void setMetadata(String pubkey, FlutterMetadata metadata) {
    _metadata[pubkey] = metadata;
  }

  void setError(String pubkey) {
    _errorPubkeys.add(pubkey);
  }

  @override
  Future<Account> getAccount({required String pubkey}) async {
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

    return _metadata[pubkey] ?? FlutterMetadata(
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

final testAccount = Account(
  pubkey: 'test_pubkey_123',
  lastSyncedAt: DateTime.now(),
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
  updatedAt: DateTime.now().subtract(const Duration(days: 1)),
);

final testMetadata = FlutterMetadata(
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

final otherTestMetadata = FlutterMetadata(
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

    ProviderContainer createContainer({
      String? activePubkey,
      MockWnAccountsApi? accountsApi,
    }) {
      final api = accountsApi ?? mockAccountsApi;

      return ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(activePubkey)),
          wnAccountsApiProvider.overrideWithValue(api),
        ],
      );
    }

    setUp(() {
      mockAccountsApi = MockWnAccountsApi();
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
        final otherTestAccount = Account(
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
          mockAccountsApi.setAccount('test_pubkey_456', Account(
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
  });
}
