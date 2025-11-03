import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_input_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input_media_selector.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input_reply_preview.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input_send_button.dart';
import 'package:whitenoise/ui/chat/widgets/media_preview.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
  final _inputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDraftMessage();
      }
    });
    _focusNode.addListener(_handleFocusChange);
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureSingleLineHeight();
    });
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final editingMessage = ref.read(chatProvider).editingMessage[widget.groupId];
    final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
    final chatInputState = ref.read(chatInputProvider(widget.groupId));

    if (editingMessage != null &&
        editingMessage.content != chatInputState.previousEditingMessageContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        chatInputNotifier.setPreviousEditingMessageContent(editingMessage.content);
        _textController.text = editingMessage.content ?? '';
      });
    }
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus) {
      widget.onInputFocused?.call();
      final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
      final chatInputState = ref.read(chatInputProvider(widget.groupId));
      if (chatInputState.showMediaSelector) {
        chatInputNotifier.hideMediaSelector();
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMediaSelector() {
    final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
    final chatInputState = ref.read(chatInputProvider(widget.groupId));
    chatInputNotifier.toggleMediaSelector();
    if (!chatInputState.showMediaSelector) {
      _focusNode.unfocus();
    }
  }

  Future<void> _handleImagesSelected() async {
    _focusNode.unfocus();
    final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
    await chatInputNotifier.handleImagesSelected();
  }

  void _removeImage(int index) {
    final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
    chatInputNotifier.removeImage(index);
  }

  void _measureSingleLineHeight() {
    final context = _inputKey.currentContext;
    if (!mounted || context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox) {
      final h = renderObject.size.height;
      final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
      chatInputNotifier.setSingleLineHeight(h);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraftImmediately();
    }
  }

  Future<void> _loadDraftMessage() async {
    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessage[widget.groupId] != null;
    if (!isEditing) {
      final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
      final draft = await chatInputNotifier.loadDraft();
      if (draft != null && draft.isNotEmpty && mounted) {
        _textController.text = draft;
      }
    }
  }

  void _onTextChanged() {
    final chatInputState = ref.read(chatInputProvider(widget.groupId));
    if (chatInputState.isLoadingDraft) return;
    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessage[widget.groupId] != null;
    if (!isEditing) {
      final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
      chatInputNotifier.scheduleDraftSave(_textController.text);
    }
  }

  Future<void> _saveDraftImmediately() async {
    final chatInputState = ref.read(chatInputProvider(widget.groupId));
    if (chatInputState.isLoadingDraft) return;
    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessage[widget.groupId] != null;
    if (!isEditing) {
      final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
      await chatInputNotifier.saveDraftImmediately(_textController.text);
    }
  }

  void _sendMessage() {
    final chatState = ref.read(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final chatInputState = ref.read(chatInputProvider(widget.groupId));
    final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);

    final isEditing = chatState.editingMessage[widget.groupId] != null;
    final content = _textController.text.trim();
    if ((content.isEmpty && chatInputState.selectedMedia.isEmpty) ||
        chatInputState.hasUploadingMedia) {
      return;
    }

    widget.onSend(content, isEditing);

    _textController.clear();
    chatInputNotifier.clear();

    if (chatState.replyingTo[widget.groupId] != null) {
      chatNotifier.cancelReply(groupId: widget.groupId);
    }
    if (chatState.editingMessage[widget.groupId] != null) {
      chatNotifier.cancelEdit(groupId: widget.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.watch(chatProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider(widget.groupId));

    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final chatState = ref.read(chatProvider);
          final isEditing = chatState.editingMessage[widget.groupId] != null;
          if (!isEditing) {
            final chatInputNotifier = ref.read(chatInputProvider(widget.groupId).notifier);
            final currentText = _textController.text;

            await chatInputNotifier.handleAccountSwitch(
              oldPubkey: previous,
              currentText: currentText,
            );

            _textController.clear();
            await _loadDraftMessage();
          }
        });
      }
    });

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
                  bottom: chatInputState.showMediaSelector ? 0.h : 24.h,
                ),
                child: Container(
                  width: 1.sw,
                  constraints: BoxConstraints(
                    minHeight: 44.h,
                  ),
                  child: Row(
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
                              ChatInputReplyPreview(
                                replyingTo: chatState.replyingTo[widget.groupId],
                                editingMessage: chatState.editingMessage[widget.groupId],
                                onCancel: () {
                                  if (chatState.replyingTo[widget.groupId] != null) {
                                    chatNotifier.cancelReply(groupId: widget.groupId);
                                  } else if (chatState.editingMessage[widget.groupId] != null) {
                                    chatNotifier.cancelEdit(groupId: widget.groupId);
                                    _textController.clear();
                                  }
                                },
                              ),
                              MediaPreview(
                                mediaItems: chatInputState.selectedMedia,
                                onRemoveImage: _removeImage,
                                onAddMore: _handleImagesSelected,
                                isReply: chatState.replyingTo[widget.groupId] != null,
                              ),
                              Row(
                                children: [
                                  if (chatInputState.selectedMedia.isEmpty)
                                    GestureDetector(
                                      onTap: _toggleMediaSelector,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 14.w),
                                        child: WnImage(
                                          AssetsPaths.icAdd,
                                          size: 16.w,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: WnTextFormField(
                                      key: _inputKey,
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      hintText: 'chats.message'.tr(),
                                      maxLines: 5,
                                      textInputAction: TextInputAction.newline,
                                      keyboardType: TextInputType.multiline,
                                      textCapitalization: TextCapitalization.sentences,
                                      size: FieldSize.small,
                                      isBorderHidden: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      ChatInputSendButton(
                        textController: _textController,
                        singleLineHeight: chatInputState.singleLineHeight,
                        onSend: _sendMessage,
                        hasImages: chatInputState.selectedMedia.isNotEmpty,
                        isDisabled: chatInputState.hasUploadingMedia,
                      ),
                    ],
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
              ),
          if (chatInputState.showMediaSelector)
            ChatInputMediaSelector(
                  onImagesSelected: _handleImagesSelected,
                )
                .animate()
                .slideY(
                  begin: 0.5,
                  end: 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(
                  duration: const Duration(milliseconds: 200),
                ),
        ],
      ),
    );
  }
}
