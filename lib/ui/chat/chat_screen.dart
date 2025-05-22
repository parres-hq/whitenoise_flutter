import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_hero_dialog_route.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reactions_dialog_widget.dart';
import 'package:whitenoise/ui/chat/widgets/status_message_item_widget.dart';

import '../../routing/routes.dart';
import '../core/themes/assets.dart';
import '../core/themes/colors.dart';

class ChatScreen extends StatefulWidget {
  final User contact;
  final List<MessageModel> initialMessages;

  const ChatScreen({super.key, required this.contact, required this.initialMessages});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<MessageModel> messages;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    messages = List.from(widget.initialMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void showEmojiBottomSheet({required MessageModel message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 0.4.sh,
          decoration: BoxDecoration(
            color: AppColors.color202320,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
          ),
          child: EmojiPicker(
            // config: Config(
            //   columns: 7,
            //   emojiSizeMax: 28.sp,
            //   bgColor: AppColors.color202320,
            //   indicatorColor: AppColors.blue1,
            //   iconColor: AppColors.colorE2E2E2,
            //   iconColorSelected: AppColors.blue1,
            //   progressIndicatorColor: AppColors.blue1,
            //   backspaceColor: AppColors.blue1,
            //   skinToneDialogBgColor: AppColors.color202320,
            //   skinToneIndicatorColor: AppColors.colorE2E2E2,
            //   enableSkinTones: true,
            //   recentsLimit: 28,
            //   replaceEmojiOnLimitExceed: false,
            //   noRecents: Text(
            //     'No Recents',
            //     style: TextStyle(
            //       fontSize: 14.sp,
            //       color: AppColors.colorE2E2E2),
            //   ),
            //   tabIndicatorAnimDuration: kTabScrollDuration,
            //   categoryIcons: const CategoryIcons(),
            //   buttonMode: ButtonMode.MATERIAL,
            // ),
            onEmojiSelected: ((category, emoji) {
              Navigator.pop(context);
              addReactionToMessage(message: message, reaction: emoji.emoji);
            }),
          ),
        );
      },
    );
  }

  void addReactionToMessage({required MessageModel message, required String reaction}) {
    setState(() {
      message.reactions.add(
        Reaction(
          emoji: reaction,
          user: User(id: 'current_user_id', name: 'You', email: 'current@user.com', publicKey: 'current_public_key'),
        ),
      );
    });
  }

  void sendNewMessage(MessageModel newMessage) {
    setState(() {
      messages.insert(0, newMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isSameSender(int index) {
    if (index <= 0 || index >= messages.length) return false;
    return messages[index].sender.id == messages[index - 1].sender.id;
  }

  bool _isNextSameSender(int index) {
    if (index < 0 || index >= messages.length - 1) return false;
    return messages[index].sender.id == messages[index + 1].sender.id;
  }

  @override
  Widget build(BuildContext context) {
    print(messages);
    return Scaffold(
      backgroundColor: AppColors.colorF9F9F9,
      appBar: AppBar(
        backgroundColor: AppColors.color202320,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.w, color: AppColors.colorE2E2E2),
          onPressed: () => context.pop(),
        ),
        title: ContactInfo(
          title: widget.contact.name,
          // subtitle: widget.contact.username ?? widget.contact.email,
          imgPath: widget.contact.imagePath ?? AssetsPaths.icImage,
        ),
        actions: [
          IconButton(
            icon: Icon(CarbonIcons.search, size: 20.w, color: AppColors.colorE2E2E2),
            onPressed: () => context.go(Routes.newChat),
          ),
          Gap(8.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return _buildHeaderInfo();
                  }

                  final message = messages[index];
                  return GestureDetector(
                    onLongPress: () => _showReactionDialog(message, index),
                    child: Hero(
                      tag: message.id,
                      child: MessageWidget(
                        message: message,
                        isGroupMessage: false,
                        isSameSenderAsPrevious: _isSameSender(index),
                        isSameSenderAsNext: _isNextSameSender(index),
                        // onReact: (reaction) {
                        //   if (reaction == '⋯') {
                        //     showEmojiBottomSheet(message: message);
                        //   } else {
                        //     addReactionToMessage(message: message, reaction: reaction);
                        //   }
                        // },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: ChatInput(
                currentUser: User(
                  id: 'current_user_id',
                  name: 'You',
                  email: 'current@user.com',
                  publicKey: 'current_public_key',
                ),
                onSend: sendNewMessage,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionDialog(MessageModel message, int index) {
    Navigator.of(context).push(
      HeroDialogRoute(
        builder: (context) {
          return ReactionsDialogWidget(
            id: message.id,
            menuItems: message.isMe ? DefaultData.myMessageMenuItems : DefaultData.menuItems,
            messageWidget: MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: _isSameSender(index),
              isSameSenderAsNext: _isNextSameSender(index),
            ),
            onReactionTap: (reaction) {
              if (reaction == '⋯') {
                showEmojiBottomSheet(message: message);
              } else {
                addReactionToMessage(message: message, reaction: reaction);
              }
            },
            onContextMenuTap: (menuItem) {
              // Handle context menu actions
            },
            widgetAlignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Gap(40.h),
          CircleAvatar(
            radius: 40.r,
            // backgroundImage: CachedNetworkImageProvider(
            //   widget.contact.imagePath ?? AssetsPaths.icImage,
            // ),
            backgroundImage: AssetImage(AssetsPaths.icImage),
          ),
          Gap(12.h),
          Text(
            widget.contact.name,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: AppColors.color202320),
          ),
          Gap(4.h),
          Text(widget.contact.email, style: TextStyle(fontSize: 14.sp, color: AppColors.grey2)),
          Gap(12.h),
          Text(
            'Public Key: ${widget.contact.publicKey.substring(0, 8)}...',
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey2),
          ),
          Gap(24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'All messages are end-to-end encrypted. Only you and ${widget.contact.name} can read them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.color727772),
            ),
          ),
          Gap(24.h),
          StatusMessageItemWidget(
            icon: CarbonIcons.checkmark,
            // iconColor: AppColors.blue1,
            highlightedContent: widget.contact.name,
            content: " accepted the invite",
          ),
          Gap(12.h),
          StatusMessageItemWidget(
            icon: Icons.lock,
            highlightedContent: widget.contact.name,
            // iconColor: AppColors.green1,
            content: "End-to-end encrypted",
          ),
          Gap(40.h),
        ],
      ),
    );
  }
}
