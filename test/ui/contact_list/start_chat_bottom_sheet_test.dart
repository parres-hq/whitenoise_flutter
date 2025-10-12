import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

import '../../test_helpers.dart';

class MockFollowsNotifier extends FollowsNotifier {
  final List<User> _mockFollows;

  MockFollowsNotifier(this._mockFollows);

  @override
  FollowsState build() {
    return FollowsState(
      follows: _mockFollows,
    );
  }

  @override
  bool isFollowing(String pubkey) {
    return _mockFollows.any((user) => user.pubkey == pubkey);
  }
}

class MockActiveAccountNotifier extends ActiveAccountNotifier {
  @override
  Future<ActiveAccountState> build() {
    final mockAccount = Account(
      pubkey: 'test-pubkey',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Future.value(ActiveAccountState(account: mockAccount));
  }
}

// Mock WnUsersApi that returns true (user has key package)
class MockWnUsersApiWithPackage implements WnUsersApi {
  @override
  Future<bool> userHasKeyPackage({required String pubkey}) async {
    return true;
  }
}

// Mock WnUsersApi that returns false (user needs invite)
class MockWnUsersApiWithoutPackage implements WnUsersApi {
  @override
  Future<bool> userHasKeyPackage({required String pubkey}) async {
    return false;
  }
}

// Mock WnUsersApi that throws an error
class MockWnUsersApiWithError implements WnUsersApi {
  @override
  Future<bool> userHasKeyPackage({required String pubkey}) async {
    throw Exception('Network error');
  }
}

void main() {
  group('StartChatBottomSheet Tests', () {
    final contact = ContactModel(
      displayName: 'Satoshi Nakamoto',
      publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
      nip05: 'satoshi@nakamoto.com',
      imagePath: 'https://example.com/satoshi.png',
    );

    // Common provider overrides for all tests
    final commonOverrides = [
      activeAccountProvider.overrideWith(() => MockActiveAccountNotifier()),
    ];

    testWidgets('displays user name', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      expect(find.text('Satoshi Nakamoto'), findsOneWidget);
    });

    testWidgets('displays nip05', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      expect(find.text('satoshi@nakamoto.com'), findsOneWidget);
    });

    testWidgets('displays formatted pubkey', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      expect(
        find.text(
          'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows copy option', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      final copyButton = find.byType(WnImage);
      expect(copyButton, findsWidgets);

      await tester.tap(copyButton.first);
    });

    testWidgets('initially shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
    });

    group('without key package', () {
      Future<void> setup(WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            SingleChildScrollView(
              child: StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithoutPackage(),
              ),
            ),
            overrides: commonOverrides,
          ),
        );
        await tester.pump();
      }

      testWidgets('displays invite', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.share'), findsOneWidget);
      });

      testWidgets('hides follow option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.follow'), findsNothing);
      });

      testWidgets('hides add to group option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.addToGroup'), findsNothing);
      });

      testWidgets('hides start chat option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.startChat'), findsNothing);
      });
    });

    group('when contact has key package', () {
      Future<void> setup(WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            SingleChildScrollView(
              child: StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithPackage(),
              ),
            ),
            overrides: commonOverrides,
          ),
        );
        await tester.pump();
      }

      testWidgets('displays follow option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.follow'), findsOneWidget);
      });

      testWidgets('displays add to group option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.addToGroup'), findsOneWidget);
      });

      testWidgets('hides unfollow option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.unfollow'), findsNothing);
      });

      testWidgets('displays start chat option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('ui.startChat'), findsOneWidget);
      });

      testWidgets('hides invite section', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('chats.inviteToWhiteNoise'), findsNothing);
      });

      group('when user is already a follow', () {
        Future<void> setup(WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithPackage(),
              ),
              overrides: [
                ...commonOverrides,
                followsProvider.overrideWith(
                  () => MockFollowsNotifier([
                    User(
                      pubkey: contact.publicKey,
                      metadata: const FlutterMetadata(custom: {}),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  ]),
                ),
              ],
            ),
          );
          await tester.pump();
        }

        testWidgets('displays unfollow option', (WidgetTester tester) async {
          await setup(tester);
          expect(find.text('ui.unfollow'), findsOneWidget);
        });

        testWidgets('hides follow option', (WidgetTester tester) async {
          await setup(tester);
          expect(find.text('ui.follow'), findsNothing);
        });

        testWidgets('hides invite section', (WidgetTester tester) async {
          await setup(tester);
          expect(find.text('chats.inviteToWhiteNoise'), findsNothing);
        });
      });
    });

    group('when loading key package fails', () {
      Future<void> setup(WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            StartChatBottomSheet(
              contact: contact,
              usersApi: MockWnUsersApiWithError(),
            ),
            overrides: commonOverrides,
          ),
        );
        await tester.pump();
      }

      testWidgets('hides follow option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Follow'), findsNothing);
      });

      testWidgets('hides unfollow option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Unfollow'), findsNothing);
      });

      testWidgets('hides start chat option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Start Chat'), findsNothing);
        expect(find.text('Invite to White Noise'), findsNothing);
      });

      testWidgets('hides add to group option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add to Group'), findsNothing);
      });

      testWidgets('hides invite option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Invite to White Noise'), findsNothing);
      });
    });
  });
}
