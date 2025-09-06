import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart';

final testNpubPubkey = 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf';
final testHexPubkey = '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff';

ContactModel mockContactModelFromMetadata({
  required String pubkey,
  FlutterMetadata? metadata,
}) {
  final npub = pubkey == testHexPubkey ? testNpubPubkey : pubkey;
  return ContactModel.fromMetadata(
    pubkey: npub,
    metadata: metadata,
  );
}

class MockWnUsersApi {
  final Map<String, User> _users = {};
  Exception? _throwError;

  void addUser(String hexPubkey, User user) {
    _users[hexPubkey] = user;
  }

  void setThrowError(Exception error) {
    _throwError = error;
  }

  void clearError() {
    _throwError = null;
  }

  Future<User> getUser({required String pubkey}) async {
    if (_throwError != null) {
      throw _throwError!;
    }

    final hex = pubkey == testNpubPubkey ? testHexPubkey : pubkey;
    final user = _users[hex];
    if (user == null) {
      throw Exception('User not found');
    }

    return user;
  }
}

void main() {
  group('UserProfileDataProvider Tests', () {
    late ProviderContainer container;
    late MockWnUsersApi mockWnUsersApi;
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
      pubkey: testNpubPubkey,
      metadata: testMetadata,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
    );

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          userProfileDataProvider.overrideWith(
            () => UserProfileDataNotifier(
              wnApiGetUserFn: mockWnUsersApi.getUser,
              getContactModelFromMetadataFn: mockContactModelFromMetadata,
            ),
          ),
        ],
      );
    }

    setUp(() {
      mockWnUsersApi = MockWnUsersApi();
      container = createContainer();
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
          mockWnUsersApi.addUser(testHexPubkey, testUser);
        });

        group('with npub pubkey', () {
          test('returns expected user profile data', () async {
            final notifier = container.read(userProfileDataProvider.notifier);
            final result = await notifier.getUserProfileData(testNpubPubkey);

            expect(result, isNotNull);
            expect(result.publicKey, testNpubPubkey);
            expect(result.displayName, 'Johnny');
            expect(result.about, 'Test user bio');
            expect(result.imagePath, 'https://example.com/avatar.jpg');
            expect(result.website, 'https://johndoe.com');
            expect(result.nip05, 'john@example.com');
            expect(result.lud16, 'john@zap.me');
          });
        });

        group('with hex pubkey', () {
          test('returns expected user profile data', () async {
            final notifier = container.read(userProfileDataProvider.notifier);
            final result = await notifier.getUserProfileData(testHexPubkey);

            expect(result, isNotNull);
            expect(result.publicKey, testNpubPubkey);
            expect(result.displayName, 'Johnny');
            expect(result.about, 'Test user bio');
            expect(result.imagePath, 'https://example.com/avatar.jpg');
            expect(result.website, 'https://johndoe.com');
            expect(result.nip05, 'john@example.com');
            expect(result.lud16, 'john@zap.me');
          });
        });
      });

      group('when metadata has no display name', () {
        setUp(() {
          final metadataWithoutDisplayName = const FlutterMetadata(
            about: 'Bio without name',
            custom: {},
          );
          final userWithoutName = User(
            pubkey: testNpubPubkey,
            metadata: metadataWithoutDisplayName,
            createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
          );
          mockWnUsersApi.addUser(testHexPubkey, userWithoutName);
        });

        group('with npub pubkey', () {
          test(
            'returns data with "Unknown User" for display name',
            () async {
              final notifier = container.read(userProfileDataProvider.notifier);
              final result = await notifier.getUserProfileData(testNpubPubkey);
              expect(result, isNotNull);
              expect(result.displayName, 'Unknown User');
              expect(result.about, 'Bio without name');
            },
          );
        });

        group('with hex pubkey', () {
          test(
            'returns data with "Unknown User" for display name',
            () async {
              final notifier = container.read(userProfileDataProvider.notifier);
              final result = await notifier.getUserProfileData(testHexPubkey);
              expect(result, isNotNull);
              expect(result.displayName, 'Unknown User');
              expect(result.about, 'Bio without name');
            },
          );
        });
      });

      group('when API throws error', () {
        setUp(() {
          mockWnUsersApi.setThrowError(Exception('API error'));
        });
        test('throws exception', () async {
          final notifier = container.read(userProfileDataProvider.notifier);
          expect(
            () async => await notifier.getUserProfileData(testNpubPubkey),
            throwsException,
          );
        });
      });
    });
  });
}
