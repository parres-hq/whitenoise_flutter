import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';
import 'package:whitenoise/ui/core/ui/whitenoise_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _aboutController;
  late TextEditingController _nostrAddressController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _aboutController = TextEditingController();
    _nostrAddressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(profileProvider.notifier).fetchProfileData();
      setState(() {
        _displayNameController.text = ref.read(profileProvider).value?.displayName ?? '';
        _aboutController.text = ref.read(profileProvider).value?.about ?? '';
        _nostrAddressController.text = ref.read(profileProvider).value?.nip05 ?? '';
      });
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutController.dispose();
    _nostrAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      next.when(
        data: (profile) {
          if (profile.error != null) {
            ref.showErrorToast('Error: ${profile.error}');
          }
          // Check if we just finished saving (was saving before, not saving now, no error)
          if (previous?.value?.isSaving == true && !profile.isSaving && profile.error == null) {
            ref.showSuccessToast('Profile updated successfully');
            return;
          }

          if (previous?.value?.displayName != profile.displayName) {
            _displayNameController.text = profile.displayName ?? '';
          }
          if (previous?.value?.about != profile.about) {
            _aboutController.text = profile.about ?? '';
          }
          if (previous?.value?.nip05 != profile.nip05) {
            _nostrAddressController.text = profile.nip05 ?? '';
          }
        },
        error: (error, stackTrace) {
          ref.showErrorToast(error.toString());
        },
        loading: () {},
      );
    });

    final profileState = ref.watch(profileProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: profileState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Text(
                      'Error loading profile: $error',
                      style: TextStyle(color: context.colors.destructive),
                    ),
                  ),
              data:
                  (profile) => Column(
                    children: [
                      Gap(24.h),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: SvgPicture.asset(
                              AssetsPaths.icChevronLeft,
                              colorFilter: ColorFilter.mode(
                                context.colors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      Gap(29.h),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _displayNameController,
                                      builder: (context, value, child) {
                                        final imageUrl = _getProfileImageUrl(profile);
                                        final displayName = value.text.trim();
                                        return ContactAvatar(
                                          imageUrl: imageUrl,
                                          displayName: displayName,
                                          size: 96.w,
                                        );
                                      },
                                    ),
                                    Positioned(
                                      left: 1.sw * 0.5,
                                      bottom: 4.h,
                                      width: 28.w,
                                      child: EditIconWidget(
                                        onTap: () async {
                                          try {
                                            await ref
                                                .read(profileProvider.notifier)
                                                .pickProfileImage();
                                          } catch (e) {
                                            if (context.mounted) {
                                              ref.showErrorToast('Failed to pick profile image');
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Gap(36.h),
                                Text(
                                  'Profile Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: context.colors.primary,
                                  ),
                                ),
                                Gap(10.h),
                                AppTextFormField(
                                  controller: _displayNameController,
                                  hintText: 'Trent Reznor',
                                  onChanged: (value) {
                                    ref
                                        .read(profileProvider.notifier)
                                        .updateLocalProfile(displayName: value);
                                  },
                                ),
                                Gap(36.h),
                                Text(
                                  'Nostr Address (NIP-05)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: context.colors.primary,
                                  ),
                                ),
                                Gap(10.h),
                                AppTextFormField(
                                  controller: _nostrAddressController,
                                  hintText: 'example@whitenoise.chat',
                                  onChanged: (value) {
                                    ref
                                        .read(profileProvider.notifier)
                                        .updateLocalProfile(nip05: value);
                                  },
                                ),
                                Gap(36.h),
                                Text(
                                  'About You',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    color: context.colors.primary,
                                  ),
                                ),
                                Gap(10.h),
                                AppTextFormField(
                                  controller: _aboutController,
                                  hintText: 'Write something about yourself.',
                                  minLines: 3,
                                  maxLines: 3,
                                  keyboardType: TextInputType.multiline,
                                  onChanged: (value) {
                                    ref
                                        .read(profileProvider.notifier)
                                        .updateLocalProfile(about: value);
                                  },
                                ),
                                Gap(16.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          bottom: MediaQuery.of(context).viewPadding.bottom,
                        ),
                        child: profileState.when(
                          data:
                              (profile) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (profile.isDirty) ...[
                                    WnFilledButton(
                                      onPressed:
                                          () => showDialog(
                                            context: context,
                                            builder:
                                                (dialogContext) => WhitenoiseDialog(
                                                  title: 'Unsaved changes',
                                                  content:
                                                      'You have unsaved changes. Are you sure you want to leave?',
                                                  actions: Row(
                                                    children: [
                                                      Expanded(
                                                        child: WnFilledButton.child(
                                                          onPressed: () {
                                                            ref
                                                                .read(profileProvider.notifier)
                                                                .discardChanges();
                                                            Navigator.of(dialogContext).pop();
                                                          },
                                                          visualState:
                                                              WnButtonVisualState.secondaryWarning,
                                                          size: WnButtonSize.small,
                                                          child: const FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: Text('Discard Changes'),
                                                          ),
                                                        ),
                                                      ),
                                                      Gap(10.w),
                                                      Expanded(
                                                        child: WnFilledButton(
                                                          onPressed: () async {
                                                            await ref
                                                                .read(profileProvider.notifier)
                                                                .updateProfileData();
                                                            if (context.mounted) {
                                                              Navigator.of(dialogContext).pop();
                                                            }
                                                          },
                                                          title: 'Save',
                                                          size: WnButtonSize.small,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                      title: 'Discard Changes',
                                      visualState: WnButtonVisualState.secondary,
                                    ),
                                    Gap(4.h),
                                  ],
                                  WnFilledButton(
                                    onPressed:
                                        profile.isDirty && !profile.isSaving
                                            ? () async =>
                                                await ref
                                                    .read(profileProvider.notifier)
                                                    .updateProfileData()
                                            : null,
                                    loading: profile.isSaving,
                                    title: 'Save',
                                  ),
                                ],
                              ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

String _getProfileImageUrl(ProfileState? profile) {
  final selectedImagePath = profile?.selectedImagePath;
  final profilePicture = profile?.picture ?? '';
  if (selectedImagePath != null && selectedImagePath.isNotEmpty) {
    return selectedImagePath;
  }
  if (profilePicture.isNotEmpty) {
    return profilePicture;
  }
  return '';
}

class FallbackProfileImageWidget extends StatelessWidget {
  final String displayName;
  final double? fontSize;
  const FallbackProfileImageWidget({
    super.key,
    required this.displayName,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96.w,
      height: 96.w,
      color: context.colors.input,
      child: Center(
        child: Text(
          displayName[0].toUpperCase(),
          style: TextStyle(
            fontSize: fontSize ?? 16.sp,
            fontWeight: FontWeight.bold,
            color: context.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
