import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/notifiers/chat_notifier.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/swipe_to_reply_widget.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ChatScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
      ref.read(chatNotifierProvider.notifier).initialize();
      ref.read(chatProvider.notifier).loadMessagesForGroup(widget.groupId);
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
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsNotifier = ref.read(groupsProvider.notifier);
    final groupData = groupsNotifier.findGroupById(widget.groupId);
    final displayName =
        groupsNotifier.getGroupDisplayName(widget.groupId) ?? groupData?.name ?? 'Unknown Group';
    final chatState = ref.watch(chatNotifierProvider);
    final chatNotifier = ref.read(chatNotifierProvider.notifier);

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    if (groupData == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    final groupLoading = ref.watch(chatProvider).groupLoadingStates[widget.groupId] ?? false;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              CustomAppBar.sliver(
                floating: true,
                pinned: true,
                title: ContactInfo(
                  title: displayName,
                  imgPath: AssetsPaths.icImage,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ).copyWith(
                  bottom: 200.h,
                ),
                sliver: SliverList.builder(
                  itemCount: chatState.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChatContactHeader(groupData: groupData);
                    }
                    final message = chatState.messages[index - 1];
                    return SwipeToReplyWidget(
                      message: message,
                      onReply: () => chatNotifier.handleReply(message),
                      onTap:
                          () => ChatDialogService.showReactionDialog(
                            context: context,
                            ref: ref,
                            message: message,
                            messageIndex: index,
                          ),
                      child: Hero(
                        tag: message.id,
                        child: MessageWidget(
                          message: message,
                          isGroupMessage: groupData.groupType == GroupType.group,
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
            ],
          ),

          if (chatState.messages.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: isKeyboardOpen ? 100.h : 150.h,
              child: const BottomFade().animate().fadeIn(),
            ),
        ],
      ),
      bottomSheet: ChatInput(
        onSend:
            (message, isEditing) => chatNotifier.sendNewMessageOrEdit(
              message,
              isEditing: isEditing,
              groupId: widget.groupId,
              onMessageSent: _handleScrollToBottom,
            ),
      ),
    );
  }
}
