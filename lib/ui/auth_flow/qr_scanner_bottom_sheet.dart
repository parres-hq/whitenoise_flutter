import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class QRScannerBottomSheet extends StatefulWidget {
  const QRScannerBottomSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return context.push<String>('/qr-scanner');
  }

  @override
  State<QRScannerBottomSheet> createState() => _QRScannerBottomSheetState();
}

class _QRScannerBottomSheetState extends State<QRScannerBottomSheet> {
  late MobileScannerController _controller;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
        });
        context.pop(barcode.rawValue);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap(24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: WnImage(
                          AssetsPaths.icChevronLeft,
                          color: context.colors.primary,
                          size: 15.w,
                        ),
                        padding: EdgeInsets.all(4.w),
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.w,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'auth.scanQrCode'.tr(),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(),
                              Center(
                                child: Container(
                                  width: 288,
                                  height: 288,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  child:
                                      _isScanning
                                          ? MobileScanner(
                                            controller: _controller,
                                            onDetect: _onDetect,
                                          )
                                          : Container(
                                            color: context.colors.baseMuted,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  WnImage(
                                                    AssetsPaths.icCheckmarkFilled,
                                                    size: 94.w,
                                                    color: context.colors.primary,
                                                  ),
                                                  Gap(16.h),
                                                  Text(
                                                    'auth.qrCodeDetected'.tr(),
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      color: context.colors.primaryForeground,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                ),
                              ),
                              Gap(16.h),
                              Text(
                                'auth.scanYourPrivateKeyQr'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(height: 64.h),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
