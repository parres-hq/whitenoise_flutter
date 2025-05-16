import 'package:cached_network_image/cached_network_image.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/widgets/stacked_reactions.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import '../../core/themes/colors.dart';
import 'chat_audio_item.dart';
import 'chat_reply_item.dart';

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.message,
  });

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
          minWidth: MediaQuery.of(context).size.width * 0.3,
        ),
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
    );
  }

  // reactions widget
  Widget buildReactions(bool isMe) {
    return isMe
        ? Positioned(
      bottom: 4,
      right: 20,
      child: StackedReactions(
        reactions: message.reactions,
      ),
    )
        : Positioned(
      bottom: 4,
      left: 8,
      child: StackedReactions(
        reactions: message.reactions,
      ),
    );
  }

  // message widget
  Widget buildMessage(
      BuildContext context,
      ) {
    // padding for the message card
    final padding = message.reactions.isNotEmpty
        ? message.isMe
        ? const EdgeInsets.only(left: 30.0, bottom: 25.0)
        : const EdgeInsets.only(right: 30.0, bottom: 25.0)
        : message.isMe? const EdgeInsets.only(bottom: 0.0, left: 30.0): const EdgeInsets.only(bottom: 0.0, right: 30.0);
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: message.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                message.imageUrl != null?
                Center(
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl??"",
                    placeholder: (context, url) => SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.broken_image),
                    fit: BoxFit.fill,
                   // height: 150,
                  ),
                ): SizedBox(),
                message.isReplyMessage==true?
                ChatReplyItem(message: message,): SizedBox(),
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