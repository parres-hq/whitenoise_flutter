import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
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
      const displayName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      await tester.pumpWidget(
        createTestWidget(
          const UserProfileTestWrapper(
            name: displayName,
            pubkey: pubkey,
          ),
        ),
      );

      expect(find.text(displayName), findsOneWidget);
    });

    testWidgets('displays NIP-05 when provided', (WidgetTester tester) async {
      const displayName = 'John Doe';
      const nip05 = 'john@example.com';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      await tester.pumpWidget(
        createTestWidget(
          const UserProfileTestWrapper(
            name: displayName,
            nip05: nip05,
            pubkey: pubkey,
          ),
        ),
      );

      expect(find.text(nip05), findsOneWidget);
    });

    testWidgets('displays formatted public key', (WidgetTester tester) async {
      const displayName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';
      const expectedFormattedKey =
          'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0';

      await tester.pumpWidget(
        createTestWidget(
          const UserProfileTestWrapper(
            name: displayName,
            pubkey: pubkey,
          ),
        ),
      );

      expect(find.text(expectedFormattedKey), findsOneWidget);
    });

    testWidgets('shows copy button', (WidgetTester tester) async {
      const displayName = 'John Doe';
      const pubkey = 'abc123def456789012345678901234567890123456789012345678901234567890';

      await tester.pumpWidget(
        createTestWidget(
          const UserProfileTestWrapper(
            name: displayName,
            pubkey: pubkey,
          ),
        ),
      );

      final copyButton = find.byType(SvgPicture);
      expect(copyButton, findsOneWidget);
    });
  });
}
