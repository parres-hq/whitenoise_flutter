import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class TextMessage extends StatelessWidget {
  final MessageModel message;
  static const int _minLengthForPadding = 32;

  const TextMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;
    final content = message.content ?? '';
    final needsPadding = content.length < _minLengthForPadding;
    final double padding = message.isMe ? 58.w : 46.w;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 4.h,
        right: needsPadding ? padding : 0,
      ),
      child: Container(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14.sp,
            color: textColor,
            decoration: TextDecoration.none,
            fontFamily: 'OverusedGrotesk',
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
