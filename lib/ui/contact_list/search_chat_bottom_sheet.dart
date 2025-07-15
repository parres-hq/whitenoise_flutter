import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/chat_model.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/contact_loading_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class SearchChatBottomSheet extends ConsumerStatefulWidget {
  const SearchChatBottomSheet({super.key});

  @override
  ConsumerState<SearchChatBottomSheet> createState() => _SearchChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Search',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (_) => const SearchChatBottomSheet(),
    );
  }
}

class _SearchChatBottomSheetState extends ConsumerState<SearchChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _hasSearchResults = false;
  final Map<String, PublicKey> _publicKeyMap = {}; // Map ContactModel.publicKey to real PublicKey
  final _logger = Logger('SearchChatBottomSheet');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);
    // Load contacts when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContacts();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScrollChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _hasSearchResults = _searchQuery.isNotEmpty;
    });
  }

  void _onScrollChanged() {
    // Unfocus the text field when user starts scrolling
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _loadContacts() async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccountData != null) {
        _logger.info('SearchChatBottomSheet: Found active account: ${activeAccountData.pubkey}');
        await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
        _logger.info('SearchChatBottomSheet: Contacts loaded successfully');
      } else {
        _logger.severe('SearchChatBottomSheet: No active account found');
        if (mounted) {
          ref.showErrorToast('No active account found');
        }
      }
    } catch (e) {
      _logger.severe('SearchChatBottomSheet: Error loading contacts: $e');
      if (mounted) {
        ref.showErrorToast('Error loading contacts: $e');
      }
    }
  }

  List<ContactModel> _getFilteredContacts(Map<PublicKey, MetadataData?>? contacts) {
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
    // No dummy chats anymore - return empty list
    return [];
  }

  Future<void> _handleContactTap(ContactModel contact) async {
    _logger.info('Starting chat flow with contact: ${contact.publicKey}');

    try {
      // Show the loading bottom sheet immediately
      if (mounted) {
        ContactLoadingBottomSheet.show(
          context: context,
          contact: contact,
          onChatCreated: (groupData) {
            // Close the parent search bottom sheet when chat is created
            Navigator.pop(context);
          },
          onInviteSent: () {
            // Close the parent search bottom sheet when invite is sent
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      _logger.severe('Error handling contact tap: $e');
      if (mounted) {
        ref.showErrorToast('Failed to start chat: $e');
      }
    }
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
          focusNode: _searchFocusNode,
          hintText: 'Search contacts and chats...',
        ),
        if (_hasSearchResults) ...[
          Expanded(
            child: ListView(
              controller: _scrollController,
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
                            chat.imagePath.isNotEmpty ? AssetImage(chat.imagePath) : null,
                        backgroundColor: Colors.orange,
                        child:
                            chat.imagePath.isEmpty
                                ? Text(
                                  chat.name.isNotEmpty ? chat.name[0].toUpperCase() : '?',
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
                      onTap: () => _handleContactTap(contact),
                      onDelete: () async {
                        try {
                          // Get the real PublicKey from our map
                          final realPublicKey = _publicKeyMap[contact.publicKey];
                          if (realPublicKey != null) {
                            // Use the proper method to remove contact from Rust backend
                            await ref
                                .read(contactsProvider.notifier)
                                .removeContactByPublicKey(realPublicKey);

                            if (context.mounted) {
                              ref.showSuccessToast('Contact removed successfully');
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ref.showErrorToast('Failed to remove contact: $e');
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
