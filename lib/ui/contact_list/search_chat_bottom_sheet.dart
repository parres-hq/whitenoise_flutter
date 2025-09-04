import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/domain/models/chat_model.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

class SearchChatBottomSheet extends ConsumerStatefulWidget {
  const SearchChatBottomSheet({super.key});

  @override
  ConsumerState<SearchChatBottomSheet> createState() => _SearchChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return WnBottomSheet.show(
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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';

      if (activePubkey.isNotEmpty) {
        _logger.info('SearchChatBottomSheet: Found active account: $activePubkey');
        await ref.read(followsProvider.notifier).loadFollows();
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

  List<ChatModel> _getFilteredChats() {
    // No dummy chats anymore - return empty list
    return [];
  }

  Future<void> _handleContactTap(ContactModel contact) async {
    _logger.info('Starting chat flow with contact: ${contact.publicKey}');

    try {
      // Show the loading bottom sheet immediately
      if (mounted) {
        StartChatBottomSheet.show(
          context: context,
          contact: contact,
          onChatCreated: (group) {
            // Close the parent search bottom sheet when chat is created
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
    final followsState = ref.watch(followsProvider);
    final followsNotifier = ref.read(followsProvider.notifier);
    final filteredFollows =
        _searchQuery.isEmpty
            ? followsState.follows
            : followsNotifier.getFilteredFollows(_searchQuery);
    final filteredContacts =
        filteredFollows
            .map(
              (follow) =>
                  ContactModel.fromMetadata(pubkey: follow.pubkey, metadata: follow.metadata),
            )
            .toList();
    final filteredChats = _getFilteredChats();

    return Column(
      children: [
        WnTextField(
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
                          await ref.read(followsProvider.notifier).removeFollow(contact.publicKey);

                          if (context.mounted) {
                            ref.showSuccessToast('Contact removed successfully');
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
