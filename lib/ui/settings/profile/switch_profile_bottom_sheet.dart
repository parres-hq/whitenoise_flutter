import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';

class SwitchProfileBottomSheet extends StatelessWidget {
  final List<ContactModel> profiles;
  final Function(ContactModel) onProfileSelected;

  const SwitchProfileBottomSheet({
    super.key,
    required this.profiles,
    required this.onProfileSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> profiles,
    required Function(ContactModel) onProfileSelected,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Switch profile',
      heightFactor: 0.32,
      backgroundColor: Colors.white,
      builder: (context) => SwitchProfileBottomSheet(
        profiles: profiles,
        onProfileSelected: onProfileSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return ContactListTile(
          contact: profile,
          onTap: () {
            onProfileSelected(profile);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
