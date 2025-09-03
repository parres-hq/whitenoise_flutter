import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/ui/settings/profile/share_profile_qr_scan_screen.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

import '../../../test_helpers.dart';

// Mock classes for testing QR scanning functionality
class MockBarcode implements Barcode {
  final String? mockRawValue;

  MockBarcode({this.mockRawValue});

  @override
  String? get rawValue => mockRawValue;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBarcodeCapture implements BarcodeCapture {
  @override
  final List<Barcode> barcodes;

  MockBarcodeCapture({required this.barcodes});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ShareProfileQrScanScreen Tests', () {
    group('Widget Creation', () {
      testWidgets('creates successfully with default parameters', (tester) async {
        expect(
          () => const ShareProfileQrScanScreen(),
          returnsNormally,
        );
      });

      testWidgets('creates successfully with hideViewQrButton true', (tester) async {
        expect(
          () => const ShareProfileQrScanScreen(hideViewQrButton: true),
          returnsNormally,
        );
      });

      testWidgets('creates successfully with hideViewQrButton false', (tester) async {
        expect(
          () => const ShareProfileQrScanScreen(),
          returnsNormally,
        );
      });
    });

    group('Widget Properties', () {
      testWidgets('has correct hideViewQrButton property', (tester) async {
        const widget1 = ShareProfileQrScanScreen(hideViewQrButton: true);
        const widget2 = ShareProfileQrScanScreen();
        const widget3 = ShareProfileQrScanScreen();

        expect(widget1.hideViewQrButton, isTrue);
        expect(widget2.hideViewQrButton, isFalse);
        expect(widget3.hideViewQrButton, isFalse); // default value
      });

      testWidgets('extends ConsumerStatefulWidget correctly', (tester) async {
        const widget = ShareProfileQrScanScreen();
        expect(widget, isA<ConsumerStatefulWidget>());
      });
    });

    group('Widget Rendering (Basic)', () {
      testWidgets('renders without throwing exceptions', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);
      });

      testWidgets('contains expected widgets', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.byType(MobileScanner), findsOneWidget);
        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('shows View QR Code button when hideViewQrButton is false', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.text('View QR Code'), findsOneWidget);
      });

      testWidgets('hides View QR Code button when hideViewQrButton is true', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen(hideViewQrButton: true)),
        );

        expect(find.text('View QR Code'), findsNothing);
      });
    });

    group('Text Elements', () {
      testWidgets('displays correct title text', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.text('Scan QR Code'), findsOneWidget);
      });

      testWidgets('displays correct instruction text', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.text('Scan user\'s QR code to connect.'), findsOneWidget);
      });
    });

    group('Navigation Elements', () {
      testWidgets('contains back button', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        expect(find.byType(BackButton), findsOneWidget);
      });

      testWidgets('back button is tappable', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));

        await tester.pumpWidget(
          const MaterialApp(
            home: ShareProfileQrScanScreen(),
          ),
        );

        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);

        await tester.tap(backButton);
        await tester.pumpAndSettle();
      });
    });

    group('State Management', () {
      testWidgets('widget maintains state correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        final state = tester.state(find.byType(ShareProfileQrScanScreen));
        expect(state, isNotNull);
      });
    });

    group('QR Scanning Functionality', () {
      testWidgets('initializes MobileScannerController correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Verify the MobileScanner widget is present and configured
        final mobileScannerFinder = find.byType(MobileScanner);
        expect(mobileScannerFinder, findsOneWidget);

        // Verify the widget creates and maintains its state
        final state = tester.state(find.byType(ShareProfileQrScanScreen));
        expect(state, isNotNull);
      });

      testWidgets('implements WidgetsBindingObserver correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test that the widget handles lifecycle events
        // This is primarily testing that the observer is registered without crashing
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);

        // Simulate app lifecycle changes by pumping the widget
        await tester.pumpAndSettle();
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);
      });

      testWidgets('handles widget disposal correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));

        // Create and mount the widget
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Verify initial state
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);

        // Dispose the widget by replacing it with something else
        await tester.pumpWidget(
          createTestWidget(const Text('Replaced')),
        );
        await tester.pumpAndSettle();

        // Verify widget is disposed and replaced
        expect(find.byType(ShareProfileQrScanScreen), findsNothing);
        expect(find.text('Replaced'), findsOneWidget);
      });

      testWidgets('QR scanner container has proper constraints', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Find the scanner container
        final containerFinder = find.ancestor(
          of: find.byType(MobileScanner),
          matching: find.byType(Container),
        );

        expect(containerFinder, findsOneWidget);

        // Verify the container is wrapped in proper responsive widgets
        expect(find.byType(AspectRatio), findsOneWidget);
        expect(find.byType(Center), findsWidgets);
      });

      testWidgets('maintains scanner state during widget updates', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));

        // Create initial widget
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);

        // Update the widget with new parameters
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen(hideViewQrButton: true)),
        );
        await tester.pumpAndSettle();

        // Verify the widget updated correctly
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);
        expect(find.text('View QR Code'), findsNothing);
      });

      testWidgets('scanner formats configuration', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // The scanner should be configured for QR codes
        // We can't directly access the controller, but we can verify
        // the MobileScanner widget is present and configured
        expect(find.byType(MobileScanner), findsOneWidget);

        // Get the actual MobileScanner widget
        final mobileScannerWidget = tester.widget<MobileScanner>(
          find.byType(MobileScanner),
        );

        // Verify it has a controller
        expect(mobileScannerWidget.controller, isNotNull);
      });

      testWidgets('handles different screen sizes appropriately', (tester) async {
        // Test with small screen
        await tester.binding.setSurfaceSize(const Size(320, 568));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);

        // Test with large screen
        await tester.binding.setSurfaceSize(const Size(414, 896));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);

        // Test with tablet size
        await tester.binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );
        expect(find.byType(ShareProfileQrScanScreen), findsOneWidget);
      });

      testWidgets('accessibility features work correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Verify key elements have proper semantics
        expect(find.byType(BackButton), findsOneWidget);
        expect(find.text('Scan QR Code'), findsOneWidget);
        expect(find.text('Scan user\'s QR code to connect.'), findsOneWidget);

        // Verify tappable elements
        final backButton = find.byType(BackButton);
        expect(backButton, findsOneWidget);

        // Test that back button responds to tap
        await tester.tap(backButton, warnIfMissed: false);
        await tester.pumpAndSettle();
      });
    });

    group('Npub (Nostr Public Key) Validation & Usage', () {
      testWidgets('validates valid npub formats correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test valid npub formats (just needs to start with 'npub1' and be > 10 chars)
        const validNpubs = [
          'npub1yx5dwahlw3sql3t7h7qrr0xrx5k3cf44rjfq3fvs37lhk8yq0dnq7z5zqh',
          'npub1234567890abc', // 15 chars, > 10 so valid
          'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqd4wm8k',
          'npub1abcdefghijk', // any chars after npub1, > 10 total
        ];

        for (final validNpub in validNpubs) {
          expect(validNpub.isValidPublicKey, isTrue,
              reason: '$validNpub should be a valid public key');
        }
      });

      testWidgets('validates hex public keys correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test valid hex formats (exactly 64 hex characters)
        const validHexKeys = [
          '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef', // 64 hex chars
          'ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890', // uppercase hex
          '0000000000000000000000000000000000000000000000000000000000000000', // all zeros
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', // all f's
        ];

        for (final hexKey in validHexKeys) {
          expect(hexKey.isValidPublicKey, isTrue,
              reason: '$hexKey should be a valid hex public key');
          expect(hexKey.isValidHexPublicKey, isTrue,
              reason: '$hexKey should be valid hex specifically');
        }
      });

      testWidgets('rejects invalid public key formats correctly', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test invalid formats
        const invalidKeys = [
          'invalid',
          '123',
          'npub123', // only 7 chars, <= 10 so invalid
          'npub1', // only 5 chars, <= 10 so invalid
          'not_a_key',
          '', // empty
          'nsec1234567890abc', // starts with nsec not npub
          '123456789012345678901234567890123456789012345678901234567890123', // 63 hex chars, not 64
          '12345678901234567890123456789012345678901234567890123456789012345', // 65 hex chars, not 64
          '1234567890abcdefg123456789012345678901234567890123456789012345678', // contains 'g', not valid hex
        ];

        for (final invalidKey in invalidKeys) {
          expect(invalidKey.isValidPublicKey, isFalse,
              reason: '$invalidKey should be an invalid public key');
        }
      });

      testWidgets('handles edge cases in validation', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test edge cases
        const edgeCases = [
          'npub1', // exactly 5 chars, <= 10 so invalid
          'npub123456', // exactly 10 chars, <= 10 so invalid  
          'npub1234567', // exactly 11 chars, > 10 so valid
          'npub', // prefix without content
          ' npub1234567890abc', // leading space - will be trimmed, then valid
          'npub1234567890abc ', // trailing space - will be trimmed, then valid
        ];

        expect(edgeCases[0].isValidPublicKey, isFalse); // npub1 (5 chars)
        expect(edgeCases[1].isValidPublicKey, isFalse); // npub123456 (10 chars)
        expect(edgeCases[2].isValidPublicKey, isTrue);  // npub1234567 (11 chars)
        expect(edgeCases[3].isValidPublicKey, isFalse); // npub (4 chars)
        expect(edgeCases[4].isValidPublicKey, isTrue);  // leading space (trimmed)
        expect(edgeCases[5].isValidPublicKey, isTrue);  // trailing space (trimmed)
      });

      testWidgets('tests different public key types', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        const hexKey = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
        const npubKey = 'npub1234567890abcdef';

        expect(hexKey.publicKeyType, equals(PublicKeyType.hex));
        expect(npubKey.publicKeyType, equals(PublicKeyType.npub));
        expect('invalid'.publicKeyType, isNull);

        expect(hexKey.isValidHexPublicKey, isTrue);
        expect(hexKey.isValidNpubPublicKey, isFalse);

        expect(npubKey.isValidHexPublicKey, isFalse);
        expect(npubKey.isValidNpubPublicKey, isTrue);
      });

      testWidgets('tests validation performance', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Generate test cases
        final testCases = <String>[];
        
        // Add valid npub cases
        for (int i = 0; i < 10; i++) {
          testCases.add('npub1${'a' * 20}'); // Valid npub format
        }
        
        // Add valid hex cases  
        for (int i = 0; i < 10; i++) {
          testCases.add('a' * 64); // Valid hex format
        }
        
        // Add invalid cases
        for (int i = 0; i < 10; i++) {
          testCases.add('invalid$i'); // Invalid format
        }

        final stopwatch = Stopwatch()..start();
        
        for (final testCase in testCases) {
          final isValid = testCase.isValidPublicKey;
          final keyType = testCase.publicKeyType;
          // Just accessing the properties to test performance
          expect(isValid, isA<bool>());
          expect(keyType, isA<PublicKeyType?>());
        }
        
        stopwatch.stop();
        
        // Validation should be very fast (less than 50ms for 30 validations)
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Public key validation should be performant');
      });

      testWidgets('tests real-world npub scenarios', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 812));
        await tester.pumpWidget(
          createTestWidget(const ShareProfileQrScanScreen()),
        );

        // Test realistic but safe npub examples
        const scenarios = [
          'npub1testkey12345678901234567890', // test key
          'npub1abcdef123456789012345678901234567890123456789012345678901234', // long valid
          'npub1short123', // short but valid (> 10 chars)
        ];

        for (final scenario in scenarios) {
          expect(scenario.isValidPublicKey, isTrue,
              reason: '$scenario should be valid npub');
          expect(scenario.startsWith('npub1'), isTrue,
              reason: '$scenario should start with npub1');
          expect(scenario.length, greaterThan(10),
              reason: '$scenario should be longer than 10 characters');
        }
      });
    });
  });
}
