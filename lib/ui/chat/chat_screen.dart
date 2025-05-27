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
import 'package:flutter/services.dart';

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
  final currentUser = User(
    id: 'current_user_id',
    name: 'You',
    email: 'current@user.com',
    publicKey: 'current_public_key',
  );

  MessageModel? _replyingTo;
  MessageModel? _editingMessage;

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

  void _showEmojiBottomSheet({required MessageModel message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 0.4.sh,
          decoration: BoxDecoration(
            color: AppColors.glitch50,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
          ),
          child: EmojiPicker(
            config: Config(bottomActionBarConfig: BottomActionBarConfig(enabled: false)),
            onEmojiSelected: ((category, emoji) {
              Navigator.pop(context);
              _updateMessageReaction(message: message, reaction: emoji.emoji);
            }),
          ),
        );
      },
    );
  }

  void _updateMessageReaction({required MessageModel message, required String reaction}) {
    setState(() {
      final existingReactionIndex = message.reactions.indexWhere(
        (r) => r.emoji == reaction && r.user.id == currentUser.id,
      );

      if (existingReactionIndex != -1) {
        // Remove reaction if user already reacted with same emoji
        final newReactions = List<Reaction>.from(message.reactions)..removeAt(existingReactionIndex);
        messages = _updateMessage(message.copyWith(reactions: newReactions));
      } else {
        // Add new reaction
        final newReaction = Reaction(emoji: reaction, user: currentUser);
        final newReactions = List<Reaction>.from(message.reactions)..add(newReaction);
        messages = _updateMessage(message.copyWith(reactions: newReactions));
      }
    });
  }

  void _sendNewMessage(MessageModel newMessage) {
    setState(() {
      messages.insert(0, newMessage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null;
    });
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  void _cancelEdit() {
    setState(() => _editingMessage = null);
  }

  List<MessageModel> _updateMessage(MessageModel updatedMessage) {
    return messages.map((msg) {
      return msg.id == updatedMessage.id ? updatedMessage : msg;
    }).toList();
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
    // Ensure status bar has light icons on this dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // for Android
        statusBarBrightness: Brightness.dark, // for iOS
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.glitch50,
      appBar: AppBar(
        backgroundColor: AppColors.glitch950,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.w, color: AppColors.glitch50),
          onPressed: () => context.pop(),
        ),
        title: ContactInfo(title: widget.contact.name, imgPath: AssetsPaths.icImage),
        actions: [
          IconButton(
            icon: Icon(CarbonIcons.search, size: 20.w, color: AppColors.glitch50),
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
                        onReactionTap: (reaction) {
                          _updateMessageReaction(message: message, reaction: reaction);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: ChatInput(
                currentUser: currentUser,
                onSend: _sendNewMessage,
                padding: EdgeInsets.zero,
                replyingTo: _replyingTo,
                editingMessage: _editingMessage,
                onCancelReply: _cancelReply,
                onCancelEdit: _cancelEdit,
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
                _showEmojiBottomSheet(message: message);
              } else {
                _updateMessageReaction(message: message, reaction: reaction);
              }
            },
            onContextMenuTap: (menuItem) {
              if (menuItem.label == 'Reply') {
                _handleReply(message);
              }
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
          Gap(60.h),
          CircleAvatar(radius: 40.r, backgroundImage: AssetImage(AssetsPaths.icImage)),
          Gap(12.h),
          Text(
            widget.contact.name,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: AppColors.glitch950),
          ),
          Gap(12.h),
          Text(widget.contact.email, style: TextStyle(fontSize: 14.sp, color: AppColors.glitch600)),
          Gap(8.h),
          Text(
            'Public Key: ${widget.contact.publicKey.substring(0, 8)}...',
            style: TextStyle(fontSize: 12.sp, color: AppColors.glitch600),
          ),
          Gap(24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'All messages are end-to-end encrypted. Only you and ${widget.contact.name} can read them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: AppColors.glitch600),
            ),
          ),
          Gap(24.h),
          StatusMessageItemWidget(
            icon: CarbonIcons.email,
            content: 'Chat invite sent to ${widget.contact.name}',
            boldText: widget.contact.name,
          ),
          Gap(12.h),
          StatusMessageItemWidget(
            icon: CarbonIcons.checkmark,
            content: '${widget.contact.name} accepted the invite',
            boldText: widget.contact.name,
          ),
          Gap(40.h),
        ],
      ),
    );
  }
}
