import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/create_profile_screen_provider.dart';
import 'package:whitenoise/ui/auth_flow/auth_header.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/status_bar_utils.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen>
    with WidgetsBindingObserver {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _bioFocusNode = FocusNode();
  bool _isLoadingDisplayName = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bioFocusNode.addListener(() {
      if (_bioFocusNode.hasFocus) {
        _scrollToEnd();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final currentMetadata = activeAccountState.metadata;
      if (currentMetadata?.displayName != null && currentMetadata!.displayName!.isNotEmpty) {
        _displayNameController.text = currentMetadata.displayName!;
        setState(() {
          _isLoadingDisplayName = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayNameController.dispose();
    _bioController.dispose();
    _scrollController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // If keyboard is opening (height increase > 50px), scroll to end
    if (bottomInset > 50) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        _scrollToEnd(forceScroll: true);
      });
    }
  }

  void _scrollToEnd({bool forceScroll = false}) {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final currentScrollOffset = _scrollController.offset;

    // Only scroll if we're not already at the bottom (unless forced)
    if (forceScroll || (maxScrollExtent - currentScrollOffset) > 50) {
      // Use double frame callback for better layout completion detection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active account provider changes and update displayName when metadata is loaded
    ref.listen<AsyncValue<ActiveAccountState>>(activeAccountProvider, (previous, next) {
      next.whenData((activeAccountState) {
        if (activeAccountState.metadata?.displayName != null &&
            activeAccountState.metadata!.displayName!.isNotEmpty &&
            _displayNameController.text.isEmpty) {
          _displayNameController.text = activeAccountState.metadata!.displayName!;
          setState(() {
            _isLoadingDisplayName = false;
          });
        }
      });
    });

    return StatusBarUtils.wrapWithAdaptiveIcons(
      context: context,
      child: Scaffold(
        backgroundColor: context.colors.neutral,
        resizeToAvoidBottomInset: true,
        appBar: AuthAppBar(title: 'auth.setUpProfile'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 0),
            child: Column(
              children: [
                Gap(48.h),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _displayNameController,
                      builder: (context, value, child) {
                        final displayText = value.text.trim();
                        final activePubkey = ref.watch(activePubkeyProvider);
                        return WnAvatar(
                          imageUrl: ref.watch(createProfileScreenProvider).selectedImagePath ?? '',
                          displayName: displayText,
                          pubkey: activePubkey,
                          size: 96.w,
                          showBorder:
                              ref.watch(createProfileScreenProvider).selectedImagePath == null,
                        );
                      },
                    ),
                    GestureDetector(
                      onTap:
                          () =>
                              ref.read(createProfileScreenProvider.notifier).pickProfileImage(ref),
                      child: Container(
                        width: 28.w,
                        height: 28.w,
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: context.colors.mutedForeground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.secondary,
                            width: 1.w,
                          ),
                        ),
                        child: WnImage(
                          AssetsPaths.icEdit,
                          color: context.colors.primaryForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(36.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'auth.chooseAName'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                Gap(10.h),
                _isLoadingDisplayName
                    ? Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: context.colors.avatarSurface,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    )
                    : WnTextFormField(
                      hintText: 'auth.yourName'.tr(),
                      obscureText: false,
                      controller: _displayNameController,
                    ),
                Gap(36.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'auth.introduceYourself'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                Gap(8.h),
                WnTextFormField(
                  hintText: 'auth.writeSomethingAboutYourself'.tr(),
                  obscureText: false,
                  controller: _bioController,
                  focusNode: _bioFocusNode,
                  maxLines: 3,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                Gap(16.h),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            bottom: 16.h + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Consumer(
              builder: (context, ref, child) {
                final createProfileState = ref.watch(createProfileScreenProvider);
                final isButtonDisabled = createProfileState.isLoading || _isLoadingDisplayName;

                return WnFilledButton(
                  label: 'auth.finish'.tr(),
                  loading: isButtonDisabled,
                  onPressed:
                      isButtonDisabled
                          ? null
                          : () => ref
                              .read(createProfileScreenProvider.notifier)
                              .updateProfile(
                                ref,
                                _displayNameController.text.trim(),
                                _bioController.text.trim(),
                              ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
