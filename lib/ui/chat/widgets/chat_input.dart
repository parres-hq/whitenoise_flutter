import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/notifiers/chat_notifier.dart';

import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_icon_button.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({
    super.key,

    required this.onSend,
  });

  final void Function(MessageModel message, bool isEditing) onSend;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final chatNotifier = ref.read(chatNotifierProvider.notifier);
    final chatState = ref.read(chatNotifierProvider);
    final accountState = ref.read(accountProvider);
    if (accountState.metadata == null || accountState.pubkey == null) return;

    final isEditing = chatState.editingMessage != null;

    final message = MessageModel(
      id: chatState.editingMessage?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: _textController.text.trim(),
      type: MessageType.text,
      createdAt: chatState.editingMessage?.createdAt ?? DateTime.now(),
      updatedAt: chatState.editingMessage != null ? DateTime.now() : null,
      sender: User.fromMetadata(accountState.metadata!, accountState.pubkey!),
      isMe: true,
      status: MessageStatus.sending,
      replyTo: chatState.replyingTo,
    );

    widget.onSend(message, isEditing);

    // Reset input state
    _textController.clear();
    if (chatState.replyingTo != null) {
      chatNotifier.cancelReply();
    }
    if (chatState.editingMessage != null) {
      chatNotifier.cancelEdit();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final chatNotifier = ref.read(chatNotifierProvider.notifier);

    // Update text controller when editing message changes
    if (chatState.editingMessage != null &&
        _textController.text != chatState.editingMessage!.content) {
      _textController.text = chatState.editingMessage!.content ?? '';
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return AnimatedPadding(
      duration: Durations.long2,
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
        top: 4.h,
        bottom: isKeyboardOpen ? 16.h : 54.h,
      ),
      child: SafeArea(
        child: Container(
          width: 1.sw,
          constraints: BoxConstraints(
            minHeight: 44.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.avatarSurface,
                        border: Border.all(
                          color:
                              _focusNode.hasFocus ? context.colors.primary : context.colors.input,
                          width: 1.w,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReplyEditHeader(
                            replyingTo: chatState.replyingTo,
                            editingMessage: chatState.editingMessage,
                            onCancel: () {
                              if (chatState.replyingTo != null) {
                                chatNotifier.cancelReply();
                              } else if (chatState.editingMessage != null) {
                                chatNotifier.cancelEdit();
                                _textController.clear();
                              }
                              setState(() {});
                            },
                          ),
                          AppTextFormField(
                            controller: _textController,
                            focusNode: _focusNode,
                            onChanged: (_) => setState(() {}),
                            hintText: 'Message',
                            maxLines: 5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child:
                        _textController.text.isNotEmpty
                            ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Gap(8.w),
                                AppIconButton(
                                      onPressed: _sendMessage,
                                      icon: Icons.arrow_upward,
                                      backgroundColor: context.colors.primary,
                                      iconColor: context.colors.primaryForeground,
                                      size: 52.w,
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: const Duration(milliseconds: 200),
                                    )
                                    .scale(
                                      begin: const Offset(0.7, 0.7),
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.elasticOut,
                                    ),
                              ],
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}

class ReplyEditHeader extends StatelessWidget {
  const ReplyEditHeader({
    super.key,
    this.replyingTo,
    this.editingMessage,
    required this.onCancel,
  });

  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (replyingTo == null && editingMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16.w).copyWith(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.colors.secondary,
        border: Border(
          left: BorderSide(
            color: context.colors.mutedForeground,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onCancel,
              child: Icon(
                Icons.close,
                size: 14.w,
                color: context.colors.mutedForeground,
              ),
            ),
          ),
          Text(
            replyingTo?.sender.name ?? editingMessage?.sender.name ?? 'User Name',
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(4.h),
          Text(
            replyingTo?.content ?? editingMessage?.content ?? 'Quote Text...',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
