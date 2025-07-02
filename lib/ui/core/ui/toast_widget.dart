import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ToastOverlay extends ConsumerWidget {
  const ToastOverlay({super.key});

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
        // Toasts at the very top of screen with safe area
        if (topToasts.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16.h,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  topToasts.map((message) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: ToastMessageWidget(
                        key: ValueKey(message.id),
                        message: message,
                      ),
                    );
                  }).toList(),
            ),
          ),

        // Toasts below the app bar (original position)
        if (belowAppBarToasts.isNotEmpty)
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 16.h,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  belowAppBarToasts.map((message) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: ToastMessageWidget(
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

class ToastMessageWidget extends ConsumerStatefulWidget {
  final ToastMessage message;

  const ToastMessageWidget({
    super.key,
    required this.message,
  });

  @override
  ConsumerState<ToastMessageWidget> createState() => _ToastMessageWidgetState();
}

class _ToastMessageWidgetState extends ConsumerState<ToastMessageWidget>
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
        return context.colors.teal200;
      case ToastType.error:
        return context.colors.destructive;
      case ToastType.warning:
        return context.colors.warning;
      case ToastType.info:
        return context.colors.primary;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (widget.message.type) {
      case ToastType.success:
        return context.colors.teal600;
      case ToastType.error:
      case ToastType.warning:
      case ToastType.info:
        return context.colors.neutral;
    }
  }

  IconData _getIcon() {
    switch (widget.message.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
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
          child: Container(
            width: double.infinity,
            height: 72.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _getBackgroundColor(context),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getTextColor(context),
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    widget.message.message,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
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

class ToastWrapper extends ConsumerWidget {
  final Widget child;

  const ToastWrapper({
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
          const ToastOverlay(),
        ],
      ),
    );
  }
}
