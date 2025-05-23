import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/chat_model.dart';
import 'package:whitenoise/domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/domain/dummy_data/dummy_chats.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';

class SearchChatBottomSheet extends StatefulWidget {
  const SearchChatBottomSheet({super.key});

  @override
  State<SearchChatBottomSheet> createState() => _SearchChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Search',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      blurBackground: true,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (_) => const SearchChatBottomSheet(),
    );
  }
}

class _SearchChatBottomSheetState extends State<SearchChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasSearchResults = false;
  List<ContactModel> _filteredContacts = [];
  List<ChatModel> _filteredChats = [];

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
      _hasSearchResults = _searchQuery.isNotEmpty;
      _filteredContacts = _getFilteredContacts();
      _filteredChats = _getFilteredChats();
    });
  }

  List<ContactModel> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return [];
    return dummyContacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<ChatModel> _getFilteredChats() {
    if (_searchQuery.isEmpty) return [];
    return dummyChats
        .where(
          (chat) =>
              chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              chat.lastMessage.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          textController: _searchController,
          hintText: 'Search contacts or chats...',
        ),
        if (_hasSearchResults) ...[
          if (_filteredContacts.isNotEmpty) ...[
            Gap(24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Contacts', style: TextStyle(fontSize: 24.sp)),
              ),
            ),
            ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _filteredContacts.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return ContactListTile(contact: contact);
              },
            ),
          ],
          Gap(24.h),
          if (_filteredChats.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Chats', style: TextStyle(fontSize: 24.sp)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = _filteredChats[index];
                  return ChatListTile(chat: chat);
                },
              ),
            ),
          ],
          if (_filteredContacts.isEmpty && _filteredChats.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No results found for "$_searchQuery"',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
              ),
            ),
        ],
        if (!_hasSearchResults) ...[
          Expanded(
            child: Center(
              child: Text(
                'Type to search contacts or chats',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
