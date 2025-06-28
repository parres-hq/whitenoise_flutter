import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:whitenoise/ui/chat/widgets/reaction/reactions_dialog_widget.dart';
import 'package:whitenoise/ui/chat/widgets/status_message_item_widget.dart';

import '../../routing/routes.dart';
import '../core/themes/assets.dart';
import '../core/themes/src/extensions.dart';

class ChatScreen extends StatefulWidget {
  final User contact;
  final List<MessageModel> initialMessages;

  const ChatScreen({
    super.key,
    required this.contact,
    required this.initialMessages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<MessageModel> messages;
  final ScrollController _scrollController = ScrollController();
  final currentUser = User(
    id: 'current_user_id',
    name: 'You',
    nip05: 'current@user.com',
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

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // for Android
        statusBarBrightness: Brightness.dark, // for iOS
      ),
    );
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
            color: context.colors.primaryForeground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: EmojiPicker(
            config: const Config(
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
            ),
            onEmojiSelected: ((category, emoji) {
              Navigator.pop(context);
              _updateMessageReaction(message: message, reaction: emoji.emoji);
            }),
          ),
        );
      },
    );
  }

  void _updateMessageReaction({
    required MessageModel message,
    required String reaction,
  }) {
    setState(() {
      final existingReactionIndex = message.reactions.indexWhere(
        (r) => r.emoji == reaction && r.user.id == currentUser.id,
      );

      if (existingReactionIndex != -1) {
        // Remove reaction if user already reacted with same emoji
        final newReactions = List<Reaction>.from(message.reactions)
          ..removeAt(existingReactionIndex);
        messages = _updateMessage(message.copyWith(reactions: newReactions));
      } else {
        // Add new reaction
        final newReaction = Reaction(emoji: reaction, user: currentUser);
        final newReactions = List<Reaction>.from(message.reactions)..add(newReaction);
        messages = _updateMessage(message.copyWith(reactions: newReactions));
      }
    });
  }

  void _sendNewMessageOrEdit(MessageModel msg, bool isEditing) {
    setState(() {
      if (isEditing) {
        final index = messages.indexWhere((m) => m.id == msg.id);
        if (index != -1) {
          messages[index] = msg;
        }
      } else {
        messages.insert(0, msg);
      }
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

  void _handleEdit(MessageModel message) {
    setState(() {
      _editingMessage = message;
      _replyingTo = null;
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
    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: AppBar(
        backgroundColor: context.colors.appBarBackground,
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
        actions: [
          IconButton(
            icon: Icon(
              CarbonIcons.search,
              size: 20.w,
              color: context.colors.appBarForeground,
            ),
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
                  return _SwipeToReplyWidget(
                    message: message,
                    onReply: () => _handleReply(message),
                    onLongPress: () => _showReactionDialog(message, index),
                    child: Hero(
                      tag: message.id,
                      child: MessageWidget(
                        message: message,
                        isGroupMessage: false,
                        isSameSenderAsPrevious: _isSameSender(index),
                        isSameSenderAsNext: _isNextSameSender(index),
                        onReactionTap: (reaction) {
                          _updateMessageReaction(
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
                currentUser: currentUser,
                onSend: _sendNewMessageOrEdit,
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
    // Add haptic feedback for smooth interaction
    HapticFeedback.mediumImpact();

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black26,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) {
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
              } else if (menuItem.label == 'Edit') {
                _handleEdit(message);
              }
            },
            widgetAlignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
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
          CircleAvatar(
            radius: 40.r,
            backgroundImage: const AssetImage(AssetsPaths.icImage),
          ),
          Gap(12.h),
          Text(
            widget.contact.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.primary,
            ),
          ),
          Gap(12.h),
          Text(
            widget.contact.nip05,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(8.h),
          Text(
            'Public Key: ${widget.contact.publicKey.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.colors.mutedForeground,
            ),
          ),
          Gap(24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'All messages are end-to-end encrypted. Only you and ${widget.contact.name} can read them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
              ),
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

class _SwipeToReplyWidget extends StatefulWidget {
  final MessageModel message;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final Widget child;

  const _SwipeToReplyWidget({
    required this.message,
    required this.onReply,
    required this.onLongPress,
    required this.child,
  });

  @override
  State<_SwipeToReplyWidget> createState() => _SwipeToReplyWidgetState();
}

class _SwipeToReplyWidgetState extends State<_SwipeToReplyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  final double _dragThreshold = 60.0;
  bool _showReplyIcon = false;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _showReplyIcon = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    // For messages from others (left side), allow right swipe
    // For my messages (right side), allow left swipe
    if ((!widget.message.isMe && details.delta.dx > 0) ||
        (widget.message.isMe && details.delta.dx < 0)) {
      setState(() {
        // For my messages, we need to track negative drag extent
        if (widget.message.isMe) {
          _dragExtent -= details.delta.dx; // Negative for right-aligned messages
        } else {
          _dragExtent += details.delta.dx; // Positive for left-aligned messages
        }
        _dragExtent = _dragExtent.clamp(0.0, _dragThreshold);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent >= _dragThreshold * 0.5) {
      widget.onReply();
    }

    _controller.value = 0.0;
    setState(() {
      _dragExtent = 0.0;
      _showReplyIcon = false;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _longPressTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onLongPress();
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _longPressTimer?.cancel();
  }

  void _handleTapCancel() {
    _longPressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final dragOffset = widget.message.isMe ? -_dragExtent : _dragExtent;

    return Stack(
      children: [
        if (_showReplyIcon)
          Positioned(
            left: widget.message.isMe ? null : 8.w,
            right: widget.message.isMe ? 8.w : null,
            top: 0,
            // Adjust bottom to account for reactions
            bottom: widget.message.reactions.isNotEmpty ? 18.h : 0,
            child: Align(
              child: Icon(
                CarbonIcons.reply,
                color: context.colors.primary,
                size: 14.w,
              ),
            ),
          ),
        GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
