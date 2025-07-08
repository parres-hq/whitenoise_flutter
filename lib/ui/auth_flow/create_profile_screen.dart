import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/app_text_form_field.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ref.showRawErrorToast('Failed to pick image: $e');
    }
  }

  Future<void> _onFinishPressed() async {
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.isEmpty) {
      ref.showRawErrorToast('Please enter a name');
      return;
    }

    try {
      String? profilePictureUrl;

      // Upload profile image if one was selected
      if (_selectedImagePath != null) {
        // Get file extension to determine image type
        final fileExtension = path.extension(_selectedImagePath!);
        final imageType = await imageTypeFromExtension(extension_: fileExtension);

        // Get active account public key
        final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
        if (activeAccount == null) {
          ref.showRawErrorToast('No active account found');
          return;
        }

        final serverUrl = await getDefaultBlossomServerUrl();
        final publicKey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);

        // Upload the image to Blossom server
        profilePictureUrl = await uploadProfilePicture(
          pubkey: publicKey,
          serverUrl: serverUrl,
          filePath: _selectedImagePath!,
          imageType: imageType,
        );
      }

      // Update account metadata using the account provider
      await ref
          .read(accountProvider.notifier)
          .updateAccountMetadata(
            username,
            bio,
            profilePictureUrl: profilePictureUrl,
          );
      if (!mounted) return;
      context.go('/chats');
    } catch (e) {
      if (!mounted) return;
      final error = e as WhitenoiseErrorImpl;
      final errorMessage = await whitenoiseErrorToString(error: error);
      ref.showRawErrorToast('Failed to create profile: $errorMessage');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _usernameController.text = ref.read(accountProvider).metadata?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 0),
          child: Column(
            children: [
              Text(
                'Setup Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(48.h),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _usernameController,
                    builder: (context, value, child) {
                      final displayText = value.text.trim();
                      final firstLetter =
                          displayText.isNotEmpty ? displayText[0].toUpperCase() : '';
                      return CircleAvatar(
                        radius: 48.r,
                        backgroundColor: context.colors.primarySolid,
                        backgroundImage:
                            _selectedImagePath != null
                                ? FileImage(File(_selectedImagePath!))
                                : null,
                        child:
                            _selectedImagePath == null
                                ? (firstLetter.isNotEmpty
                                    ? Text(
                                      firstLetter,
                                      style: TextStyle(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.w700,
                                        color: context.colors.primaryForeground,
                                      ),
                                    )
                                    : Icon(
                                      CarbonIcons.user,
                                      size: 32.sp,
                                      color: context.colors.primaryForeground,
                                    ))
                                : null,
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _pickProfileImage,
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
                      child: SvgPicture.asset(
                        AssetsPaths.icEdit,
                        colorFilter: ColorFilter.mode(
                          context.colors.primaryForeground,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Gap(36.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: context.colors.primary,
                  ),
                ),
              ),
              Gap(10.h),
              AppTextFormField(
                hintText: 'Free Citizen',
                obscureText: false,
                controller: _usernameController,
              ),
              Gap(36.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Introduce yourself',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: context.colors.primary,
                  ),
                ),
              ),
              Gap(8.h),
              AppTextFormField(
                hintText: 'Write something about yourself',
                obscureText: false,
                controller: _bioController,
                maxLines: 3,
                minLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              Gap(32.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
          ).copyWith(bottom: 32.h),
          child: AppFilledButton(
            onPressed: _onFinishPressed,
            title: 'Finish',
          ),
        ),
      ),
    );
  }
}
