import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/new_group_chat_sheet.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NewChatBottomSheet extends ConsumerStatefulWidget {
  const NewChatBottomSheet({super.key});

  @override
  ConsumerState<NewChatBottomSheet> createState() => _NewChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'New chat',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => const NewChatBottomSheet(),
    );
  }
}

class _NewChatBottomSheetState extends ConsumerState<NewChatBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final _logger = Logger('NewChatBottomSheet');

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
    });
  }

  Future<void> _loadContacts() async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccountData != null) {
        _logger.info('NewChatBottomSheet: Found active account: ${activeAccountData.pubkey}');
        await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
        _logger.info('NewChatBottomSheet: Contacts loaded successfully');
      } else {
        _logger.severe('NewChatBottomSheet: No active account found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No active account found'),
              backgroundColor: context.colors.destructive,
            ),
          );
        }
      }
    } catch (e) {
      _logger.severe('NewChatBottomSheet: Error loading contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: context.colors.destructive,
          ),
        );
      }
    }
  }

  bool _isValidPublicKey(String input) {
    final trimmed = input.trim();
    // Check if it's a hex key (64 characters) or npub format
    return (trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) ||
        (trimmed.startsWith('npub1') && trimmed.length > 10);
  }

  Future<void> _addNewContact(String publicKey) async {
    try {
      await ref.read(contactsProvider.notifier).addContactByHex(publicKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact added successfully')),
        );
        // Clear search and reload
        _searchController.clear();
        setState(() => _searchQuery = '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add contact: $e')));
      }
    }
  }

  List<ContactModel> _getFilteredContacts(List<ContactModel>? contacts) {
    if (contacts == null) return [];

    if (_searchQuery.isEmpty) return contacts;

    return contacts
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

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = _getFilteredContacts(contactsState.contactModels);

    final showAddOption =
        _searchQuery.isNotEmpty && _isValidPublicKey(_searchQuery) && filteredContacts.isEmpty;

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
                  colorFilter: ColorFilter.mode(
                    context.colors.mutedForeground,
                    BlendMode.srcIn,
                  ),
                  width: 20.w,
                  height: 20.w,
                ),
                Gap(10.w),
                Expanded(
                  child: Text(
                    'New Group Chat',
                    style: TextStyle(
                      color: context.colors.mutedForeground,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  AssetsPaths.icChevronRight,
                  colorFilter: ColorFilter.mode(
                    context.colors.mutedForeground,
                    BlendMode.srcIn,
                  ),
                  width: 8.55.w,
                  height: 15.w,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child:
              contactsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contactsState.error != null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading contacts',
                          style: TextStyle(
                            color: context.colors.mutedForeground,
                            fontSize: 16.sp,
                          ),
                        ),
                        Gap(8.h),
                        Text(
                          contactsState.error!,
                          style: TextStyle(
                            color: context.colors.mutedForeground,
                            fontSize: 12.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Gap(16.h),
                        ElevatedButton(
                          onPressed: _loadContacts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : Column(
                    children: [
                      // Show "Add as contact" option if valid public key and no matches
                      if (showAddOption) ...[
                        GestureDetector(
                          onTap: () => _addNewContact(_searchQuery),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primaryForeground,
                              border: Border.all(
                                color: context.colors.baseMuted,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  color: context.colors.mutedForeground,
                                  size: 20.w,
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add as contact',
                                        style: TextStyle(
                                          color: context.colors.secondaryForeground,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _searchQuery.length > 20
                                            ? '${_searchQuery.substring(0, 20)}...'
                                            : _searchQuery,
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Gap(16.h),
                      ],

                      // Contacts list
                      Expanded(
                        child:
                            filteredContacts.isEmpty && !showAddOption
                                ? Center(
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? 'No contacts found'
                                        : 'No contacts match your search',
                                    style: TextStyle(
                                      color: context.colors.mutedForeground,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  itemCount: filteredContacts.length,
                                  itemBuilder: (context, index) {
                                    final contact = filteredContacts[index];
                                    return ContactListTile(
                                      contact: contact,
                                      enableSwipeToDelete: true,
                                      onTap: () {
                                        StartSecureChatBottomSheet.show(
                                          context: context,
                                          name: contact.displayNameOrName,
                                          nip05: contact.nip05 ?? '',
                                          pubkey: contact.publicKey,
                                          bio: contact.about,
                                          imagePath: contact.imagePath,
                                          onChatCreated: () {
                                            // Chat created successfully, close the new chat bottom sheet
                                            Navigator.pop(context);
                                          },
                                        );
                                      },
                                      onDelete: () async {
                                        try {
                                          // Get the real PublicKey from the provider
                                          final realPublicKey = ref
                                              .read(contactsProvider.notifier)
                                              .getPublicKeyForContact(contact.publicKey);
                                          if (realPublicKey != null) {
                                            await ref
                                                .read(contactsProvider.notifier)
                                                .removeContactByPublicKey(realPublicKey);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Contact removed successfully'),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to remove contact: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}
