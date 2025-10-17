import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/user_profile_list/share_invite_bottom_sheet.dart';

import '../../test_helpers.dart';

void main() {
  group('ShareInviteBottomSheet Tests', () {
    final testUserProfile = UserProfile(
      displayName: 'Satoshi Nakamoto',
      publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
      nip05: 'satoshi@nakamoto.com',
      imagePath: 'https://example.com/satoshi.png',
    );

    testWidgets('displays userProfile display name', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      expect(find.text('Satoshi Nakamoto'), findsOneWidget);
    });

    testWidgets('displays nip05', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      expect(find.text('satoshi@nakamoto.com'), findsOneWidget);
    });

    testWidgets('displays formatted pubkey', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      expect(
        find.text(
          'abc12 3def4 56789 01234 56789 01234 56789 01234 56789 01234 56789 01234 56789 0',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows copy button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      final copyButton = find.byWidgetPredicate(
        (widget) => widget is WnImage && widget.src.contains('assets/svgs/ic_copy.svg'),
      );
      expect(copyButton, findsOneWidget);
    });

    testWidgets('displays invite callout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      expect(find.text('chats.inviteToWhiteNoise'), findsOneWidget);
      expect(find.text('chats.userNotOnWhiteNoise'), findsOneWidget);
    });

    testWidgets('displays share button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(userProfiles: [testUserProfile]),
          ),
        ),
      );

      expect(find.text('chats.share'), findsOneWidget);
    });
  });
}
