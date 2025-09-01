import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart';

class MockWnUsersApi implements WnUsersApi {
  final Map<String, User> _users = {};
  Exception? _throwError;

  void addUser(String pubkey, User user) {
    _users[pubkey] = user;
  }

  void setThrowError(Exception error) {
    _throwError = error;
  }

  void clearError() {
    _throwError = null;
  }

  @override
  Future<User> getUser({required String pubkey}) async {
    if (_throwError != null) {
      throw _throwError!;
    }

    final user = _users[pubkey];
    if (user == null) {
      throw Exception('User not found');
    }

    return user;
  }
}

void main() {
  group('UserProfileDataProvider Tests', () {
    late ProviderContainer container;
    late MockWnUsersApi mockUsersApi;
    final testPubkey = 'test_pubkey_123';
    final testMetadata = const FlutterMetadata(
      name: 'John Doe',
      displayName: 'Johnny',
      about: 'Test user bio',
      picture: 'https://example.com/avatar.jpg',
      website: 'https://johndoe.com',
      nip05: 'john@example.com',
      lud16: 'john@zap.me',
      custom: {},
    );
    final testUser = User(
      pubkey: testPubkey,
      metadata: testMetadata,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
    );

    ProviderContainer createContainer({MockWnUsersApi? usersApi}) {
      final api = usersApi ?? mockUsersApi;

      return ProviderContainer(
        overrides: [
          userProfileDataProvider.overrideWith(() => UserProfileDataNotifier(usersApi: api)),
        ],
      );
    }

    setUp(() {
      mockUsersApi = MockWnUsersApi();
      container = createContainer(usersApi: mockUsersApi);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial State', () {
      test('notifier should be accessible', () {
        final notifier = container.read(userProfileDataProvider.notifier);
        expect(notifier, isA<UserProfileDataNotifier>());
      });
    });

    group('getUserProfileData', () {
      group('when user exists', () {
        setUp(() {
          mockUsersApi.addUser(testPubkey, testUser);
        });
        test('returns expected user profile data', () async {
          final notifier = container.read(userProfileDataProvider.notifier);
          final result = await notifier.getUserProfileData(testPubkey);

          expect(result, isNotNull);
          expect(result.publicKey, testPubkey);
          expect(result.displayName, 'Johnny');
          expect(result.about, 'Test user bio');
          expect(result.imagePath, 'https://example.com/avatar.jpg');
          expect(result.website, 'https://johndoe.com');
          expect(result.nip05, 'john@example.com');
          expect(result.lud16, 'john@zap.me');
        });
      });

      group('when metadata has no display name', () {
        setUp(() {
          final metadataWithoutDisplayName = const FlutterMetadata(
            about: 'Bio without name',
            custom: {},
          );
          final userWithoutName = User(
            pubkey: testPubkey,
            metadata: metadataWithoutDisplayName,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
          );
          mockUsersApi.addUser(testPubkey, userWithoutName);
        });
        test(
          'returns data with "Unknown User" for display name',
          () async {
            final notifier = container.read(userProfileDataProvider.notifier);
            final result = await notifier.getUserProfileData(testPubkey);
            expect(result, isNotNull);
            expect(result.displayName, 'Unknown User');
            expect(result.about, 'Bio without name');
          },
        );
      });

      group('when API throws error', () {
        setUp(() {
          mockUsersApi.setThrowError(Exception('API error'));
        });
        test('throws exception', () async {
          final notifier = container.read(userProfileDataProvider.notifier);
          expect(
            () async => await notifier.getUserProfileData(testPubkey),
            throwsException,
          );
        });
      });
    });
  });
}
