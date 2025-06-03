import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/profile/add_profile_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';
import 'package:whitenoise/routing/routes.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  ContactModel _currentProfile = dummyContacts.first;

  void _deleteAllData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data deleted")));
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test notification sent")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        children: [
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: () => AddProfileBottomSheet.show(context: context),
                child: Row(
                  children: [
                    Text('Add Profile', style: TextStyle(fontSize: 18.sp, color: AppColors.glitch600)),
                    Gap(12.w),
                    SvgPicture.asset(AssetsPaths.icAdd, height: 16.w, width: 16.w),
                  ],
                ),
              ),
            ],
          ),
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
          SettingsListTile(
            icon: CarbonIcons.user,
            text: 'Edit Profile',
            onTap: () => context.push('${Routes.settings}/profile'),
          ),
          SettingsListTile(
            icon: CarbonIcons.password,
            text: 'Nostr keys',
            onTap: () => context.push('${Routes.settings}/keys'),
          ),
          SettingsListTile(
            icon: CarbonIcons.satellite,
            text: 'Network',
            onTap: () => context.push('${Routes.settings}/network'),
          ),
          SettingsListTile(
            icon: CarbonIcons.wallet,
            text: 'Wallet',
            onTap: () => context.push('${Routes.settings}/wallet'),
          ),
          SettingsListTile(
            icon: CarbonIcons.logout,
            text: 'Sign out',
            onTap: () {},
          ),
          SettingsListTile(
            icon: CarbonIcons.delete,
            text: 'Delete all data',
            onTap: _deleteAllData,
          ),
          SettingsListTile(
            icon: CarbonIcons.password,
            text: 'Publish a key package event',
            onTap: _publishKeyPackage,
          ),
          SettingsListTile(
            icon: CarbonIcons.delete,
            text: 'Delete all key package events',
            onTap: _deleteKeyPackages,
          ),
          SettingsListTile(
            icon: CarbonIcons.notification,
            text: 'Test Notifications',
            onTap: _testNotifications,
          ),
        ],
      ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 24.w, color: AppColors.glitch600),
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
