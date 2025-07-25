import 'package:flutter_test/flutter_test.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import '../../test_helpers.dart';

class MockContactsNotifier extends ContactsNotifier {
  final List<ContactModel> _mockContacts;

  MockContactsNotifier(this._mockContacts);

  @override
  ContactsState build() {
    return ContactsState(
      contactModels: _mockContacts,
    );
  }
}

void main() {
  group('StartChatBottomSheet Tests', () {
    const testName = 'Satoshi Nakamoto';
    const testNip05 = 'satoshi@nakamoto.com';
    const testImagePath = 'https://example.com/satoshi.png';
    const testPubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

    testWidgets('displays user name', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          imagePath: testImagePath,
          pubkey: testPubkey,
        ),
      ));
      
      expect(find.text('Satoshi Nakamoto'), findsOneWidget);
    });

    testWidgets('displays nip05', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          imagePath: testImagePath,
          pubkey: testPubkey,
        ),
      ));
      
      expect(find.text('satoshi@nakamoto.com'), findsOneWidget);
    });

    testWidgets('displays formatted pubkey', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          imagePath: testImagePath,
          pubkey: testPubkey,
        ),
      ));
      
      expect(find.text(
        'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0'
      ), findsOneWidget);
    });

    testWidgets('allows copying npub to clipboard', (WidgetTester tester) async {
      final clipboardData = setupClipboardMock(tester);

      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          pubkey: testPubkey,
        ),
      ));

      final copyButton = find.byIcon(CarbonIcons.copy);
      expect(copyButton, findsOneWidget);
      
      await tester.tap(copyButton);
    
      expect(clipboardData['text'], equals(
        'abc123def456789012345678901234567890123456789012345678901234567890'
      ));
    });

    testWidgets('displays add contact button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          pubkey: testPubkey,
        ),
      ));
      expect(find.text('Add Contact'), findsOneWidget);
    });

     testWidgets('displays add to group button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          pubkey: testPubkey,
        ),
      ));
      expect(find.text('Add to Group'), findsOneWidget);
    });

    testWidgets('displays start chat button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        const StartChatBottomSheet(
          name: testName,
          nip05: testNip05,
          pubkey: testPubkey,
        ),
      ));
      expect(find.text('Start Chat'), findsOneWidget);
    });

    group('when user is already a contact', () {
      testWidgets('displays remove contact button', (WidgetTester tester) async {
        final existingContact = ContactModel(
          name: testName,
          publicKey: testPubkey,
          nip05: testNip05,
          imagePath: testImagePath,
        );

        await tester.pumpWidget(createTestWidget(
          const StartChatBottomSheet(
            name: testName,
            nip05: testNip05,
            pubkey: testPubkey,
          ),
          additionalOverrides: [
            contactsProvider.overrideWith(() => MockContactsNotifier([existingContact])),
          ],
        ));
        
        expect(find.text('Remove Contact'), findsOneWidget);
        expect(find.text('Add Contact'), findsNothing);
      });
    });
  });
} 
