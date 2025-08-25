// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:whitenoise/config/providers/active_account_provider.dart';
// import 'package:whitenoise/domain/models/contact_model.dart';
// import 'package:whitenoise/domain/services/key_package_service.dart';
// import 'package:whitenoise/src/rust/api/accounts.dart';
// import 'package:whitenoise/src/rust/api/relays.dart' as relays;
// import 'package:whitenoise/src/rust/lib.dart';
// import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';

// import '../../test_helpers.dart';

// class MockContactsNotifier extends ContactsNotifier {
//   final List<ContactModel> _mockContacts;

//   MockContactsNotifier(this._mockContacts);

//   @override
//   ContactsState build() {
//     return ContactsState(
//       contactModels: _mockContacts,
//     );
//   }
// }

// class MockAccountSettings implements AccountSettings {
//   @override
//   dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
// }

// class MockActiveAccountNotifier extends ActiveAccountNotifier {
//   @override
//   String? build() {
//     return 'test-pubkey';
//   }

//   @override
//   Future<Account?> getActiveAccount() async {
//     return Account(
//       pubkey: 'test-pubkey',
//       settings: MockAccountSettings(),
//       nip65Relays: [MockRelayUrl(url: 'wss://test-relay.com')],
//       inboxRelays: [MockRelayUrl(url: 'wss://inbox-relay.com')],
//       keyPackageRelays: [MockRelayUrl(url: 'wss://keypackage-relay.com')],
//       lastSynced: BigInt.from(DateTime.now().millisecondsSinceEpoch),
//     );
//   }
// }

// class MockEvent implements relays.Event {
//   final String eventId;

//   MockEvent({required this.eventId});

//   @override
//   dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
// }

// class MockRelayUrl implements RelayUrl {
//   final String url;

//   MockRelayUrl({required this.url});

//   @override
//   dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
// }

// // Mock KeyPackageService that returns a key package (user is on White Noise)
// class MockKeyPackageServiceWithPackage extends KeyPackageService {
//   MockKeyPackageServiceWithPackage()
//     : super(
//         publicKeyString: 'test',
//         nip65Relays: [MockRelayUrl(url: 'wss://test-relay.com')],
//       );

//   @override
//   Future<relays.Event?> fetchWithRetry() async {
//     return MockEvent(eventId: 'test-key-package');
//   }
// }

// // Mock KeyPackageService that returns null (user needs invite)
// class MockKeyPackageServiceWithoutPackage extends KeyPackageService {
//   MockKeyPackageServiceWithoutPackage()
//     : super(
//         publicKeyString: 'test',
//         nip65Relays: [MockRelayUrl(url: 'wss://test-relay.com')],
//       );

//   @override
//   Future<relays.Event?> fetchWithRetry() async {
//     return null;
//   }
// }

// // Mock KeyPackageService that throws an error
// class MockKeyPackageServiceWithError extends KeyPackageService {
//   MockKeyPackageServiceWithError()
//     : super(
//         publicKeyString: 'test',
//         nip65Relays: [MockRelayUrl(url: 'wss://test-relay.com')],
//       );

//   @override
//   Future<relays.Event?> fetchWithRetry() async {
//     throw Exception('Network error');
//   }
// }

// void main() {
//   group('StartChatBottomSheet Tests', () {
//     final contact = ContactModel(
//       displayName: 'Satoshi Nakamoto',
//       publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
//       nip05: 'satoshi@nakamoto.com',
//       imagePath: 'https://example.com/satoshi.png',
//     );

//     // Common provider overrides for all tests
//     final commonOverrides = [
//       activeAccountProvider.overrideWith(() => MockActiveAccountNotifier()),
//     ];

//     testWidgets('displays user name', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         createTestWidget(
//           StartChatBottomSheet(contact: contact),
//           overrides: commonOverrides,
//         ),
//       );

//       expect(find.text('Satoshi Nakamoto'), findsOneWidget);
//     });

//     testWidgets('displays nip05', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         createTestWidget(
//           StartChatBottomSheet(contact: contact),
//           overrides: commonOverrides,
//         ),
//       );

//       expect(find.text('satoshi@nakamoto.com'), findsOneWidget);
//     });

//     testWidgets('displays formatted pubkey', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         createTestWidget(
//           StartChatBottomSheet(contact: contact),
//           overrides: commonOverrides,
//         ),
//       );

//       expect(
//         find.text(
//           'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0',
//         ),
//         findsOneWidget,
//       );
//     });

//     testWidgets('shows copy option', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         createTestWidget(
//           StartChatBottomSheet(contact: contact),
//           overrides: commonOverrides,
//         ),
//       );

//       final copyButton = find.byType(SvgPicture);
//       expect(copyButton, findsOneWidget);

//       await tester.tap(copyButton);
//     });

//     testWidgets('initially shows loading indicator', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         createTestWidget(
//           StartChatBottomSheet(contact: contact),
//           overrides: commonOverrides,
//         ),
//       );

//       expect(find.byType(CircularProgressIndicator), findsOneWidget);
//     });

//     group('without key package', () {
//       Future<void> setup(WidgetTester tester) async {
//         await tester.pumpWidget(
//           createTestWidget(
//             SingleChildScrollView(
//               child: StartChatBottomSheet(
//                 contact: contact,
//                 keyPackageService: MockKeyPackageServiceWithoutPackage(),
//               ),
//             ),
//             overrides: commonOverrides,
//           ),
//         );
//         await tester.pumpAndSettle();
//       }

//       testWidgets('hides loading indicator', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.byType(CircularProgressIndicator), findsNothing);
//       });

//       testWidgets('displays invite', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Invite to White Noise'), findsOneWidget);
//         expect(find.text('Share'), findsOneWidget);
//       });

//       testWidgets('hides add contact option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add Contact'), findsNothing);
//       });

//       testWidgets('hides add to group option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add to Group'), findsNothing);
//       });

//       testWidgets('hides start chat option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Start Chat'), findsNothing);
//       });
//     });

//     group('when contact has key package', () {
//       Future<void> setup(WidgetTester tester) async {
//         await tester.pumpWidget(
//           createTestWidget(
//             SingleChildScrollView(
//               child: StartChatBottomSheet(
//                 contact: contact,
//                 keyPackageService: MockKeyPackageServiceWithPackage(),
//               ),
//             ),
//             overrides: commonOverrides,
//           ),
//         );
//         await tester.pumpAndSettle();
//       }

//       testWidgets('hides loading indicator', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.byType(CircularProgressIndicator), findsNothing);
//       });

//       testWidgets('displays add contact option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add Contact'), findsOneWidget);
//       });

//       testWidgets('displays add to group option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add to Group'), findsOneWidget);
//       });

//       testWidgets('displays start chat option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Start Chat'), findsOneWidget);
//       });

//       testWidgets('hides invite section', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Invite to White Noise'), findsNothing);
//       });

//       group('when user is already a contact', () {
//         Future<void> setup(WidgetTester tester) async {
//           await tester.pumpWidget(
//             createTestWidget(
//               StartChatBottomSheet(
//                 contact: contact,
//                 keyPackageService: MockKeyPackageServiceWithPackage(),
//               ),
//               overrides: [
//                 ...commonOverrides,
//                 contactsProvider.overrideWith(() => MockContactsNotifier([contact])),
//               ],
//             ),
//           );
//           await tester.pumpAndSettle();
//         }

//         testWidgets('displays remove contact option', (WidgetTester tester) async {
//           await setup(tester);
//           expect(find.text('Remove Contact'), findsOneWidget);
//         });

//         testWidgets('hides add contact option', (WidgetTester tester) async {
//           await setup(tester);
//           expect(find.text('Add Contact'), findsNothing);
//         });

//         testWidgets('hides invite section', (WidgetTester tester) async {
//           await setup(tester);
//           expect(find.text('Invite to White Noise'), findsNothing);
//         });
//       });
//     });

//     group('when loading key package fails', () {
//       Future<void> setup(WidgetTester tester) async {
//         await tester.pumpWidget(
//           createTestWidget(
//             StartChatBottomSheet(
//               contact: contact,
//               keyPackageService: MockKeyPackageServiceWithError(),
//             ),
//             overrides: commonOverrides,
//           ),
//         );
//         await tester.pumpAndSettle();
//       }

//       testWidgets('hides loading indicator', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.byType(CircularProgressIndicator), findsNothing);
//       });
//       testWidgets('hides add contact option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add Contact'), findsNothing);
//       });

//       testWidgets('hides remove contact option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Remove Contact'), findsNothing);
//       });

//       testWidgets('hides start chat option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Start Chat'), findsNothing);
//         expect(find.text('Invite to White Noise'), findsNothing);
//       });

//       testWidgets('hides add to group option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Add to Group'), findsNothing);
//       });

//       testWidgets('hides invite option', (WidgetTester tester) async {
//         await setup(tester);
//         expect(find.text('Invite to White Noise'), findsNothing);
//       });
//     });
//   });
// }
