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
            onPressed:
                () => ref
                    .read(accountProvider.notifier)
                    .updateAccountMetadata(
                      ref,
                      _usernameController.text.trim(),
                      _bioController.text.trim(),
                    ),
            title: 'Finish',
          ),
        ),
      ),
    );
  }
}
