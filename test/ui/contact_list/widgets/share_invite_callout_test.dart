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

    group('when contact has empty name and no display name', () {
      final contact = ContactModel(
        name: '',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('Invite to White Noise'), findsOneWidget);
        expect(
          find.text(
            "This user isn't on White Noise yet. Share the download link to start a secure chat.",
          ),
          findsOneWidget,
        );
      });
    });

    group('when contact has an unknown display name', () {
      final contact = ContactModel(
        name: '',
        displayName: 'Unknown User',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('Invite to White Noise'), findsOneWidget);
        expect(
          find.text(
            "This user isn't on White Noise yet. Share the download link to start a secure chat.",
          ),
          findsOneWidget,
        );
      });
    });

    group('when contact has a name and no display name', () {
      final contact = ContactModel(
        name: 'Satoshi Nakamoto',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('Invite to White Noise'), findsOneWidget);
        expect(
          find.text(
            "Satoshi Nakamoto isn't on White Noise yet. Share the download link to start a secure chat.",
          ),
          findsOneWidget,
        );
      });
    });

    group('when contact has a display name', () {
      final contact = ContactModel(
        name: 'Satoshi Nakamoto',
        displayName: 'SN',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with display name', (WidgetTester tester) async {
        await setup(tester, contact);
        expect(find.text('Invite to White Noise'), findsOneWidget);
        expect(
          find.text("SN isn't on White Noise yet. Share the download link to start a secure chat."),
          findsOneWidget,
        );
      });
    });
  });
}
