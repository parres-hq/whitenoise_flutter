import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
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

class _ChatInputState extends ConsumerState<ChatInput> with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _draftSaveTimer;
  bool _isLoadingDraft = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDraftMessage();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.onInputFocused != null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onInputFocused!();
        });
      }
      setState(() {});
    });

    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftSaveTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Immediately save draft when app is paused/minimized or becomes inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraftImmediately();
    }
  }

  Future<void> _loadDraftMessage() async {
    setState(() {
      _isLoadingDraft = true;
    });

    try {
      final chatState = ref.read(chatProvider);
      final isEditing = chatState.editingMessage[widget.groupId] != null;

      if (!isEditing) {
        final draft = await DraftMessageService.loadDraft(chatId: widget.groupId);
        if (draft != null && draft.isNotEmpty && mounted) {
          _textController.text = draft;
        }
      }
    } catch (e) {
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDraft = false;
        });
      }
    }
  }

  void _onTextChanged() {
    _draftSaveTimer?.cancel();

    if (_isLoadingDraft) return;

    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessage[widget.groupId] != null;

    if (!isEditing) {
      _draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
        _saveDraft();
      });
    }
  }

  Future<void> _saveDraft() async {
    try {
      await DraftMessageService.saveDraft(
        chatId: widget.groupId,
        message: _textController.text,
      );
    } catch (e) {
      return;
    }
  }

  Future<void> _saveDraftImmediately() async {
    _draftSaveTimer?.cancel();

    if (_isLoadingDraft) return;

    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessage[widget.groupId] != null;

    if (!isEditing) {
      try {
        await DraftMessageService.saveDraft(
          chatId: widget.groupId,
          message: _textController.text,
        );
      } catch (e) {
        return;
      }
    }
  }

  Future<void> _clearDraft() async {
    try {
      await DraftMessageService.clearDraft(chatId: widget.groupId);
    } catch (e) {
      return;
    }
  }

  void _sendMessage() {
    final chatState = ref.read(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final isEditing = chatState.editingMessage[widget.groupId] != null;
    final content = _textController.text.trim();

    if (content.isEmpty) return;

    widget.onSend(content, isEditing);

    _clearDraft();

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
    final isReplying = chatState.replyingTo[widget.groupId] != null;
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
                            border:
                                isReplying
                                    ? Border.all(
                                      color:
                                          _focusNode.hasFocus
                                              ? context.colors.primary
                                              : context.colors.input,
                                      width: 1.w,
                                    )
                                    : null,
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
                                size: FieldSize.small,
                                decoration:
                                    isReplying
                                        ? const InputDecoration(
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                        )
                                        : null,
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
                                    //TODO @Quwaysim ... This will come in PR for issue #511
                                    WnIconButton(
                                          iconPath: AssetsPaths.icArrowUp,
                                          padding: 18.w,
                                          size: 44.h,
                                          onTap: _sendMessage,
                                          buttonColor: context.colors.primary,
                                          iconColor: context.colors.primaryForeground,
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
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: WnImage(
                    AssetsPaths.icClose,
                    width: 16.w,
                    height: 16.w,
                    color: context.colors.mutedForeground,
                  ),
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
