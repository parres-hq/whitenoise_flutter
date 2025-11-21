import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/ui/auth_flow/qr_scanner_screen.dart';
import 'package:whitenoise/ui/shared/widgets/camera_permission_denied_widget.dart';

import '../../test_helpers.dart';

void main() {
  group('QRScannerScreen Tests', () {
    testWidgets('creates successfully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(
        createTestWidget(const QRScannerScreen()),
      );

      expect(find.byType(QRScannerScreen), findsOneWidget);
      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('displays permission denied UI when error occurs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1920));
      await tester.pumpWidget(
        createTestWidget(const QRScannerScreen()),
      );

      final mobileScannerFinder = find.byType(MobileScanner);
      expect(mobileScannerFinder, findsOneWidget);

      final mobileScanner = tester.widget<MobileScanner>(mobileScannerFinder);

      expect(mobileScanner.errorBuilder, isNotNull);

      final context = tester.element(mobileScannerFinder);

      final errorWidget = mobileScanner.errorBuilder!(
        context,
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );

      expect(errorWidget, isA<CameraPermissionDeniedWidget>());
    });
  });
}
