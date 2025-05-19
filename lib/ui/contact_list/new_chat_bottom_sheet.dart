import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/contact_list/new_group_chat_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NewChatBottomSheet extends StatefulWidget {
  const NewChatBottomSheet({super.key});

  @override
  State<NewChatBottomSheet> createState() => _NewChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'New chat',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => const NewChatBottomSheet(),
    );
  }
}

class _NewChatBottomSheetState extends State<NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ContactModel> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredContacts = _getFilteredContacts();
    });
  }

  List<ContactModel> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return dummyContacts;
    return dummyContacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomTextField(
          textController: _searchController,
          hintText: 'Search contact or public key...',
        ),
        Gap(16.h),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            NewGroupChatSheet.show(context);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              children: [
                SvgPicture.asset(
                  AssetsPaths.icGroupChat,
                  colorFilter: ColorFilter.mode(AppColors.color727772, BlendMode.srcIn),
                  width: 20.w,
                  height: 20.w,
                ),
                Gap(10.w),
                Expanded(child: Text('New Group Chat', style: TextStyle(color: AppColors.color727772, fontSize: 18.sp))),
                SvgPicture.asset(
                  AssetsPaths.icChevronRight,
                  colorFilter: ColorFilter.mode(AppColors.color727772, BlendMode.srcIn),
                  width: 8.55.w,
                  height: 15.w,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: _filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];
              return ContactListTile(
                contact: contact,
                onTap: () {
                  StartSecureChatBottomSheet.show(
                    context: context,
                    name: contact.name,
                    email: contact.email,
                    publicKey: contact.publicKey,
                    onStartChat: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Started secure chat with ${contact.name}',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
