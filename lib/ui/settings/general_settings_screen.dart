import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/network/network_screen.dart';
import 'package:whitenoise/ui/settings/nostr_keys/nostr_keys_screen.dart';
import 'package:whitenoise/ui/settings/profile/add_profile_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/profile/edit_profile_screen.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _profileExpanded = true;
  bool _privacyExpanded = false;
  bool _developerExpanded = false;

  ContactModel _currentProfile = dummyContacts.first;

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
      appBar: CustomAppBar(title: 'Settings'),
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
              contact: _currentProfile,
              showExpansionArrow: dummyContacts.length > 1,
              onTap: () {
                if (dummyContacts.length > 1) {
                  SwitchProfileBottomSheet.show(
                    context: context,
                    profiles: dummyContacts,
                    onProfileSelected: (selectedProfile) {
                      setState(() {
                        _currentProfile = selectedProfile;
                      });
                    },
                  );
                }
              },
            ),
            _settingsRow(Icons.person_outline, 'Edit Profile', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(profile: _currentProfile)),
              );
            }),
            _settingsRow(Icons.vpn_key_outlined, 'Nostr keys', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NostrKeysScreen()),
              );
            }),
            _settingsRow(Icons.network_wifi, 'Network', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NetworkScreen()),
              );
            }),
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
            Icon(icon, size: 22.sp, color: AppColors.glitch600),
            Gap(12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 17.sp, color: AppColors.glitch600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
