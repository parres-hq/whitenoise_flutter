import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';
import 'package:whitenoise/ui/settings/profile/widgets/edit_icon.dart';

class EditProfileScreen extends StatefulWidget {
  final ContactModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _aboutController;
  late TextEditingController _websiteController;
  late TextEditingController _nostrAddressController;
  late TextEditingController _lightningAddressController;

  String _profileImagePath = '';
  final _bannerImagePath = '';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: '@satoshi');
    _displayNameController = TextEditingController(text: 'Satoshi Nakamoto');
    _aboutController = TextEditingController(text: 'A few words about you');
    _websiteController = TextEditingController(text: 'https://');
    _nostrAddressController = TextEditingController(text: 'satoshi@nakamoto.com');
    _lightningAddressController = TextEditingController(text: 'satoshi@nakamoto.com');
    _profileImagePath = widget.profile.imagePath;
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

  void _saveChanges() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: 'Profile'),
      body: Column(
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
                        color: AppColors.glitch200.withValues(alpha: 0.5),
                        image:
                            _bannerImagePath.isNotEmpty
                                ? DecorationImage(image: AssetImage(_bannerImagePath), fit: BoxFit.cover)
                                : null,
                      ),
                      child: Image.asset(AssetsPaths.profileBackground, fit: BoxFit.cover),
                    ),
                    Positioned(right: 16.w, top: 16.h, child: EditIconWidget()),
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
                        decoration: BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        child: Container(
                          width: 80.w,
                          height: 80.w,
                          margin: EdgeInsets.all(5.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image:
                                _profileImagePath.isNotEmpty
                                    ? DecorationImage(image: AssetImage(_profileImagePath), fit: BoxFit.cover)
                                    : null,
                          ),
                          child:
                              _profileImagePath.isEmpty
                                  ? Center(
                                    child: Text(
                                      'S',
                                      style: TextStyle(
                                        fontSize: 32.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.glitch600,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      Positioned(left: 1.sw * 0.5 + 2.w, bottom: 4.h, width: 24.w, child: EditIconWidget()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFilledButton(onPressed: _saveChanges, title: 'Save Changes'),
    );
  }
}
