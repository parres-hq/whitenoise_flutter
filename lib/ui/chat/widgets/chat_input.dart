import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({
    super.key,
    required this.groupId,
    required this.onSend,
    this.onInputFocused,
  });

  final void Function(String content, bool isEditing) onSend;
  final VoidCallback? onInputFocused;
  final String groupId;
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
      if (_focusNode.hasFocus && widget.onInputFocused != null) {
        // Trigger scroll to bottom when input gains focus
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onInputFocused!();
        });
      }
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
    final chatState = ref.read(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final isEditing = chatState.editingMessage[widget.groupId] != null;
    final content = _textController.text.trim();

    if (content.isEmpty) return;

    widget.onSend(content, isEditing);

    // Reset input state
    _textController.clear();
    if (chatState.replyingTo[widget.groupId] != null) {
      chatNotifier.cancelReply(groupId: widget.groupId);
    }
    if (chatState.editingMessage[widget.groupId] != null) {
      chatNotifier.cancelEdit(groupId: widget.groupId);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.watch(chatProvider.notifier);

    // Update text controller when editing message changes
    if (chatState.editingMessage[widget.groupId] != null &&
        _textController.text != chatState.editingMessage[widget.groupId]!.content) {
      _textController.text = chatState.editingMessage[widget.groupId]!.content ?? '';
    }

    return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
            bottom: 24.h,
          ),
          child: Container(
            width: 1.sw,
            constraints: BoxConstraints(
              minHeight: 44.h,
            ),
            child: SafeArea(
              top: false,
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
                                  _focusNode.hasFocus
                                      ? context.colors.primary
                                      : context.colors.input,
                              width: 1.w,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReplyEditHeader(
                                replyingTo: chatState.replyingTo[widget.groupId],
                                editingMessage: chatState.editingMessage[widget.groupId],
                                onCancel: () {
                                  if (chatState.replyingTo[widget.groupId] != null) {
                                    chatNotifier.cancelReply(groupId: widget.groupId);
                                  } else if (chatState.editingMessage[widget.groupId] != null) {
                                    chatNotifier.cancelEdit(groupId: widget.groupId);
                                    _textController.clear();
                                  }
                                  setState(() {});
                                },
                              ),
                              WnTextFormField(
                                controller: _textController,
                                focusNode: _focusNode,
                                onChanged: (_) => setState(() {}),
                                hintText: 'Message',
                                maxLines: 5,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                textCapitalization: TextCapitalization.sentences,
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
                                    Gap(4.w),
                                    WnIconButton(
                                          onPressed: _sendMessage,
                                          icon: Icons.arrow_upward,
                                          backgroundColor: context.colors.primary,
                                          iconColor: context.colors.primaryForeground,
                                          size: 56.h,
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
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 200),
        )
        .slideY(
          begin: 0.3,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                replyingTo?.sender.displayName ??
                    editingMessage?.sender.displayName ??
                    'Unknown User',
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: onCancel,
                child: Icon(
                  Icons.close,
                  size: 14.w,
                  color: context.colors.mutedForeground,
                ),
              ),
            ],
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
