import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoadingDisplayName = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Try to load existing metadata first
      final currentMetadata = ref.read(accountProvider).metadata;
      if (currentMetadata?.displayName != null && currentMetadata!.displayName!.isNotEmpty) {
        _displayNameController.text = currentMetadata.displayName!;
        setState(() {
          _isLoadingDisplayName = false;
        });
      } else {
        // If no metadata, try to load it
        await ref.read(accountProvider.notifier).loadAccountData();
        final newMetadata = ref.read(accountProvider).metadata;
        if (newMetadata?.displayName != null && newMetadata!.displayName!.isNotEmpty) {
          _displayNameController.text = newMetadata.displayName!;
          setState(() {
            _isLoadingDisplayName = false;
          });
        }
        // Keep loading if no displayName is found - don't stop loading
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to account provider changes and update displayName when metadata is loaded
    ref.listen<AccountState>(accountProvider, (previous, next) {
      if (next.metadata?.displayName != null &&
          next.metadata!.displayName!.isNotEmpty &&
          _displayNameController.text.isEmpty) {
        _displayNameController.text = next.metadata!.displayName!;
        setState(() {
          _isLoadingDisplayName = false;
        });
      }
    });

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
                    valueListenable: _displayNameController,
                    builder: (context, value, child) {
                      final displayText = value.text.trim();
                      final firstLetter =
                          displayText.isNotEmpty ? displayText[0].toUpperCase() : '';
                      return CircleAvatar(
                        radius: 48.r,
                        backgroundColor: context.colors.primarySolid,
                        backgroundImage:
                            ref.watch(accountProvider).selectedImagePath != null
                                ? FileImage(File(ref.watch(accountProvider).selectedImagePath!))
                                : null,
                        child:
                            ref.watch(accountProvider).selectedImagePath == null
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
                    onTap: () => ref.read(accountProvider.notifier).pickProfileImage(ref),
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
                    hintText: 'Your name',
                    obscureText: false,
                    controller: _displayNameController,
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
              WnTextFormField(
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
          child: Consumer(
            builder: (context, ref, child) {
              final accountState = ref.watch(accountProvider);
              final isButtonDisabled = accountState.isLoading || _isLoadingDisplayName;

              return WnFilledButton(
                title: 'Finish',
                loading: isButtonDisabled,
                onPressed:
                    isButtonDisabled
                        ? null
                        : () => ref
                            .read(accountProvider.notifier)
                            .updateAccountMetadata(
                              ref,
                              _displayNameController.text.trim(),
                              _bioController.text.trim(),
                            ),
              );
            },
          ),
        ),
      ),
    );
  }
}
