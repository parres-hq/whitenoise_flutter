import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _aboutController;
  late TextEditingController _websiteController;
  late TextEditingController _nostrAddressController;
  late TextEditingController _lightningAddressController;

  String _profileImagePath = '';
  String _bannerImagePath = '';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _displayNameController = TextEditingController();
    _aboutController = TextEditingController();
    _websiteController = TextEditingController();
    _nostrAddressController = TextEditingController();
    _lightningAddressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _websiteController.dispose();
    _nostrAddressController.dispose();
    _lightningAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      await ref.read(profileProvider.notifier).fetchProfileData();

      final profileData = ref.read(profileProvider);

      profileData.whenData((profile) {
        setState(() {
          _usernameController.text = profile.name ?? '';
          _displayNameController.text = profile.displayName ?? '';
          _aboutController.text = profile.about ?? '';
          _websiteController.text = profile.website ?? '';
          _nostrAddressController.text = profile.nip05 ?? '';
          _lightningAddressController.text = profile.lud16 ?? '';
          _profileImagePath = profile.picture ?? '';
          _bannerImagePath = profile.banner ?? '';
        });
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
      );
    }
  }

  //TODO
  Future<void> _saveChanges() async {
    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfileData(
            name: _usernameController.text,
            displayName: _displayNameController.text,
            about: _aboutController.text,
            picture: _profileImagePath,
            banner: _bannerImagePath,
            nip05: _nostrAddressController.text,
            lud16: _lightningAddressController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Profile'),
      body: profileState.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(),
            ),
        error:
            (error, _) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        data:
            (_) => Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 168.h,
                          child: Stack(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 128.h,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.glitch200.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    child:
                                        _bannerImagePath.isNotEmpty
                                            ? Image.network(
                                              _bannerImagePath,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Image.asset(
                                                    AssetsPaths
                                                        .profileBackground,
                                                    fit: BoxFit.cover,
                                                  ),
                                            )
                                            : Image.asset(
                                              AssetsPaths.profileBackground,
                                              fit: BoxFit.cover,
                                            ),
                                  ),
                                  Positioned(
                                    right: 16.w,
                                    top: 16.h,
                                    child: EditIconWidget(
                                      onTap:
                                          ref
                                              .read(profileProvider.notifier)
                                              .pickBannerImage,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 16.w,
                                left: 16.w,
                                bottom: 0.h,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: AppColors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        width: 80.w,
                                        height: 80.w,
                                        margin: EdgeInsets.all(5.w),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child:
                                            _profileImagePath.isNotEmpty
                                                ? ClipOval(
                                                  child: Image.network(
                                                    _profileImagePath,
                                                    fit: BoxFit.cover,
                                                    width: 80.w,
                                                    height: 80.w,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Text(
                                                            'S',
                                                            style: TextStyle(
                                                              fontSize: 32.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  AppColors
                                                                      .glitch600,
                                                            ),
                                                          ),
                                                        ),
                                                  ),
                                                )
                                                : Center(
                                                  child: Text(
                                                    'S',
                                                    style: TextStyle(
                                                      fontSize: 32.sp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.glitch600,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 1.sw * 0.5 + 2.w,
                                      bottom: 4.h,
                                      width: 24.w,
                                      child: EditIconWidget(
                                        onTap:
                                            ref
                                                .read(profileProvider.notifier)
                                                .pickProfileImage,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Form fields
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                textController: _usernameController,
                                padding: EdgeInsets.zero,
                                autofocus: false,
                                hintText: '@satoshi',
                                label: 'Username',
                              ),
                              Gap(16.h),
                              CustomTextField(
                                textController: _displayNameController,
                                padding: EdgeInsets.zero,
                                autofocus: false,
                                hintText: 'Satoshi Nakamoto',
                                label: 'Display Name',
                              ),
                              Gap(16.h),
                              CustomTextField(
                                textController: _aboutController,
                                padding: EdgeInsets.zero,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                                autofocus: false,
                                hintText: 'A few words about you',
                                label: 'About',
                              ),
                              Gap(16.h),
                              CustomTextField(
                                textController: _websiteController,
                                padding: EdgeInsets.zero,
                                autofocus: false,
                                hintText: 'https://...',
                                label: 'Website',
                              ),
                              Gap(16.h),
                              CustomTextField(
                                textController: _nostrAddressController,
                                padding: EdgeInsets.zero,
                                autofocus: false,
                                hintText: 'satoshi@nakamoto.com',
                                label: 'Nostr Address (NIP-05)',
                              ),
                              Gap(16.h),
                              CustomTextField(
                                textController: _lightningAddressController,
                                padding: EdgeInsets.zero,
                                autofocus: false,
                                hintText: 'satoshi@nakamoto.com',
                                label: 'Lightning Address',
                              ),
                              Gap(32.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16.h,
                  left: 0.w,
                  right: 0.w,
                  child: CustomFilledButton(
                    onPressed: profileState.isLoading ? null : _saveChanges,
                    title:
                        profileState.isLoading ? 'Saving...' : 'Save Changes',
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
