import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/shared/custom_bottom_sheet.dart';
import 'package:whitenoise/shared/custom_button.dart';
import 'package:whitenoise/shared/custom_textfield.dart';

class GroupChatDetailsSheet extends StatefulWidget {
  final List<ContactModel> selectedContacts;
  
  const GroupChatDetailsSheet({
    super.key,
    required this.selectedContacts,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ContactModel> selectedContacts,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Group chat details',
      heightFactor: 0.9,
      backgroundColor: Colors.white,
      builder: (context) => GroupChatDetailsSheet(
        selectedContacts: selectedContacts,
      ),
    );
  }

  @override
  State<GroupChatDetailsSheet> createState() => _GroupChatDetailsSheetState();
}

class _GroupChatDetailsSheetState extends State<GroupChatDetailsSheet> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _hasGroupImage = false;
  bool _isGroupNameValid = false;
  
  @override
  void initState() {
    super.initState();
    _groupNameController.addListener(_onGroupNameChanged);
  }
  
  void _onGroupNameChanged() {
    final isValid = _groupNameController.text.trim().isNotEmpty;
    if (isValid != _isGroupNameValid) {
      setState(() {
        _isGroupNameValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.removeListener(_onGroupNameChanged);
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _hasGroupImage = !_hasGroupImage;
              });
            },
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.colorE2E2E2,
                shape: BoxShape.circle,
              ),
              child: _hasGroupImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(40.r),
                      child: Image.asset(
                       AssetsPaths.icWhiteNoise,
                        fit: BoxFit.cover,
                      ),
                    )
                  : SvgPicture.asset(
                      AssetsPaths.icCamera,
                      width: 42.w,
                      height: 42.w,
                      colorFilter: ColorFilter.mode(AppColors.color727772, BlendMode.srcIn),
                    ),
            ),
          ),
        ),
        Gap(24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group chat name',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.color202320,
                ),
              ),
              Gap(8.h),
              CustomTextField(
                textController: _groupNameController,
                hintText: 'Enter group name',
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        Gap(24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Members',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.color202320,
            ),
          ),
        ),
        Gap(8.h),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: widget.selectedContacts.length,
            itemBuilder: (context, index) {
              final contact = widget.selectedContacts[index];
              return ContactListTile(
                contact: contact,
              );
            },
          ),
        ),    
        SafeArea(
          child: CustomButton(
            onPressed: _isGroupNameValid ? () {
              final groupName = _groupNameController.text.trim();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created group "$groupName" with ${widget.selectedContacts.length} members'),
                ),
              );
            } : null,
            title: 'Create Group',
          ),
        ),
      ],
    );
  }
}
