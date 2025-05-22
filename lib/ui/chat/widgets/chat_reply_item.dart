import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/message_model.dart';

import '../../core/themes/colors.dart';

class ChatReplyItem extends StatelessWidget {
  final MessageModel message;
  const ChatReplyItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: message.isMe ? AppColors.glitch400 : AppColors.glitch800,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: BorderSide(
            color: message.isMe ? AppColors.glitch600 : AppColors.glitch950,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.originalMessage?.senderData?.name ?? "",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
              color: message.isMe ? AppColors.glitch950 : AppColors.glitch200,
            ),
          ),
          Text(
            message.originalMessage?.message ?? "",
            maxLines: 2,
            style: TextStyle(
              color: message.isMe ? AppColors.glitch950 : AppColors.glitch200,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
