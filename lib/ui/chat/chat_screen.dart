import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
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
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
      ref.read(chatProvider.notifier).loadMessagesForGroup(widget.groupId);
      _handleScrollToBottom();
    });

    ref.listenManual(chatProvider, (previous, next) {
      final currentMessages = next.groupMessages[widget.groupId] ?? [];
      final previousMessages = previous?.groupMessages[widget.groupId] ?? [];

      if (currentMessages.length != previousMessages.length) {
        _handleScrollToBottom();
      }
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

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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

    final messages = ref.watch(
      chatProvider.select((state) => state.groupMessages[widget.groupId] ?? []),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollUpdateNotification) {
                final currentFocus = FocusManager.instance.primaryFocus;
                if (currentFocus != null && currentFocus.hasFocus) {
                  final currentOffset = scrollInfo.metrics.pixels;
                  final scrollDelta = currentOffset - _lastScrollOffset;

                  if (scrollDelta < -20) {
                    currentFocus.unfocus();
                  }
                  _lastScrollOffset = currentOffset;
                }
              }
              return false;
            },
            child: GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping in empty space
                FocusManager.instance.primaryFocus?.unfocus();
              },
              behavior: HitTestBehavior.translucent,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  CustomAppBar.sliver(
                    floating: true,
                    pinned: true,
                    title: ContactInfo(
                      title: displayName,
                      imageUrl: '',
                      onTap:
                          () => context.push(
                            '/chats/${widget.groupId}/info',
                          ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ).copyWith(
                      bottom: 120.h,
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
                          onReply: () => chatNotifier.handleReply(message, groupId: widget.groupId),
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
                                )
                                .animate()
                                .fadeIn(
                                  duration: const Duration(milliseconds: 200),
                                )
                                .slide(
                                  begin: const Offset(0, 0.1),
                                  duration: const Duration(milliseconds: 200),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
        onInputFocused: _handleScrollToBottom,
        onSend: (message, isEditing) async {
          final chatState = ref.read(chatProvider);
          final replyingTo = chatState.replyingTo[widget.groupId];

          if (replyingTo != null) {
            await chatNotifier.sendReplyMessage(
              groupId: widget.groupId,
              replyToMessageId: replyingTo.id,
              message: message,
              onMessageSent: _handleScrollToBottom,
            );
          } else {
            await chatNotifier.sendMessage(
              groupId: widget.groupId,
              message: message,
              isEditing: isEditing,
              onMessageSent: _handleScrollToBottom,
            );
          }
        },
      ),
    );
  }
}
