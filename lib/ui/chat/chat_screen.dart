import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/notifiers/chat_notifier.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/swipe_to_reply_widget.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final User contact;
  final List<MessageModel> initialMessages;

  const ChatScreen({
    super.key,
    required this.contact,
    required this.initialMessages,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late final ChatNotifierParams _chatNotifierParams;

  @override
  void initState() {
    super.initState();

    _chatNotifierParams = ChatNotifierParams(
      contact: widget.contact,
      initialMessages: widget.initialMessages,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_chatNotifierParams));
    final chatNotifier = ref.read(chatNotifierProvider(_chatNotifierParams).notifier);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20.w,
            color: context.colors.appBarForeground,
          ),
          onPressed: () => context.pop(),
        ),
        title: ContactInfo(
          title: widget.contact.name,
          imgPath: AssetsPaths.icImage,
        ),
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
                itemCount: chatState.messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length) {
                    return ChatHeaderWidget(contact: widget.contact);
                  }

                  final message = chatState.messages[index];
                  return SwipeToReplyWidget(
                    message: message,
                    onReply: () => chatNotifier.handleReply(message),
                    onTap:
                        () => ChatDialogService.showReactionDialog(
                          context: context,
                          ref: ref,
                          message: message,
                          messageIndex: index,
                          chatNotifierParams: _chatNotifierParams,
                        ),
                    child: Hero(
                      tag: message.id,
                      child: MessageWidget(
                        message: message,
                        isGroupMessage: false,
                        isSameSenderAsPrevious: chatNotifier.isSameSender(index),
                        isSameSenderAsNext: chatNotifier.isNextSameSender(index),
                        onReactionTap: (reaction) {
                          chatNotifier.updateMessageReaction(
                            message: message,
                            reaction: reaction,
                          );
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
                currentUser: chatNotifier.currentUser,
                onSend:
                    (message, isEditing) => chatNotifier.sendNewMessageOrEdit(
                      message,
                      isEditing,
                      onMessageSent: _handleScrollToBottom,
                    ),
                padding: EdgeInsets.zero,
                replyingTo: chatState.replyingTo,
                editingMessage: chatState.editingMessage,
                onCancelReply: () => chatNotifier.cancelReply(),
                onCancelEdit: () => chatNotifier.cancelEdit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
