import 'package:cached_network_image/cached_network_image.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/dummy_data/dummy_messages.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/stacked_reactions.dart';
import '../../core/themes/colors.dart';
import 'chat_audio_item.dart';
import 'chat_reply_item.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.messageIndex
  });

  final MessageModel message;
  final bool isGroupMessage;
  final int messageIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: MediaQuery.of(context).size.width * 0.3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            isGroupMessage?
              message.isMe==false && message.senderData!=null
                && (messageIndex==0 || (messageIndex>0 && groupMessages[messageIndex-1].senderData!.name != message.senderData!.name))?
            Container(
              margin: EdgeInsets.only(bottom: 20, right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: message.senderData!.imagePath,
                  fit: BoxFit.cover,
                  width: 30,
                  height: 30,
                ),
              ),
            ): Container(width: 30,margin: EdgeInsets.only(bottom: 20, right: 10),) :SizedBox(),
            Expanded(
              child: Align(
                alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Stack(
                  children: [
                    // message
                    buildMessage(
                      context,
                    ),
                    //reactions
                    buildReactions(
                      message.isMe,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // reactions widget
  Widget buildReactions(bool isMe) {
    double bottomPadding = isGroupMessage==true && messageIndex>0 && groupMessages[messageIndex-1].senderData!.name == message.senderData!.name? message.reactions.isEmpty? 10 : 0: 10;
    return isMe
        ? Positioned(
      bottom: bottomPadding,
      left: 40,
      child: StackedReactions(
        reactions: message.reactions,
      ),
    )
        : Positioned(
      bottom:  bottomPadding,
      right: 40,
      child: StackedReactions(
        reactions: message.reactions,
      ),
    );
  }


  // message widget
  Widget buildMessage(
      BuildContext context,
      ) {
    double bottomPadding = isGroupMessage==true && messageIndex>0 && groupMessages[messageIndex-1].senderData!.name == message.senderData!.name? message.reactions.isEmpty? 3 : 15:25;
    //bottomPadding=message.reactions.isEmpty? messageIndex==0 || (messageIndex>0 && groupMessages[messageIndex-1].senderData!.name == message.senderData!.name)? 0 : ;

    // padding for the message card
    final padding= message.isMe? EdgeInsets.only(top: 0, left: 30.0, bottom: bottomPadding)
        :  EdgeInsets.only(top: 0, right: 30.0, bottom: bottomPadding);
    // border radius for the message card
    final borderRadius = message.isMe
        ? const BorderRadius.only(
      topLeft: Radius.circular(7),
      topRight: Radius.circular(7),
      bottomLeft: Radius.circular(7),
    )
        : const BorderRadius.only(
      topLeft: Radius.circular(7),
      topRight: Radius.circular(7),
      bottomRight: Radius.circular(7),
    );
    // car color
    final cardColor = message.isMe
        ? AppColors.color202320
        : AppColors.colorE2E2E2;

    // text color
    final textColor = message.isMe
        ? AppColors.colorE2E2E2
        : AppColors.color202320;
    return Padding(
      padding: padding,
      child: Card(
        margin: EdgeInsets.all(0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                isGroupMessage==true &&
                  message.isMe==false && message.senderData!=null
                    && (messageIndex==0 || (messageIndex<groupMessages.length-1 && groupMessages[messageIndex+1].senderData!.name != message.senderData!.name))?
                Container(
                  margin: EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.senderData!.name??"",
                    style: TextStyle(
                      color: AppColors.red1,
                    ),
                  ),
                ):SizedBox(),
                message.imageUrl != null?
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl??"",
                      placeholder: (context, url) => SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Icon(Icons.broken_image),
                      fit: BoxFit.fill,
                     // height: 150,
                    ),
                  ),
                ): SizedBox(),
                message.isReplyMessage==true?
                ChatReplyItem(message: message,): SizedBox(),
                ( message.imageUrl != null || message.isReplyMessage==true) && message.messageType==0 && message.message != null && message.message!.isNotEmpty?
                Gap(5): Gap(0),
                message.messageType==0?
                Wrap(
                  alignment:  message.isMe? WrapAlignment.end: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    message.message != null && message.message!.isNotEmpty?
                    Text(
                      message.message??"",
                      style: TextStyle(
                        color: textColor,
                      ),
                    ):SizedBox(),
                    Gap(5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        message.message!=null && message.message!.isNotEmpty?Gap(10):Gap(0),
                        Text(
                          message.timeSent,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        message.isMe
                            ? const Icon(
                          CarbonIcons.checkmark_outline,
                          color: AppColors.colorE2E2E2,
                          size: 15,
                        )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ):
                Wrap(
                  alignment:  message.isMe? WrapAlignment.end: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    message.audioPath != null?
                    ChatAudioItem(audioPath: message.audioPath??""): SizedBox(),
                    Gap(5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.timeSent,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        message.isMe
                            ? const Icon(
                          CarbonIcons.checkmark_outline,
                          color: AppColors.colorE2E2E2,
                          size: 15,
                        )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}