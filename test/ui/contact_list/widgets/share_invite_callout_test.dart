import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/user_profile_list/widgets/share_invite_callout.dart';
import '../../../test_helpers.dart';

void main() {
  group('ShareInviteCallout Tests', () {
    Future<void> setup(WidgetTester tester, UserProfile userProfile) async {
      await tester.pumpWidget(
        createTestWidget(ShareInviteCallout(userProfile: userProfile)),
      );
    }

    group('when userProfile has empty display name', () {
      final userProfile = UserProfile(
        displayName: '',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, userProfile);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });

    group('when userProfile has an unknown display name', () {
      final userProfile = UserProfile(
        displayName: 'Unknown User',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with generic name', (WidgetTester tester) async {
        await setup(tester, userProfile);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });
    group('when userProfile has a display name', () {
      final userProfile = UserProfile(
        displayName: 'Satoshi Nakamoto',
        publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
        nip05: 'satoshi@nakamoto.com',
        imagePath: 'https://example.com/satoshi.png',
      );
      testWidgets('shows invite with display name', (WidgetTester tester) async {
        await setup(tester, userProfile);
        expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
        expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
      });
    });
  });
}
