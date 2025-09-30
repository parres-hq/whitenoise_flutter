// TODO - Better msg navigation between word matches

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/models/dm_chat_data.dart';
import 'package:whitenoise/domain/services/dm_chat_service.dart';
import 'package:whitenoise/domain/services/last_read_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/invite/chat_invite_screen.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/chat_search_widget.dart';
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

class _ChatScreenState extends ConsumerState<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;
  Future<DMChatData?>? _dmChatDataFuture;
  ProviderSubscription<ChatState>? _chatSubscription;
  bool _hasInitialScrollCompleted = false;
  bool _isKeyboardOpen = false;
  bool _hasMarkedLastReadAtBottom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeDMChatData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.inviteId == null) {
        ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
        ref.read(chatProvider.notifier).loadMessagesForGroup(widget.groupId);
      }
    });

    // Listen for chat state changes to handle auto-scroll
    _chatSubscription = ref.listenManual(chatProvider, (previous, next) {
      _handleChatStateChange(previous, next);
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _hasInitialScrollCompleted = false; // Reset for new chat
      _initializeDMChatData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatSubscription?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeDMChatData() {
    final groupsNotifier = ref.read(groupsProvider.notifier);
    final group = groupsNotifier.findGroupById(widget.groupId);
    if (group != null) {
      _dmChatDataFuture = ref.getDMChatData(group.mlsGroupId);
    }
  }

  /// Scroll to the bottom of the chat
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || !mounted) return;

      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      if (animated) {
        _scrollController.animateTo(
          maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(maxScrollExtent);
      }
      LastReadService.setLastRead(groupId: widget.groupId);
    });
  }

  /// Handle keyboard visibility changes
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final keyboardHeight =
        bottomInset / WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    // Simple keyboard state tracking
    if (keyboardHeight > 100) {
      // Keyboard is open
      if (!_isKeyboardOpen) {
        _isKeyboardOpen = true;
        // Scroll to bottom when keyboard opens (with delay)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isKeyboardOpen) {
            _scrollToBottom();
          }
        });
      }
    } else {
      // Keyboard is closed
      _isKeyboardOpen = false;
    }
  }

  /// Handle chat state changes for auto-scroll
  void _handleChatStateChange(ChatState? previous, ChatState next) {
    final currentMessages = next.groupMessages[widget.groupId] ?? [];
    final previousMessages = previous?.groupMessages[widget.groupId] ?? [];
    final wasLoading = previous?.isGroupLoading(widget.groupId) ?? false;
    final isLoading = next.isGroupLoading(widget.groupId);
    final isLoadingCompleted = wasLoading && !isLoading;

    // Auto-scroll when chat first loads
    if (isLoadingCompleted && currentMessages.isNotEmpty && !_hasInitialScrollCompleted) {
      _hasInitialScrollCompleted = true;
      _scrollToBottom(animated: false);
      LastReadService.setLastRead(groupId: widget.groupId);
      return;
    }

    // Auto-scroll when new messages arrive (after initial load)
    if (_hasInitialScrollCompleted &&
        previousMessages.isNotEmpty &&
        currentMessages.length > previousMessages.length &&
        currentMessages.last.id != previousMessages.last.id) {
      _scrollToBottom();
    }
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
      final viewportHeight = _scrollController.position.viewportDimension;
      final approximateItemHeight = maxScrollExtent / totalItems;
      final targetPosition = targetIndex * approximateItemHeight;
      final searchWidgetHeight = 120.h;
      final centeredPosition = targetPosition - (viewportHeight / 2) + searchWidgetHeight;
      final clampedPosition = centeredPosition.clamp(0.0, maxScrollExtent);

      _scrollController.animateTo(
        clampedPosition,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  SearchMatch? _getMessageSearchMatch(List<SearchMatch> matches, String messageId) {
    final messageMatches = matches.where((match) => match.messageId == messageId).toList();
    if (messageMatches.isEmpty) return null;

    final allTextMatches = <TextMatch>[];
    for (final match in messageMatches) {
      allTextMatches.addAll(match.textMatches);
    }

    return SearchMatch(
      messageId: messageId,
      messageIndex: messageMatches.first.messageIndex,
      messageContent: messageMatches.first.messageContent,
      textMatches: allTextMatches,
    );
  }

  void activateSearch() {
    final searchNotifier = ref.read(chatSearchProvider(widget.groupId).notifier);
    searchNotifier.activateSearch();
  }

  @override
  Widget build(BuildContext context) {
    final groupsNotifier = ref.watch(groupsProvider.notifier);
    final chatNotifier = ref.watch(chatProvider.notifier);
    final searchState = ref.watch(chatSearchProvider(widget.groupId));
    final searchNotifier = ref.read(chatSearchProvider(widget.groupId).notifier);
    final isInviteMode = widget.inviteId != null;

    // Watch messages first so they're available for listeners
    final messages = ref.watch(
      chatProvider.select((state) => state.groupMessages[widget.groupId] ?? []),
    );

    // Move ref.listen calls to the main build method
    ref.listen(chatSearchProvider(widget.groupId), (previous, next) {
      if (next.query.isNotEmpty && next.query != previous?.query) {
        searchNotifier.performSearchWithMessages(next.query, messages);
      }
    });

    ref.listen(chatSearchProvider(widget.groupId).select((state) => state.currentMatchIndex), (
      previous,
      next,
    ) {
      final currentMatch = searchNotifier.currentMatch;
      if (currentMatch != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToMessage(currentMatch.messageId);
        });
      }
    });

    if (isInviteMode) {
      return ChatInviteScreen(
        groupId: widget.groupId,
        inviteId: widget.inviteId!,
      );
    }

    final group = groupsNotifier.findGroupById(widget.groupId);

    if (group == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    return FutureBuilder<GroupType>(
      future: groupsNotifier.getGroupTypeById(widget.groupId),
      builder: (context, groupTypeSnapshot) {
        if (!groupTypeSnapshot.hasData) {
          return Scaffold(
            backgroundColor: context.colors.neutral,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final groupType = groupTypeSnapshot.data!;

        return PopScope(
          onPopInvokedWithResult: (_, _) {
            if (searchState.isSearchActive) {
              searchNotifier.deactivateSearch();
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is ScrollUpdateNotification) {
                  final currentFocus = FocusManager.instance.primaryFocus;
                  if (currentFocus != null && currentFocus.hasFocus && !_isKeyboardOpen) {
                    final currentOffset = scrollInfo.metrics.pixels;
                    final scrollDelta = currentOffset - _lastScrollOffset;
                    if (scrollDelta < -20) currentFocus.unfocus();
                    _lastScrollOffset = currentOffset;
                  }

                  final maxScrollExtent = scrollInfo.metrics.maxScrollExtent;
                  final currentPixels = scrollInfo.metrics.pixels;
                  final isAtBottom = currentPixels >= maxScrollExtent - 50;

                  if (isAtBottom) {
                    if (!_hasMarkedLastReadAtBottom) {
                      _hasMarkedLastReadAtBottom = true;
                      LastReadService.setLastRead(groupId: widget.groupId);
                    }
                  } else {
                    _hasMarkedLastReadAtBottom = false;
                  }
                }
                return false;
              },
              child: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    if (searchState.isSearchActive)
                      ChatSearchWidget(
                        groupId: widget.groupId,
                        onClose: searchNotifier.deactivateSearch,
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              if (!searchState.isSearchActive)
                                WnAppBar.sliver(
                                  floating: true,
                                  pinned: true,
                                  title: FutureBuilder(
                                    future: _dmChatDataFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const ContactInfo.loading();
                                      }
                                      final otherUser = snapshot.data;
                                      return ContactInfo(
                                        title:
                                            groupType == GroupType.directMessage
                                                ? otherUser?.displayName ?? ''
                                                : group.name,
                                        image:
                                            groupType == GroupType.directMessage
                                                ? otherUser?.displayImage ?? ''
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
                                ).copyWith(bottom: 120.h),
                                sliver: SliverList.builder(
                                  itemCount: messages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ChatContactHeader(group: group);
                                    }
                                    final int messageIndex = index - 1;
                                    final message = messages[messageIndex];

                                    return SwipeToReplyWidget(
                                      message: message,
                                      onReply:
                                          () => chatNotifier.handleReply(
                                            message,
                                            groupId: widget.groupId,
                                          ),
                                      onLongPress:
                                          () => ChatDialogService.showReactionDialog(
                                            context: context,
                                            ref: ref,
                                            message: message,
                                            messageIndex: messageIndex,
                                          ),
                                      child: Hero(
                                        tag: message.id,
                                        child: MessageWidget(
                                              message: message,
                                              isGroupMessage: groupType == GroupType.group,
                                              isSameSenderAsPrevious: chatNotifier.isSameSender(
                                                messageIndex,
                                                groupId: widget.groupId,
                                              ),
                                              isSameSenderAsNext:
                                                  messageIndex + 1 < messages.length &&
                                                  chatNotifier.isSameSender(
                                                    messageIndex + 1,
                                                    groupId: widget.groupId,
                                                  ),
                                              searchMatch:
                                                  searchState.matches.isNotEmpty
                                                      ? _getMessageSearchMatch(
                                                        searchState.matches,
                                                        message.id,
                                                      )
                                                      : null,
                                              isActiveSearchMatch:
                                                  searchNotifier.currentMatch?.messageId ==
                                                  message.id,
                                              currentActiveMatch:
                                                  searchNotifier.currentMatch?.messageId ==
                                                          message.id
                                                      ? searchNotifier.currentMatch
                                                      : null,
                                              isSearchActive: searchState.isSearchActive,
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
                                            .fadeIn(duration: const Duration(milliseconds: 200))
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
                    if (!searchState.isSearchActive)
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
                            );
                          } else {
                            await chatNotifier.sendMessage(
                              groupId: widget.groupId,
                              message: message,
                              isEditing: isEditing,
                            );
                          }
                          // Auto-scroll after sending message
                          _scrollToBottom();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
