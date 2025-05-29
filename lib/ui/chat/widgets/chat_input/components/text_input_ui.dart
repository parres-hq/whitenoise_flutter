import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class TextInputUI extends StatelessWidget {
  const TextInputUI({
    super.key,
    required this.message,
    required this.onMessageChanged,
    required this.focusNode,
    required this.showEmojiPicker,
    required this.hasContent,
    required this.enableAudio,
    required this.enableImages,
    required this.isRecording,
    required this.mediaSelector,
    required this.cursorColor,
    required this.onPickImages,
    required this.onSendMessage,
    required this.onToggleEmojiPicker,
    required this.onStartRecording,
    required this.onTakePhoto,
    this.onAttachmentPressed,
  });

  final String message;
  final ValueChanged<String> onMessageChanged;
  final FocusNode focusNode;
  final bool showEmojiPicker;
  final bool hasContent;
  final bool enableAudio;
  final bool enableImages;
  final bool isRecording;
  final Widget? mediaSelector;
  final Color? cursorColor;
  final VoidCallback onPickImages;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleEmojiPicker;
  final VoidCallback onStartRecording;
  final VoidCallback onTakePhoto;
  final VoidCallback? onAttachmentPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (mediaSelector != null || enableImages)
          mediaSelector ??
              IconButton(
                padding: EdgeInsets.all(1.sp),
                icon: Icon(CarbonIcons.add, size: 28.w, color: AppColors.glitch500),
                onPressed: onAttachmentPressed ?? onPickImages,
                splashRadius: 0.1,
              ),

        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppColors.glitch100),
            child: TextField(
              controller: TextEditingController(text: message)
                ..selection = TextSelection.collapsed(offset: message.length),
              onChanged: onMessageChanged,
              focusNode: focusNode,
              onTap: () {
                if (showEmojiPicker) {
                  onToggleEmojiPicker();
                }
              },
              cursorColor: cursorColor ?? AppColors.glitch500,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.glitch500),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
              ),
              style: TextStyle(fontSize: 14.sp, color: AppColors.glitch700),
            ),
          ),
        ),

        if (hasContent)
          IconButton(
            icon: Icon(CarbonIcons.send, size: 24.w, color: AppColors.glitch500),
            onPressed: onSendMessage,
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  showEmojiPicker ? CarbonIcons.text_scale : CarbonIcons.flash,
                  size: 24.w,
                  color: AppColors.glitch500,
                ),
                onPressed: onToggleEmojiPicker,
                padding: EdgeInsets.zero,
              ),

              if (enableImages)
                IconButton(
                  icon: Icon(CarbonIcons.camera, size: 24.w, color: AppColors.glitch500),
                  onPressed: onTakePhoto,
                  padding: EdgeInsets.zero,
                ),

              if (enableAudio)
                IconButton(
                  icon: Icon(
                    CarbonIcons.microphone,
                    size: 24.w,
                    color: isRecording ? Theme.of(context).colorScheme.error : AppColors.glitch500,
                  ),
                  onPressed: onStartRecording,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
      ],
    );
  }
}
