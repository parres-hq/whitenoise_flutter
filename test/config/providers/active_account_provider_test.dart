import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account;

class MockWnAccountsApi implements WnAccountsApi {
  final Map<String, Account> _accounts = {};
  final List<String> _errorPubkeys = [];

  void setAccount(String pubkey, Account account) {
    _accounts[pubkey] = account;
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

    group('with null active pubkey', () {
      setUp(() {
        container = createContainer();
      });

      test('returns null', () async {
        final result = await container.read(activeAccountProvider.future);
        expect(result, isNull);
      });
    });

    group('with empty active pubkey', () {
      setUp(() {
        container = createContainer(activePubkey: '');
      });

      test('should return null', () async {
        final result = await container.read(activeAccountProvider.future);
        expect(result, isNull);
      });
    });

    group('with active pubkey', () {
      const testPubkey = 'test_pubkey_123';

      setUp(() {
        mockAccountsApi.setAccount(testPubkey, testAccount);

        container = createContainer(
          activePubkey: testPubkey,
          accountsApi: mockAccountsApi,
        );
      });

      test('returns account', () async {
        final result = await container.read(activeAccountProvider.future);
        expect(result?.pubkey, 'test_pubkey_123');
        expect(result?.createdAt, testAccount.createdAt);
        expect(result?.updatedAt, testAccount.updatedAt);
        expect(result?.lastSyncedAt, testAccount.lastSyncedAt);
      });
    });

    group('with error', () {
      const testPubkey = 'test_pubkey_123';

      setUp(() {
        mockAccountsApi.setAccount(testPubkey, testAccount);
        mockAccountsApi.setError(testPubkey);

        container = createContainer(
          activePubkey: testPubkey,
          accountsApi: mockAccountsApi,
        );
      });

      test('returns null', () async {
        final result = await container.read(activeAccountProvider.future);
        expect(result, isNull);
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
        container = createContainer(activePubkey: 'test_pubkey_123');
      });
      test('updates account', () async {
        final initialResult = await container.read(activeAccountProvider.future);
        expect(initialResult?.pubkey, 'test_pubkey_123');
        await container.read(activePubkeyProvider.notifier).setActivePubkey('test_pubkey_456');
        final updatedResult = await container.read(activeAccountProvider.future);
        expect(updatedResult?.pubkey, 'test_pubkey_456');
      });
    });
  });
}
