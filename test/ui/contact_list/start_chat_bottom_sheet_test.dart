import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';

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
}

class MockActiveAccountNotifier extends ActiveAccountNotifier {
  @override
  Future<ActiveAccountState> build() async {
    final mockAccount = Account(
      pubkey: 'test-pubkey',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return ActiveAccountState(account: mockAccount);
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

    final mockUser = User(
      pubkey: 'abc123def456789012345678901234567890123456789012345678901234567890',
      metadata: const FlutterMetadata(
        name: 'Satoshi Nakamoto',
        displayName: 'Satoshi Nakamoto',
        nip05: 'satoshi@nakamoto.com',
        picture: 'https://example.com/satoshi.png',
        custom: {},
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

      final copyButton = find.byType(SvgPicture);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
    });

    testWidgets('initially shows loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          StartChatBottomSheet(contact: contact),
          overrides: commonOverrides,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
        await tester.pumpAndSettle();
      }

      testWidgets('hides loading indicator', (WidgetTester tester) async {
        await setup(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays invite', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Invite to White Noise'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
      });

      testWidgets('hides add contact option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add Contact'), findsNothing);
      });

      testWidgets('hides add to group option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add to Group'), findsNothing);
      });

      testWidgets('hides start chat option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Start Chat'), findsNothing);
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
        await tester.pumpAndSettle();
      }

      testWidgets('hides loading indicator', (WidgetTester tester) async {
        await setup(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('displays add contact option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add Contact'), findsOneWidget);
      });

      testWidgets('displays add to group option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add to Group'), findsOneWidget);
      });

      testWidgets('displays start chat option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Start Chat'), findsOneWidget);
      });

      testWidgets('hides invite section', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Invite to White Noise'), findsNothing);
      });

      group('when user is already a contact', () {
        Future<void> setup(WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithPackage(),
              ),
              overrides: [
                ...commonOverrides,
                followsProvider.overrideWith(() => MockFollowsNotifier([mockUser])),
              ],
            ),
          );
          await tester.pumpAndSettle();
        }

        testWidgets('displays remove contact option', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithPackage(),
              ),
              overrides: [
                ...commonOverrides,
                followsProvider.overrideWith(() => MockFollowsNotifier([User(
                  pubkey: contact.publicKey,
                  metadata: const FlutterMetadata(custom: {}),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                )])),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Remove Contact'), findsOneWidget);
        });

        testWidgets('hides add contact option', (WidgetTester tester) async {
          await tester.pumpWidget(
            createTestWidget(
              StartChatBottomSheet(
                contact: contact,
                usersApi: MockWnUsersApiWithPackage(),
              ),
              overrides: [
                ...commonOverrides,
                followsProvider.overrideWith(() => MockFollowsNotifier([User(
                  pubkey: contact.publicKey,
                  metadata: const FlutterMetadata(custom: {}),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                )])),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Add Contact'), findsNothing);
        });

        testWidgets('hides invite section', (WidgetTester tester) async {
          await setup(tester);
          expect(find.text('Invite to White Noise'), findsNothing);
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
        await tester.pumpAndSettle();
      }

      testWidgets('hides loading indicator', (WidgetTester tester) async {
        await setup(tester);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
      testWidgets('hides add contact option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Add Contact'), findsNothing);
      });

      testWidgets('hides remove contact option', (WidgetTester tester) async {
        await setup(tester);
        expect(find.text('Remove Contact'), findsNothing);
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
