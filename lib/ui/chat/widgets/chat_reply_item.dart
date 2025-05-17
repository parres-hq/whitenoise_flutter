import 'package:flutter/material.dart';
import 'package:whitenoise/domain/models/message_model.dart';

import '../../core/themes/colors.dart';

class ChatReplyItem extends StatelessWidget {
  MessageModel message;
  ChatReplyItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(3),
        border: Border(
          left: BorderSide(
            color: AppColors.color727772,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.originalMessage!.senderData!.name,
            style: TextStyle(
              color: AppColors.color202320,
            ),
          ),
          Text(
            message.originalMessage!.message??"",
            style: TextStyle(
              color: AppColors.color727772,
            ),
          ),
        ],
      ),
    );
  }
}
