import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';
import 'package:whitenoise/utils/relay_validation.dart';

class RelayOptionsBottomSheet extends ConsumerStatefulWidget {
  final RelayInfo relayInfo;
  final Function(String)? onRelayUpdated;

  const RelayOptionsBottomSheet({
    super.key,
    required this.relayInfo,
    this.onRelayUpdated,
  });

  @override
  ConsumerState<RelayOptionsBottomSheet> createState() => _RelayOptionsBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required RelayInfo relayInfo,
    Function(String)? onRelayUpdated,
  }) async {
    await WnBottomSheet.show(
      context: context,
      title: 'Edit Relay',
      builder:
          (context) => RelayOptionsBottomSheet(
            relayInfo: relayInfo,
            onRelayUpdated: onRelayUpdated,
          ),
    );
  }
}

class _RelayOptionsBottomSheetState extends ConsumerState<RelayOptionsBottomSheet> {
  final TextEditingController _relayUrlController = TextEditingController();
  bool _isValidatingUrl = false;
  bool _validUrl = false;
  final bool _acceptedRelay = false;
  String? _relayValidationError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _relayUrlController.text = widget.relayInfo.url;
    _relayUrlController.addListener(_onUrlChanged);
    _validUrl = true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _relayUrlController.removeListener(_onUrlChanged);
    _relayUrlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateRelayUrl();
    });
  }

  Future<void> _validateRelayUrl() async {
    if (_isValidatingUrl) return;

    try {
      final url = _relayUrlController.text.trim();

      // If URL is empty or just the prefix, don't validate
      if (RelayValidation.shouldSkipValidation(url)) {
        if (mounted) {
          setState(() {
            _isValidatingUrl = false;
            _validUrl = false;
            _relayValidationError = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isValidatingUrl = true;
          _validUrl = false;
          _relayValidationError = null;
        });
      }

      final String? validationError = RelayValidation.validateRelayUrl(url);

      if (mounted) {
        if (validationError == null) {
          setState(() {
            _validUrl = true;
            _relayValidationError = null;
            _isValidatingUrl = false;
          });
        } else {
          setState(() {
            _validUrl = false;
            _relayValidationError = validationError;
            _isValidatingUrl = false;
          });
        }
      }
    } catch (e) {
      ref.showErrorToast('Failed validating relay URL');
      if (mounted) {
        setState(() {
          _isValidatingUrl = false;
          _validUrl = false;
        });
      }
    }
  }

  Future<void> _updateRelay() async {
    if (!_validUrl) {
      ref.showErrorToast('Please enter a valid relay URL');
      return;
    }
    if (!_acceptedRelay) {
      ref.showErrorToast('Please enter a valid relay');
      return;
    }
    // TODO : implement update relay logic
    final relayUrl = _relayUrlController.text.trim();
    if (relayUrl.isEmpty || !_validUrl) {
      ref.showErrorToast('Please enter a valid relay URL');
      return;
    }
    Navigator.of(context).pop();
    widget.onRelayUpdated?.call(relayUrl);
    ref.showSuccessToast('Relay updated successfully');
  }

  Future<void> _removeRelay() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => WnDialog.custom(
            customChild: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remove Relay?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: Icon(
                        CarbonIcons.close,
                        color: context.colors.primary,
                        size: 24.w,
                      ),
                    ),
                  ],
                ),
                Gap(6.h),
                Text(
                  'Are you sure you want to remove this relay? To use it again, you’ll need to add it back manually.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(12.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  visualState: WnButtonVisualState.secondary,
                  title: 'Cancel',
                  size: WnButtonSize.small,
                ),
                Gap(8.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  visualState: WnButtonVisualState.destructive,
                  title: 'Remove Relay',
                  size: WnButtonSize.small,
                ),
              ],
            ),
          ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      // TODO: Implement relay removal
      ref.showSuccessToast('Relay removed successfully');
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final String pastedText = clipboardData!.text!.trim();

        // If pasted text already starts with wss:// or ws://, use it as is
        // Otherwise, append it to wss://
        if (pastedText.startsWith('wss://') || pastedText.startsWith('ws://')) {
          _relayUrlController.text = pastedText;
        } else {
          // Add wss:// prefix to the pasted text
          _relayUrlController.text = 'wss://$pastedText';
        }

        // Trigger immediate validation after paste
        _debounceTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 100), _validateRelayUrl);

        ref.showRawSuccessToast('Pasted from clipboard');
      } else {
        ref.showRawErrorToast('No text found in clipboard');
      }
    } catch (e) {
      ref.showRawErrorToast('Failed to paste from clipboard');
    }
  }

  final List<RelayFunction> _functionsToUpdate = [];
  final List<RelayFunction> _foundFunctions = [
    RelayFunction.messaging,
    RelayFunction.inviteToChat,
    RelayFunction.keyInvite,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      // mainAxisSize: MainAxisSize.min,
      // crossAxisAlignment: CrossAxisAlignment.start,
      shrinkWrap: true,
      children: [
        Text(
          'Relay Address',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  WnTextFormField(
                    controller: _relayUrlController,
                    hintText: 'wss://relay.example.com',
                  ),
                ],
              ),
            ),
            Gap(8.w),
            CustomIconButton(
              onTap: _pasteFromClipboard,
              iconPath: AssetsPaths.icPaste,
              size: 50.w,
              padding: 15.w,
            ),
          ],
        ),
        Gap(16.h),
        if (_relayValidationError != null) ...[
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.colors.destructive.withValues(alpha: 0.1),

              border: Border.all(color: context.colors.destructive),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      CarbonIcons.warning_filled,
                      color: context.colors.destructive,
                      size: 16.w,
                    ),
                    Gap(8.w),
                    Text(
                      'Relay Not Supported',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                Text(
                  _relayValidationError!,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          Gap(12.h),
        ],
        Text(
          'Relay Functions',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(12.h),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: RelayFunction.values.length,
          itemBuilder: (context, index) {
            final function = RelayFunction.values[index];
            final isSelected = _functionsToUpdate.contains(function);
            final isDisabled = _foundFunctions.isNotEmpty && !_foundFunctions.contains(function);
            return Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: ColoredBox(
                color: context.colors.surface,
                child: CheckboxListTile(
                  value: isSelected,
                  enabled: !isDisabled,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    function.displayName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.colors.primary,
                    ),
                  ),
                  subtitle: Text(
                    function.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _functionsToUpdate.add(function);
                      } else {
                        _functionsToUpdate.remove(function);
                      }
                    });
                  },
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => Gap(8.h),
        ),

        Gap(16.h),
        WnFilledButton(
          onPressed: () => Navigator.of(context).pop(),
          visualState: WnButtonVisualState.secondary,
          title: 'Cancel',
          size: WnButtonSize.small,
        ),
        Gap(8.h),

        WnFilledButton(
          onPressed: _removeRelay,
          visualState: WnButtonVisualState.secondaryWarning,
          title: 'Remove Relay',
          size: WnButtonSize.small,
        ),
        Gap(8.h),
        WnFilledButton(
          onPressed: (_validUrl && _functionsToUpdate.isNotEmpty) ? _updateRelay : null,
          title: 'Save',
          size: WnButtonSize.small,
        ),
      ],
    );
  }
}
