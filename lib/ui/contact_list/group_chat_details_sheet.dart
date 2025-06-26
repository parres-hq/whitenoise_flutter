import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class GroupChatDetailsSheet extends ConsumerStatefulWidget {
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
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      barrierColor: Colors.transparent,
      builder:
          (context) => GroupChatDetailsSheet(
            selectedContacts: selectedContacts,
          ),
    );
  }

  @override
  ConsumerState<GroupChatDetailsSheet> createState() => _GroupChatDetailsSheetState();
}

class _GroupChatDetailsSheetState extends ConsumerState<GroupChatDetailsSheet> {
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

  void _createGroupChat() async {
    if (!_isGroupNameValid) return;
    final groupName = _groupNameController.text.trim();

    final groupData = await ref
        .read(groupsProvider.notifier)
        .createNewGroup(
          groupName: groupName,
          groupDescription: '',
          memberPublicKeyHexs: widget.selectedContacts.map((c) => c.publicKey).toList(),
          adminPublicKeyHexs: [],
        );

    if (mounted) {
      if (groupData != null) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to create group chat. Please try again.'),
            backgroundColor: context.colors.destructive,
          ),
        );
        debugPrint('Failed to create group chat with name: $groupName');
      }
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.colors.baseMuted,
                shape: BoxShape.circle,
              ),
              child:
                  _hasGroupImage
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
                        colorFilter: ColorFilter.mode(
                          context.colors.mutedForeground,
                          BlendMode.srcIn,
                        ),
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
                  color: context.colors.primary,
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
              color: context.colors.primary,
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
              return ContactListTile(contact: contact);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(bottom: 16.h),
            child: AppFilledButton(
              onPressed: () => _createGroupChat(),
              title: 'Create Group',
            ),
          ),
        ),
      ],
    );
  }
}
