import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';

class ChatInputSendButton extends StatefulWidget {
  const ChatInputSendButton({
    super.key,
    required this.textController,
    required this.singleLineHeight,
    required this.onSend,
    this.hasImages = false,
  });

  final TextEditingController textController;
  final double? singleLineHeight;
  final VoidCallback onSend;
  final bool hasImages;

  @override
  State<ChatInputSendButton> createState() => ChatInputSendButtonState();
}

class ChatInputSendButtonState extends State<ChatInputSendButton> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatInputSendButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_onTextChanged);
      widget.textController.addListener(_onTextChanged);
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.textController.text.isNotEmpty || widget.hasImages;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child:
          hasContent
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gap(4.w),
                  WnIconButton(
                        iconPath: AssetsPaths.icArrowUp,
                        padding: 14.w,
                        size: widget.singleLineHeight ?? 44.h,
                        onTap: widget.onSend,
                        buttonColor: context.colors.primary,
                        iconColor: context.colors.primaryForeground,
                      )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 200),
                      )
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                      ),
                ],
              )
              : const SizedBox.shrink(),
    );
  }
}
