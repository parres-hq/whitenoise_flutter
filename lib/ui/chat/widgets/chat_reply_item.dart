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
        color: message.isMe? AppColors.grey3:  AppColors.grey4,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: BorderSide(
            color: message.isMe? AppColors.color727772: AppColors.color202320,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.originalMessage?.senderData?.name??"",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
              color: message.isMe? AppColors.color202320: AppColors.colorE2E2E2,
            ),
          ),
          Text(
            message.originalMessage?.message??"",
            maxLines: 2,
            style: TextStyle(
              color: message.isMe? AppColors.color202320: AppColors.colorE2E2E2,
              overflow: TextOverflow.ellipsis
            ),
          ),
        ],
      ),
    );
  }
}
