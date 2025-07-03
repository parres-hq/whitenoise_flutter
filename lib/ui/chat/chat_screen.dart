import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/swipe_to_reply_widget.dart';
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
      ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
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
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _scrollToBottomIfNeeded(List<dynamic> messages, bool isLoading) {
    if (!isLoading && messages.isNotEmpty) {
      _handleScrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final groupData = groupsNotifier.findGroupById(widget.groupId);
    final displayName =
        groupsNotifier.getGroupDisplayName(widget.groupId) ?? groupData?.name ?? 'Unknown Group';

    final chatNotifier = ref.watch(chatProvider.notifier);

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
    final messages = ref.watch(chatProvider).groupMessages[widget.groupId] ?? [];
    
    
    _scrollToBottomIfNeeded(messages, groupLoading);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => ref.read(groupsProvider.notifier).loadGroups(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body:
            groupLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        CustomAppBar.sliver(
                          floating: true,
                          pinned: true,
                          title: ContactInfo(
                            title: displayName,
                            imageUrl: '',
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
                            itemCount: messages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return ChatContactHeader(groupData: groupData);
                              }
                              final message = messages[index - 1];
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

                    if (messages.isNotEmpty)
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
          groupId: widget.groupId,
          onSend:
              (message, isEditing) => chatNotifier.sendMessage(
                groupId: widget.groupId,
                message: message,
                isEditing: isEditing,
                onMessageSent: _handleScrollToBottom,
              ),
        ),
      ),
    );
  }
}
