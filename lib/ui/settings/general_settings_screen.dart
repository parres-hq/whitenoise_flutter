import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/settings/profile/add_profile_bottom_sheet.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _profileExpanded = true;
  bool _privacyExpanded = false;
  bool _developerExpanded = false;

  void _deleteAllData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("All data deleted")));
  }

  void _publishKeyPackage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Key package event published")),
    );
  }

  void _deleteKeyPackages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All key package events deleted")),
    );
  }

  void _testNotifications() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Test notification sent")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.color202320,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.h,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
              Gap(16.w),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),

      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader('Profile', _profileExpanded, () {
                setState(() => _profileExpanded = !_profileExpanded);
              }),
              if (_profileExpanded)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: GestureDetector(
                    onTap: () => AddProfileBottomSheet.show(context: context),
                    child: SvgPicture.asset(AssetsPaths.icAdd, height: 16.5.w, width: 16.5.w),
                  ),
                ),
            ],
          ),
          if (_profileExpanded) ...[
            ContactListTile(
              contact: ContactModel(
                name: 'Profile',
                email: 'profile@whitenoise.com',
                publicKey: 'npub1  klkk3  vrzme  455yh  9rl2j  shq7r  c8dpe  gj3nd f82c3  ks2sk  7qulx  40dxt 3vt',
                imagePath: '',
              ),
              showExpansionArrow: true,
            ),
            _settingsRow(Icons.person_outline, 'Edit Profile', () {}),
            _settingsRow(Icons.vpn_key_outlined, 'Nostr keys', () {}),
            _settingsRow(Icons.network_wifi, 'Network', () {}),
            _settingsRow(
              Icons.account_balance_wallet_outlined,
              'Wallet',
              () {},
            ),
            _settingsRow(Icons.logout, 'Sign out', () {}),
            Gap(32.h),
          ] else
            Gap(40.h),

          _sectionHeader('Privacy & Security', _privacyExpanded, () {
            setState(() => _privacyExpanded = !_privacyExpanded);
          }),
          if (_privacyExpanded) ...[
            _settingsRow(
              Icons.delete_outline,
              'Delete all data',
              _deleteAllData,
            ),
            Gap(32.h),
          ] else
            Gap(40.h),

          _sectionHeader('Developer Settings', _developerExpanded, () {
            setState(() => _developerExpanded = !_developerExpanded);
          }),
          if (_developerExpanded) ...[
            _settingsRow(
              Icons.vpn_key_outlined,
              'Publish a key package event',
              _publishKeyPackage,
            ),
            _settingsRow(
              Icons.delete_outline,
              'Delete all key package events',
              _deleteKeyPackages,
            ),
            _settingsRow(
              Icons.notifications_none,
              'Test Notifications',
              _testNotifications,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool expanded, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: expanded ? 12.h : 0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }

  Widget _settingsRow(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: AppColors.color727772),
            Gap(12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 17.sp, color: AppColors.color727772),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
