import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

/// A reusable wrapper for settings screens that provides consistent layout:
/// - AnnotatedRegion for status bar styling
/// - Scaffold with neutral background
/// - WnAppBar with back button and title
/// - SafeArea with ColoredBox body
class WnSettingsScreenWrapper extends StatelessWidget {
  const WnSettingsScreenWrapper({
    required this.title,
    required this.body,
    this.onBackPressed,
    this.safeAreaBottom = true,
    super.key,
  });

  /// The title to display in the app bar (can be String or Widget)
  final dynamic title;

  /// The main content of the screen (replaces ColoredBox's child)
  final Widget body;

  /// Optional custom back button handler. Defaults to context.pop()
  final VoidCallback? onBackPressed;

  /// Whether to apply SafeArea to the bottom. Defaults to true
  final bool safeAreaBottom;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.neutral,
        appBar: WnAppBar(
          automaticallyImplyLeading: false,
          leading: RepaintBoundary(
            child: IconButton(
              onPressed: onBackPressed ?? () => context.pop(),
              icon: WnImage(
                AssetsPaths.icChevronLeft,
                size: 15.w,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
          title: RepaintBoundary(
            child: title is String
                ? Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.solidPrimary,
                    ),
                  )
                : title as Widget,
          ),
        ),
        body: SafeArea(
          bottom: safeAreaBottom,
          child: ColoredBox(
            color: context.colors.neutral,
            child: body,
          ),
        ),
      ),
    );
  }
}
