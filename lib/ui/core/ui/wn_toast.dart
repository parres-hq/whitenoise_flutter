import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnToastOverlay extends ConsumerWidget {
  const WnToastOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toastState = ref.watch(toastMessageProvider);

    if (toastState.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Separate toasts based on their position preference
    final belowAppBarToasts = toastState.messages.where((msg) => msg.showBelowAppBar).toList();
    final topToasts = toastState.messages.where((msg) => !msg.showBelowAppBar).toList();

    return Stack(
      children: [
        if (topToasts.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  topToasts.map((message) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: WnToastMessageWidget(
                        key: ValueKey(message.id),
                        message: message,
                      ),
                    );
                  }).toList(),
            ),
          ),

        if (belowAppBarToasts.isNotEmpty)
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 8.h,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  belowAppBarToasts.map((message) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: WnToastMessageWidget(
                        key: ValueKey(message.id),
                        message: message,
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }
}

class WnToastMessageWidget extends ConsumerStatefulWidget {
  final ToastMessage message;

  const WnToastMessageWidget({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<WnToastMessageWidget> createState() => _WnToastMessageWidgetState();
}

class _WnToastMessageWidgetState extends ConsumerState<WnToastMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (widget.message.type) {
      case ToastType.success:
        return context.colors.toastSuccess;
      case ToastType.error:
        return context.colors.toastError;
      case ToastType.warning:
        return context.colors.toastWarning;
      case ToastType.info:
        return context.colors.primary;
    }
  }

  String _getIconPath() {
    switch (widget.message.type) {
      case ToastType.success:
        return AssetsPaths.icSuccessFilled;
      case ToastType.error:
        return AssetsPaths.icErrorFilled;
      case ToastType.warning:
        return AssetsPaths.icWarningFilled;
      case ToastType.info:
        return AssetsPaths.icInfoFilled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: ValueKey(widget.message.id),
          onDismissed: (_) {
            ref.read(toastMessageProvider.notifier).dismissToast(widget.message.id);
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: context.colors.toastSurface,
                border: Border(
                  bottom: BorderSide(
                    color: _getBackgroundColor(context),
                    width: 1.h,
                  ),
                ),
              ),
              child: Row(
                children: [
                  WnImage(
                    _getIconPath(),
                    size: 20.w,
                    color: _getBackgroundColor(context),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      widget.message.message,
                      style: TextStyle(
                        color: context.colors.toastIcon,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap:
                        () =>
                            ref.read(toastMessageProvider.notifier).dismissToast(widget.message.id),
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.w, top: 8.w, bottom: 8.w),
                      child: WnImage(
                        AssetsPaths.icClose,
                        size: 20.w,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WnToast extends ConsumerWidget {
  final Widget child;

  const WnToast({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          const WnToastOverlay(),
        ],
      ),
    );
  }
}
