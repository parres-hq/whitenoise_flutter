import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/create_profile_screen_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
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
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
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
                      return WnAvatar(
                        imageUrl: ref.watch(createProfileScreenProvider).selectedImagePath ?? '',
                        displayName: displayText,
                        size: 96.w,
                        showBorder:
                            ref.watch(createProfileScreenProvider).selectedImagePath == null,
                      );
                    },
                  ),
                  GestureDetector(
                    onTap:
                        () => ref.read(createProfileScreenProvider.notifier).pickProfileImage(ref),
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
              final createProfileState = ref.watch(createProfileScreenProvider);
              final isButtonDisabled = createProfileState.isLoading || _isLoadingDisplayName;

              return WnFilledButton(
                label: 'Finish',
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
    );
  }
}
