import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/share_invite_callout.dart';
import '../../../test_helpers.dart';

void main() {
  group('ShareInviteCallout Tests', () {
    Future<void> setup(WidgetTester tester, ContactModel contact) async {
      await tester.pumpWidget(
        createTestWidget(ShareInviteCallout(contact: contact)),
      );
    }

    group('when contact has empty display name', () {
      final contact = ContactModel(
        displayName: '',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });

    group('when contact has an unknown display name', () {
      final contact = ContactModel(
        displayName: 'Unknown User',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });
    group('when contact has a display name', () {
      final contact = ContactModel(
        displayName: 'Satoshi Nakamoto',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with display name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });
  });
}
