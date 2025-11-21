import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/shared/widgets/camera_permission_denied_widget.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  static Future<String?> navigate(BuildContext context) {
    return context.push<String>(Routes.qrScanner);
  }

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final Logger logger = Logger('QRScannerScreen');
  late MobileScannerController _controller;
  bool _isScanning = true;
  Timer? _cameraRestartDebouncer;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraRestartDebouncer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        unawaited(_safeStartCamera());
      case AppLifecycleState.inactive:
        unawaited(_controller.stop());
    }
  }

  Future<void> _safeStartCamera() async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        return;
      }
      if (mounted) {
        await _controller.start();
      }
    } catch (e, s) {
      logger.warning('Failed to start camera', e, s);
    }
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
                                  width: 288.w,
                                  height: 288.w,
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
                                            errorBuilder: (context, error) {
                                              if (error.errorCode ==
                                                  MobileScannerErrorCode.permissionDenied) {
                                                return const CameraPermissionDeniedWidget();
                                              }
                                              return const SizedBox();
                                            },
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
