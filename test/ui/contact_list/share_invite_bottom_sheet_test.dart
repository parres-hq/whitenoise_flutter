import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';

import '../../test_helpers.dart';

void main() {
  group('ShareInviteBottomSheet Tests', () {
    final testContact = ContactModel(
      displayName: 'Satoshi Nakamoto',
      publicKey: 'abc123def456789012345678901234567890123456789012345678901234567890',
      nip05: 'satoshi@nakamoto.com',
      imagePath: 'https://example.com/satoshi.png',
    );

    testWidgets('displays contact display name', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(contacts: [testContact]),
          ),
        ),
      );

      expect(find.text('Satoshi Nakamoto'), findsOneWidget);
    });

    testWidgets('displays nip05', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(contacts: [testContact]),
          ),
        ),
      );

      expect(find.text('satoshi@nakamoto.com'), findsOneWidget);
    });

    testWidgets('displays formatted pubkey', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(contacts: [testContact]),
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
            child: ShareInviteBottomSheet(contacts: [testContact]),
          ),
        ),
      );

      final copyButton = find.byType(SvgPicture);
      expect(copyButton, findsOneWidget);
    });

    testWidgets('displays invite callout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(contacts: [testContact]),
          ),
        ),
      );

      expect(find.text('Invite to White Noise'), findsOneWidget);
      expect(
        find.textContaining(
          "Satoshi Nakamoto isn't on White Noise yet. Share the download link to start a secure chat.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays share button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SingleChildScrollView(
            child: ShareInviteBottomSheet(contacts: [testContact]),
          ),
        ),
      );

      expect(find.text('Share'), findsOneWidget);
    });
  });
}
