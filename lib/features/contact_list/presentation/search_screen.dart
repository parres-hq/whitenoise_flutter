import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/core/utils/app_colors.dart';
import 'package:whitenoise/features/contact_list/models/chat_model.dart';
import 'package:whitenoise/features/contact_list/data/dummy_data.dart';
import 'package:whitenoise/features/contact_list/presentation/widgets/chat_list_tile.dart';
import 'package:whitenoise/features/contact_list/presentation/widgets/contact_list_tile.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SearchBottomSheet(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutQuad);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasSearchResults = false;

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
    });
  }

  List<ChatModel> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return [];
    return dummyContacts.where((contact) => contact.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<ChatModel> _getFilteredChats() {
    if (_searchQuery.isEmpty) return [];
    return dummyChats
        .where(
          (chat) =>
              chat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _getFilteredContacts();
    final filteredChats = _getFilteredChats();

    final bottomSheetHeight = 1.sh * 0.9;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black.withValues(alpha: 0.1)),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: bottomSheetHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 16.h, 16.w, 24.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Search', style: TextStyle(color: Colors.black, fontSize: 24.sp)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.close, color: Colors.black, size: 24.w),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search contacts or chats...',
                            hintStyle: TextStyle(color: AppColors.color727772, fontSize: 14.sp),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.colorE2E2E2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.colorE2E2E2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.colorE2E2E2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          ),
                        ),
                      ),
                      if (_hasSearchResults) ...[
                        if (filteredContacts.isNotEmpty) ...[
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
                            itemCount: filteredContacts.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              return ContactListTile(contact: contact);
                            },
                          ),
                          Gap(24.h),
                        ],
                        if (filteredChats.isNotEmpty) ...[
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
                              itemCount: filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = filteredChats[index];
                                return ChatListTile(chat: chat);
                              },
                            ),
                          ),
                        ],
                        if (filteredContacts.isEmpty && filteredChats.isEmpty)
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
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
