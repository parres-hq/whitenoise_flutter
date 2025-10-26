import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/edit_profile_screen_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<EditProfileScreen> {
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
      await ref.read(editProfileScreenProvider.notifier).fetchProfileData();
      setState(() {
        _displayNameController.text = ref.read(editProfileScreenProvider).value?.displayName ?? '';
        _aboutController.text = ref.read(editProfileScreenProvider).value?.about ?? '';
        _nostrAddressController.text = ref.read(editProfileScreenProvider).value?.nip05 ?? '';
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
    ref.listen(editProfileScreenProvider, (previous, next) {
      next.when(
        data: (profile) {
          if (profile.error != null) {
            ref.showErrorToast('${'errors.errorOccurred'.tr()}: ${profile.error}');
          }
          // Check if we just finished saving (was saving before, not saving now, no error)
          if (previous?.value?.isSaving == true && !profile.isSaving && profile.error == null) {
            ref.showSuccessToast('profile.profileUpdatedSuccessfully'.tr());
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

    final profileState = ref.watch(editProfileScreenProvider);

    return WnSettingsScreenWrapper(
      title: 'settings.editProfile'.tr(),
      body: profileState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Text(
                      '${'profile.errorLoadingProfile'.tr()}: $error',
                      style: TextStyle(color: context.colors.destructive),
                    ),
                  ),
              data:
                  (profile) => Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24.h),
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
                                          return WnAvatar(
                                            imageUrl: imageUrl,
                                            displayName: displayName,
                                            size: 96.w,
                                            showBorder: imageUrl.isEmpty,
                                          );
                                        },
                                      ),
                                      Positioned(
                                        left: 1.sw * 0.5,
                                        bottom: 4.h,
                                        width: 28.w,
                                        child: WnEditIconWidget(
                                          onTap: () async {
                                            try {
                                              await ref
                                                  .read(editProfileScreenProvider.notifier)
                                                  .pickProfileImage();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ref.showErrorToast(
                                                  'profile.failedToPickProfileImage'.tr(),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Gap(36.h),
                                  Text(
                                    'profile.profileName'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnTextFormField(
                                    controller: _displayNameController,
                                    hintText: 'auth.yourName'.tr(),
                                    onChanged: (value) {
                                      ref
                                          .read(editProfileScreenProvider.notifier)
                                          .updateLocalProfile(displayName: value);
                                    },
                                  ),
                                  Gap(36.h),
                                  Text(
                                    'profile.nostrAddress'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnTextFormField(
                                    controller: _nostrAddressController,
                                    hintText: 'profile.nostrAddressExample'.tr(),
                                    onChanged: (value) {
                                      ref
                                          .read(editProfileScreenProvider.notifier)
                                          .updateLocalProfile(nip05: value);
                                    },
                                  ),
                                  Gap(36.h),
                                  Text(
                                    'profile.aboutYou'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnTextFormField(
                                    controller: _aboutController,
                                    hintText: 'auth.writeSomethingAboutYourself'.tr(),
                                    minLines: 3,
                                    maxLines: 3,
                                    keyboardType: TextInputType.multiline,
                                    onChanged: (value) {
                                      ref
                                          .read(editProfileScreenProvider.notifier)
                                          .updateLocalProfile(about: value);
                                    },
                                  ),
                                  Gap(16.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          bottom: 16.h,
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
                                                (dialogContext) => WnDialog(
                                                  title: 'shared.unsavedChanges'.tr(),
                                                  content: 'profile.unsavedChangesQuestion'.tr(),
                                                  actions: Row(
                                                    children: [
                                                      Expanded(
                                                        child: WnFilledButton(
                                                          onPressed: () {
                                                            ref
                                                                .read(
                                                                  editProfileScreenProvider
                                                                      .notifier,
                                                                )
                                                                .discardChanges();
                                                            Navigator.of(dialogContext).pop();
                                                          },
                                                          visualState:
                                                              WnButtonVisualState.secondaryWarning,
                                                          size: WnButtonSize.small,
                                                          label: 'shared.discardChanges'.tr(),
                                                        ),
                                                      ),
                                                      Gap(10.w),
                                                      Expanded(
                                                        child: WnFilledButton(
                                                          onPressed: () async {
                                                            await ref
                                                                .read(
                                                                  editProfileScreenProvider
                                                                      .notifier,
                                                                )
                                                                .updateProfileData();
                                                            if (context.mounted) {
                                                              Navigator.of(dialogContext).pop();
                                                            }
                                                          },
                                                          label: 'shared.save'.tr(),
                                                          size: WnButtonSize.small,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          ),
                                      label: 'shared.discardChanges'.tr(),
                                      visualState: WnButtonVisualState.secondary,
                                    ),
                                    Gap(8.h),
                                  ],
                                  WnFilledButton(
                                    onPressed:
                                        profile.isDirty && !profile.isSaving
                                            ? () async =>
                                                await ref
                                                    .read(editProfileScreenProvider.notifier)
                                                    .updateProfileData()
                                            : null,
                                    loading: profile.isSaving,
                                    label: 'shared.save'.tr(),
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
