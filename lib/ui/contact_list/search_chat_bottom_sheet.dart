import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/models/chat_model.dart';
import 'package:whitenoise/domain/dummy_data/dummy_chats.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class SearchChatBottomSheet extends ConsumerStatefulWidget {
  const SearchChatBottomSheet({super.key});

  @override
  ConsumerState<SearchChatBottomSheet> createState() =>
      _SearchChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Search',
      barrierColor: Colors.transparent,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (_) => const SearchChatBottomSheet(),
    );
  }
}

class _SearchChatBottomSheetState extends ConsumerState<SearchChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasSearchResults = false;
  final Map<String, PublicKey> _publicKeyMap =
      {}; // Map ContactModel.publicKey to real PublicKey

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load contacts when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
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

  Future<void> _loadContacts() async {
    try {
      final accountState = ref.read(accountProvider);

      // If pubkey is null, try to load the account first
      if (accountState.pubkey == null) {
        await ref.read(accountProvider.notifier).loadAccount();
        final updatedAccountState = ref.read(accountProvider);

        if (updatedAccountState.pubkey == null) {
          // Still no pubkey, show error
          // Handle error through proper method
          debugPrint('No active account found. Please login first.');
          return;
        }
      }

      final pubkey = ref.read(accountProvider).pubkey!;
      await ref.read(contactsProvider.notifier).loadContacts(pubkey);
    } catch (e) {
      debugPrint('Error loading contacts in search chat: $e');
      // Handle error through proper method
      debugPrint('Failed to load contacts: $e');
    }
  }

  List<ContactModel> _getFilteredContacts(Map<PublicKey, Metadata?>? contacts) {
    if (_searchQuery.isEmpty || contacts == null) return [];

    final contactModels = <ContactModel>[];
    for (final entry in contacts.entries) {
      final contactModel = ContactModel.fromMetadata(
        publicKey: entry.key.hashCode.toString(), // Temporary ID for UI
        metadata: entry.value,
      );
      // Store the real PublicKey reference for operations
      _publicKeyMap[contactModel.publicKey] = entry.key;
      contactModels.add(contactModel);
    }

    return contactModels
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              contact.displayNameOrName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (contact.nip05?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              contact.publicKey.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
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
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = _getFilteredContacts(contactsState.contacts);
    final filteredChats = _getFilteredChats();

    return Column(
      children: [
        CustomTextField(
          textController: _searchController,
          hintText: 'Search contacts and chats...',
        ),
        if (_hasSearchResults) ...[
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                // Chats section
                if (filteredChats.isNotEmpty) ...[
                  Gap(24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Chats', style: TextStyle(fontSize: 24.sp)),
                    ),
                  ),
                  ...filteredChats.map(
                    (chat) => ListTile(
                      leading: CircleAvatar(
                        radius: 20.r,
                        backgroundImage:
                            chat.imagePath.isNotEmpty
                                ? AssetImage(chat.imagePath)
                                : null,
                        backgroundColor: Colors.orange,
                        child:
                            chat.imagePath.isEmpty
                                ? Text(
                                  chat.name.isNotEmpty
                                      ? chat.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      title: Text(
                        chat.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chat.time,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (chat.unreadCount > 0) ...[
                            Gap(4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        // Handle chat tap
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],

                // Contacts section
                if (filteredContacts.isNotEmpty) ...[
                  Gap(24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Contacts',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                  ...filteredContacts.map(
                    (contact) => ContactListTile(
                      contact: contact,
                      enableSwipeToDelete: true,
                      onDelete: () async {
                        try {
                          // Get the real PublicKey from our map
                          final realPublicKey =
                              _publicKeyMap[contact.publicKey];
                          if (realPublicKey != null) {
                            // Use the proper method to remove contact from Rust backend
                            await ref
                                .read(contactsProvider.notifier)
                                .removeContactByPublicKey(realPublicKey);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact removed successfully'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to remove contact: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],

                // No results
                if (filteredChats.isEmpty && filteredContacts.isEmpty) ...[
                  Gap(100.h),
                  Center(
                    child: Text(
                      'No chats or contacts found for "$_searchQuery"',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (!_hasSearchResults) ...[
          Expanded(
            child: Center(
              child: Text(
                'Type to search contacts and chats',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
