import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';
import 'package:whitenoise/ui/core/ui/whitenoise_dialog.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _aboutController.dispose();
    _nostrAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      await ref.read(profileProvider.notifier).fetchProfileData();

      final profileData = ref.read(profileProvider);

      profileData.whenData((profile) {
        setState(() {
          _displayNameController.text = profile.displayName ?? '';
          _aboutController.text = profile.about ?? '';
          _nostrAddressController.text = profile.nip05 ?? '';
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveChanges() async {
    final profileState = ref.read(profileProvider).value;
    if (profileState == null) return;
    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfileData(
            displayName: profileState.displayName,
            about: profileState.about,
            picture: profileState.picture,
            nip05: profileState.nip05,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${profile.error}'),
              backgroundColor: context.colors.destructive,
            ),
          );
        }

        // If the save was successful, `fetchProfileData` is called, which will
        // make the new state not have a value, but `isRefreshing` will be true.
        // In that case, we can pop the screen.
        if (previous?.value != null && !next.hasValue && next.isRefreshing) {
          context.pop();
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
      });
    });

    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: SafeArea(
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
                                Container(
                                  decoration: BoxDecoration(
                                    color: context.colors.neutral,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 80.w,
                                    height: 80.w,
                                    margin: EdgeInsets.all(5.w),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child:
                                          (profile.picture ?? '').isNotEmpty
                                              ? Image.network(
                                                profile.picture!,
                                                fit: BoxFit.cover,
                                                width: 96.w,
                                                height: 96.w,
                                                errorBuilder:
                                                    (context, error, stackTrace) => Center(
                                                      child: Text(
                                                        'S',
                                                        style: TextStyle(
                                                          fontSize: 32.sp,
                                                          fontWeight: FontWeight.bold,
                                                          color: context.colors.mutedForeground,
                                                        ),
                                                      ),
                                                    ),
                                              )
                                              : Image.asset(
                                                AssetsPaths.icImage,
                                                fit: BoxFit.cover,
                                                width: 96.w,
                                                height: 96.w,
                                              ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 1.sw * 0.5 - 10.w,
                                  bottom: 4.h,
                                  width: 28.w,
                                  child: EditIconWidget(
                                    onTap: () async {
                                      await ref.read(profileProvider.notifier).pickProfileImage();
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
                              hintText: 'nin@nostr.com',
                              onChanged: (value) {
                                ref.read(profileProvider.notifier).updateLocalProfile(nip05: value);
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
                              hintText: 'Nothing can stop me now.',
                              minLines: 3,
                              maxLines: 3,
                              keyboardType: TextInputType.multiline,
                              onChanged: (value) {
                                ref.read(profileProvider.notifier).updateLocalProfile(about: value);
                              },
                            ),
                            Gap(16.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: profileState.when(
            data:
                (profile) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile.isDirty) ...[
                      AppFilledButton(
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
                                          child: AppFilledButton(
                                            onPressed: () {
                                              ref.read(profileProvider.notifier).discardChanges();
                                              Navigator.of(dialogContext).pop();
                                            },
                                            title: 'Discard Changes',
                                            visualState: AppButtonVisualState.secondaryWarning,
                                            size: AppButtonSize.small,
                                          ),
                                        ),
                                        Gap(12.w),
                                        Expanded(
                                          child: AppFilledButton(
                                            onPressed: () async {
                                              await _saveChanges();
                                              if (context.mounted) {
                                                Navigator.of(dialogContext).pop();
                                              }
                                            },
                                            title: 'Save',
                                            size: AppButtonSize.small,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                        title: 'Discard Changes',
                        visualState: AppButtonVisualState.secondary,
                      ),
                      Gap(4.h),
                    ],
                    AppFilledButton(
                      onPressed: profile.isDirty && !profile.isSaving ? _saveChanges : null,
                      loading: profile.isSaving,
                      title: 'Save',
                    ),
                  ],
                ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
