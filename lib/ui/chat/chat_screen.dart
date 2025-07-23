import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/invite/chat_invite_screen.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/contact_info.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/swipe_to_reply_widget.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? inviteId;

  const ChatScreen({
    super.key,
    required this.groupId,
    this.inviteId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;
  Future<DMChatData?>? _dmChatDataFuture;

  @override
  void initState() {
    super.initState();
    _initializeDMChatData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.inviteId == null) {
        ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
        ref.read(chatProvider.notifier).loadMessagesForGroup(widget.groupId);
        _handleScrollToBottom();
      }
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
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _initializeDMChatData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeDMChatData() {
    final groupsNotifier = ref.read(groupsProvider.notifier);
    final groupData = groupsNotifier.findGroupById(widget.groupId);
    if (groupData != null) {
      _dmChatDataFuture = ref.getDMChatData(groupData.mlsGroupId);
    }
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

  void _scrollToMessage(String messageId) {
    final messages = ref.read(
      chatProvider.select((state) => state.groupMessages[widget.groupId] ?? []),
    );
    final messageIndex = messages.indexWhere((msg) => msg.id == messageId);

    if (messageIndex != -1 && _scrollController.hasClients) {
      final targetIndex = messageIndex + 1;

      final totalItems = messages.length + 1;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      final approximateItemHeight = maxScrollExtent / totalItems;
      final targetPosition = targetIndex * approximateItemHeight;

      final clampedPosition = targetPosition.clamp(0.0, maxScrollExtent);

      _scrollController.animateTo(
        clampedPosition,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);

    final isInviteMode = widget.inviteId != null;

    if (isInviteMode) {
      return ChatInviteScreen(
        groupId: widget.groupId,
        inviteId: widget.inviteId!,
      );
    }

    // Normal chat mode - get group info from groups provider
    final groupData = groupsNotifier.findGroupById(widget.groupId);

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
      body: NotificationListener<ScrollNotification>(
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
            FocusManager.instance.primaryFocus?.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Expanded(
                flex: 100,
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        WnAppBar.sliver(
                          floating: true,
                          pinned: true,
                          title: FutureBuilder(
                            future: _dmChatDataFuture,
                            builder: (context, asyncSnapshot) {
                              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                                return const ContactInfo.loading();
                              }

                              final otherUser = asyncSnapshot.data;
                              return ContactInfo(
                                title:
                                    groupData.groupType == GroupType.directMessage
                                        ? otherUser?.displayName ?? ''
                                        : groupData.name,
                                image:
                                    groupData.groupType == GroupType.directMessage
                                        ? otherUser?.displayImage ?? ''
                                        // TODO : use group image when avaialabe
                                        : '',
                                onTap: () => context.push('/chats/${widget.groupId}/info'),
                              );
                            },
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
                                onReply:
                                    () => chatNotifier.handleReply(
                                      message,
                                      groupId: widget.groupId,
                                    ),
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
                                        isSameSenderAsPrevious: chatNotifier.isSameSender(
                                          index,
                                          groupId: widget.groupId,
                                        ),
                                        isSameSenderAsNext: chatNotifier.isSameSender(
                                          index - 1,
                                          groupId: widget.groupId,
                                        ),
                                        onReactionTap: (reaction) {
                                          chatNotifier.updateMessageReaction(
                                            message: message,
                                            reaction: reaction,
                                          );
                                        },
                                        onReplyTap: (messageId) {
                                          _scrollToMessage(messageId);
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

                    if (messages.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 20.h,
                        child: const WnBottomFade().animate().fadeIn(),
                      ),
                  ],
                ),
              ),
              ChatInput(
                groupId: widget.groupId,

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
            ],
          ),
        ),
      ),
    );
  }
}
