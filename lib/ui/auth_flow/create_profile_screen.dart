import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _onFinishPressed() async {
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();
    // TODO: authProvider
    await ref.read(accountProvider.notifier).updateAccountMetadata(username, bio);
    if (username.isNotEmpty) {
      if (!mounted) return;
      context.go('/chats');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a name')));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // TODO: optimising this in the next PR - unify auth and acct, single provider for current account.
      await ref.read(accountProvider.notifier).loadAccountData();
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
                  CircleAvatar(
                    radius: 48.r,
                    backgroundImage: const AssetImage(
                      AssetsPaths.profileBackground,
                    ),
                  ),
                  Container(
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
                ],
              ),
              Gap(12.h),
              Text(
                'Upload Avatar',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primary,
                ),
              ),
              Gap(32.h),
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
