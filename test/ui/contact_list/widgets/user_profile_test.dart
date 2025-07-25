import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/contact_list/widgets/user_profile.dart';
import '../../../test_helpers.dart';

// Test wrapper widget that provides real WidgetRef
class UserProfileTestWrapper extends ConsumerWidget {
  final String name;
  final String nip05;
  final String pubkey;
  final String imageUrl;

  const UserProfileTestWrapper({
    super.key,
    required this.name,
    this.nip05 = '',
    required this.pubkey,
    this.imageUrl = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UserProfile(
      name: name,
      nip05: nip05,
      pubkey: pubkey,
      imageUrl: imageUrl,
      ref: ref,
    );
  }
}

void main() {
  group('UserProfile Widget Tests', () {
    
    testWidgets('displays user name correctly', (WidgetTester tester) async {
      const userName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      await tester.pumpWidget(createTestWidget(
        const UserProfileTestWrapper(
          name: userName,
          pubkey: pubkey,
        ),
      ));

      expect(find.text(userName), findsOneWidget);
    });

    testWidgets('displays NIP-05 when provided', (WidgetTester tester) async {
      const userName = 'John Doe';
      const nip05 = 'john@example.com';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      await tester.pumpWidget(createTestWidget(
        const UserProfileTestWrapper(
          name: userName,
          nip05: nip05,
          pubkey: pubkey,
        ),
      ));

      expect(find.text(nip05), findsOneWidget);
    });

    testWidgets('displays formatted public key', (WidgetTester tester) async {
      const userName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';
      const expectedFormattedKey = 'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0';

      await tester.pumpWidget(createTestWidget(
        const UserProfileTestWrapper(
          name: userName,
          pubkey: pubkey,
        ),
      ));

      expect(find.text(expectedFormattedKey), findsOneWidget);
    });

    testWidgets('copies pubkey to clipboard', (WidgetTester tester) async {
      const userName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      // Set up clipboard mocking
      final clipboardData = setupClipboardMock(tester);

      await tester.pumpWidget(createTestWidget(
        const UserProfileTestWrapper(
          name: userName,
          pubkey: pubkey,
        ),
      ));

      final copyButton = find.byIcon(CarbonIcons.copy);
      expect(copyButton, findsOneWidget);
      
      await tester.tap(copyButton);
      expect(clipboardData['text'], equals(pubkey));
    });
  });
} 
