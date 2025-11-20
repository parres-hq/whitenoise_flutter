// TODO - Better msg navigation between word matches

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
import 'package:whitenoise/config/providers/chat_input_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/services/displayed_chat_service.dart';
import 'package:whitenoise/domain/services/last_read_manager.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/chat/invite/chat_invite_screen.dart';
import 'package:whitenoise/ui/chat/services/chat_dialog_service.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/chat_search_widget.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/swipe_to_reply_widget.dart';
import 'package:whitenoise/ui/chat/widgets/user_profile_info.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
  static final _logger = Logger('ChatScreen');
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;
  ProviderSubscription<ChatState>? _chatSubscription;
  bool _hasInitialScrollCompleted = false;
  bool _isKeyboardOpen = false;
  bool _hasScheduledInitialScroll = false;

  static const double _scrollBottomThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Clear notifications for this chat when entering
    _clearNotificationsForChat();

    // Add scroll listener for last read saving
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DisplayedChatService.registerDisplayedChat(widget.groupId);
      if (widget.inviteId == null) {
        ref.read(groupsProvider.notifier).loadGroupDetails(widget.groupId);
        ref.read(chatProvider.notifier).loadMessagesForGroup(widget.groupId);
        _preloadMemberColors();
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
      // Unregister old chat and register new one
      DisplayedChatService.unregisterDisplayedChat(oldWidget.groupId);
      DisplayedChatService.registerDisplayedChat(widget.groupId);
      _hasInitialScrollCompleted = false; // Reset for new chat
      _hasScheduledInitialScroll = false; // Reset scheduling flag
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatSubscription?.close();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Cancel pending last read saves for this group
    DisplayedChatService.unregisterDisplayedChat(widget.groupId);
    LastReadManager.cancelPendingSaves(widget.groupId);
    super.dispose();
  }

  /// Clear notifications for this chat
  void _clearNotificationsForChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService.cancelNotificationsByGroup(widget.groupId);
      } catch (e) {
        _logger.warning('Failed to clear notifications for chat ${widget.groupId}', e);
      }
    });
  }

  /// Preload avatar colors for all group members
  void _preloadMemberColors() {
    try {
      final groupsState = ref.read(groupsProvider);
      final members = groupsState.groupMembers?[widget.groupId];

      if (members != null && members.isNotEmpty) {
        final pubkeys = members.map((m) => m.publicKey).where((p) => p.isNotEmpty).toList();
        if (pubkeys.isNotEmpty) {
          ref.read(avatarColorProvider.notifier).preloadColorTokens(pubkeys);
        }
      }
    } catch (e, stack) {
      _logger.warning('Failed to preload member colors: $e', e, stack);
    }
  }

  /// Check if the user is effectively at the bottom of the chat
  bool _isAtBottom() {
    if (!_scrollController.hasClients) return false;
    final pos = _scrollController.position;
    final threshold = _scrollBottomThreshold.clamp(0.0, double.infinity);
    return pos.pixels >= (pos.maxScrollExtent - threshold);
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
    });
  }

  /// Handle keyboard visibility changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      DisplayedChatService.clearDisplayedChat();
      _logger.info('App lifecycle changed to $state, cleared displayed chat');
    } else if (state == AppLifecycleState.resumed) {
      DisplayedChatService.registerDisplayedChat(widget.groupId);
      _logger.info('App resumed, registered displayed chat: ${widget.groupId}');
    }
  }

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

    // Auto-scroll when chat first loads (loading transition detected)
    if (isLoadingCompleted && currentMessages.isNotEmpty && !_hasInitialScrollCompleted) {
      _hasInitialScrollCompleted = true;
      _hasScheduledInitialScroll = true;
      _scrollToBottom(animated: false);
      // Save last read only if user is effectively at bottom
      if (_isAtBottom()) {
        _saveLastReadForCurrentMessages();
      }
      return;
    }

    // Handle case where messages are already loaded when widget mounts
    if (!_hasInitialScrollCompleted && currentMessages.isNotEmpty && !isLoading) {
      _hasInitialScrollCompleted = true;
      _hasScheduledInitialScroll = true;
      _scrollToBottom(animated: false);
      if (_isAtBottom()) {
        _saveLastReadForCurrentMessages();
      }
      return;
    }

    // Do not auto-scroll when new messages arrive from receiver
    // Only scroll when user sends a message (handled separately in send action)
    // Save last read if user is at bottom
    if (_hasInitialScrollCompleted &&
        previousMessages.isNotEmpty &&
        currentMessages.length > previousMessages.length &&
        currentMessages.last.id != previousMessages.last.id) {
      if (_isAtBottom()) {
        _saveLastReadForCurrentMessages();
      }
    }
  }

  /// Save last read timestamp for current messages
  void _saveLastReadForCurrentMessages() {
    final messages = ref.read(
      chatProvider.select((state) => state.groupMessages[widget.groupId] ?? []),
    );
    if (messages.isNotEmpty) {
      LastReadManager.saveLastReadForLatestMessage(widget.groupId, messages);
      ref.read(chatProvider.notifier).refreshUnreadCount(widget.groupId);
    }
  }

  /// Handle scroll events for last read saving
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_isAtBottom()) {
      // User scrolled to bottom, save last read with debouncing
      final messages = ref.read(
        chatProvider.select((state) => state.groupMessages[widget.groupId] ?? []),
      );
      if (messages.isNotEmpty) {
        final latestMessage = messages.last;
        LastReadManager.saveLastReadDebounced(
          widget.groupId,
          latestMessage.createdAt,
        );
      }
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

    final isLoading = ref.watch(
      chatProvider.select((state) => state.isGroupLoading(widget.groupId)),
    );
    if (!_hasInitialScrollCompleted &&
        !_hasScheduledInitialScroll &&
        messages.isNotEmpty &&
        !isLoading) {
      _hasScheduledInitialScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasInitialScrollCompleted && _scrollController.hasClients) {
          _hasInitialScrollCompleted = true;
          _hasScheduledInitialScroll = false;
          _scrollToBottom(animated: false);
        } else {
          // Reset flag if callback can't execute
          _hasScheduledInitialScroll = false;
        }
      });
    }

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
        body: Center(
          child: Text('ui.groupNotFound'.tr()),
        ),
      );
    }

    // Watch cached group type from provider
    final groupType = ref.watch(
      groupsProvider.select((s) => s.groupTypes?[widget.groupId]),
    );

    // Show loading indicator while group type is being determined
    if (groupType == null) {
      return Scaffold(
        backgroundColor: context.colors.neutral,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (searchState.isSearchActive) {
          searchNotifier.deactivateSearch();
        }

        if (didPop) {
          ref.read(chatProvider.notifier).resetUnreadCountForGroup(widget.groupId);

          LastReadManager.flushPendingSaves(widget.groupId).then((_) {
            ref.read(chatProvider.notifier).refreshUnreadCount(widget.groupId);
          });
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
                              title: Consumer(
                                builder: (context, ref, child) {
                                  return ChatGroupAppbar(
                                    groupId: widget.groupId,
                                    onTap: () => context.push('/chats/${widget.groupId}/info'),
                                  );
                                },
                              ),
                            ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 8.h,
                            ).copyWith(bottom: 24.h),
                            sliver: SliverList.builder(
                              itemCount: messages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return ChatUserHeader(group: group);
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
                                              searchNotifier.currentMatch?.messageId == message.id,
                                          currentActiveMatch:
                                              searchNotifier.currentMatch?.messageId == message.id
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
                    ],
                  ),
                ),
                if (!searchState.isSearchActive)
                  ChatInput(
                    groupId: widget.groupId,
                    onSend: (message, isEditing) async {
                      await ref
                          .read(chatInputProvider(widget.groupId).notifier)
                          .sendMessage(
                            message: message,
                            isEditing: isEditing,
                          );
                      _scrollToBottom();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
