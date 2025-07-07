import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/legacy_invite_bottom_sheet.dart';
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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final _logger = Logger('NewChatBottomSheet');
  ContactModel? _tempContact;
  bool _isLoadingMetadata = false;

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
      _tempContact = null;
    });

    // If it's a valid public key, fetch metadata
    if (_isValidPublicKey(_searchQuery)) {
      _fetchMetadataForPublicKey(_searchQuery);
    }
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
        _logger.info('NewChatBottomSheet: Found active account: ${activeAccountData.pubkey}');
        await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
        _logger.info('NewChatBottomSheet: Contacts loaded successfully');
      } else {
        _logger.severe('NewChatBottomSheet: No active account found');
        if (mounted) {
          ref.showErrorToast('No active account found');
        }
      }
    } catch (e) {
      _logger.severe('NewChatBottomSheet: Error loading contacts: $e');
      if (mounted) {
        ref.showErrorToast('Error loading contacts: $e');
      }
    }
  }

  bool _isValidPublicKey(String input) {
    final trimmed = input.trim();
    // Check if it's a hex key (64 characters) or npub format
    return (trimmed.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed)) ||
        (trimmed.startsWith('npub1') && trimmed.length > 10);
  }

  Future<void> _fetchMetadataForPublicKey(String publicKey) async {
    if (_isLoadingMetadata) return;

    setState(() {
      _isLoadingMetadata = true;
    });

    Event? keyPackage;
    try {
      final contactPk = await publicKeyFromString(publicKeyString: publicKey.trim());
      final metadata = await fetchMetadata(pubkey: contactPk);

      try {
        keyPackage = await fetchKeyPackage(pubkey: contactPk);
        _logger.info('Key package fetched: $keyPackage');
      } catch (e) {
        _logger.warning('Failed to fetch key package: $e');
        keyPackage = null;
      }

      if (mounted) {
        setState(() {
          _tempContact = ContactModel.fromMetadata(
            publicKey: publicKey.trim(),
            metadata: metadata,
          );
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      _logger.warning('Failed to fetch metadata for public key: $e');
      if (mounted) {
        setState(() {
          _tempContact = ContactModel(
            name: 'Unknown User',
            publicKey: publicKey.trim(),
          );
          _isLoadingMetadata = false;
        });
      }
    }
  }

  List<ContactModel> _getFilteredContacts(List<ContactModel>? contacts) {
    if (contacts == null) return [];

    // 1. Deduplicate contacts with the same publicKey
    final Map<String, ContactModel> uniqueContacts = {};
    for (final contact in contacts) {
      final normalizedKey = contact.publicKey.trim().toLowerCase();
      if (normalizedKey.isEmpty) continue;
      uniqueContacts.putIfAbsent(normalizedKey, () => contact);
    }

    final deduplicatedContacts = uniqueContacts.values.toList();

    // 2. If search is empty, return all deduplicated contacts
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return deduplicatedContacts;

    // 3. Filter by search query (null-safe)
    return deduplicatedContacts.where((contact) {
      final name = contact.name.toLowerCase();
      final displayNameOrName = contact.displayNameOrName.toLowerCase();
      final nip05 = contact.nip05?.toLowerCase() ?? '';
      final about = contact.about?.toLowerCase() ?? '';
      final publicKey = contact.publicKey.toLowerCase();

      return name.contains(query) ||
          displayNameOrName.contains(query) ||
          nip05.contains(query) ||
          about.contains(query) ||
          publicKey.contains(query);
    }).toList();
  }

  Future<void> _handleContactTap(ContactModel contact) async {
    _logger.info('Starting chat with contact: ${contact.publicKey}');

    try {
      final pubkey = await publicKeyFromString(publicKeyString: contact.publicKey);
      Event? keyPackage;

      try {
        keyPackage = await fetchKeyPackage(pubkey: pubkey);
      } catch (e) {
        _logger.warning('Failed to fetch key package: $e');
        keyPackage = null;
      }

      if (mounted) {
        _logger.info('Fetched key package: $keyPackage');

        if (keyPackage != null) {
          StartSecureChatBottomSheet.show(
            context: context,
            name: contact.displayNameOrName,
            nip05: contact.nip05 ?? '',
            pubkey: contact.publicKey,
            bio: contact.about,
            imagePath: contact.imagePath,
            onChatCreated: () {
              Navigator.pop(context);
            },
          );
        } else {
          LegacyInviteBottomSheet.show(
            context: context,
            name: contact.displayNameOrName,
            nip05: contact.nip05 ?? '',
            pubkey: contact.publicKey,
            bio: contact.about,
            imagePath: contact.imagePath,
            onInviteSent: () {
              Navigator.pop(context);
            },
          );
        }
      }
    } catch (e) {
      _logger.severe('Error handling contact tap: $e');
      if (mounted) {
        ref.showErrorToast('Failed to start chat: $e');
      }
    }
  }

  Widget _buildErrorWidget(String error) {
    return Center(
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
            error,
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
    );
  }

  Widget _buildLoadingContactTile() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: context.colors.baseMuted,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading metadata...',
                  style: TextStyle(
                    color: context.colors.mutedForeground,
                    fontSize: 16.sp,
                  ),
                ),
                Gap(2.h),
                Text(
                  _searchQuery.length > 20 ? '${_searchQuery.substring(0, 20)}...' : _searchQuery,
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
    );
  }

  Widget _buildMainOptions() {
    return Column(
      children: [
        // New Group Chat option
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
        // Help and Feedback option
        GestureDetector(
          onTap: () async {
            Navigator.pop(context);

            try {
              final contactPk = await publicKeyFromString(
                publicKeyString: kSupportNpub,
              );
              final metadata = await fetchMetadata(pubkey: contactPk);

              final supportContact = ContactModel.fromMetadata(
                publicKey: kSupportNpub,
                metadata: metadata,
              );

              if (context.mounted) {
                _handleContactTap(supportContact);
              }
            } catch (e) {
              _logger.warning('Failed to fetch metadata for public key: $e');

              final basicContact = ContactModel(
                name: 'Unknown User',
                publicKey: kSupportNpub,
              );

              if (context.mounted) {
                _handleContactTap(basicContact);
              }
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              children: [
                SvgPicture.asset(
                  AssetsPaths.icFeedback,
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
                    'Help and Feedback',
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
      ],
    );
  }

  Widget _buildContactsList(bool showTempContact, List<ContactModel> filteredContacts) {
    return Column(
      children: [
        if (showTempContact) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            child:
                _isLoadingMetadata
                    ? _buildLoadingContactTile()
                    : ContactListTile(
                      contact: _tempContact!,
                      onTap: () => _handleContactTap(_tempContact!),
                    ),
          ),
          Gap(16.h),
        ],
        Expanded(
          child:
              filteredContacts.isEmpty && !showTempContact
                  ? Center(
                    child:
                        _isLoadingMetadata
                            ? const CircularProgressIndicator()
                            : Text(
                              _searchQuery.isEmpty
                                  ? 'No contacts found'
                                  : _isValidPublicKey(_searchQuery)
                                  ? 'Loading metadata...'
                                  : 'No contacts match your search',
                              style: TextStyle(
                                color: context.colors.mutedForeground,
                                fontSize: 16.sp,
                              ),
                            ),
                  )
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      return ContactListTile(
                        contact: contact,
                        enableSwipeToDelete: true,
                        onTap: () => _handleContactTap(contact),
                        onDelete: () async {
                          try {
                            final realPublicKey = ref
                                .read(contactsProvider.notifier)
                                .getPublicKeyForContact(contact.publicKey);
                            if (realPublicKey != null) {
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
                      );
                    },
                  ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = _getFilteredContacts(contactsState.contactModels);
    final rawContacts = contactsState.contactModels ?? [];

    final showTempContact =
        _searchQuery.isNotEmpty &&
        _isValidPublicKey(_searchQuery) &&
        filteredContacts.isEmpty &&
        _tempContact != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Search field - not auto-focused
        CustomTextField(
          textController: _searchController,
          focusNode: _searchFocusNode,
          hintText: 'Search contact or public key...',
        ),
        Gap(16.h),
        // Scrollable content area
        Expanded(
          child:
              contactsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : contactsState.error != null
                  ? _buildErrorWidget(contactsState.error!)
                  : Column(
                    children: [
                      // Main options (New Group Chat, Help & Feedback)
                      _buildMainOptions(),
                      // DEBUG: Raw contacts section
                      if (_searchQuery.toLowerCase() == 'debug') ...[
                        Gap(16.h),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 24.w),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: context.colors.baseMuted,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEBUG: Raw Contacts Data',
                                style: TextStyle(
                                  color: context.colors.primary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Gap(8.h),
                              Text(
                                'Total raw contacts: ${rawContacts.length}',
                                style: TextStyle(
                                  color: context.colors.mutedForeground,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Gap(8.h),
                              ...rawContacts.asMap().entries.map((entry) {
                                final index = entry.key;
                                final contact = entry.value;
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: context.colors.surface,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact #$index',
                                        style: TextStyle(
                                          color: context.colors.primary,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'name: ${contact.name}',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                      Text(
                                        'displayNameOrName: ${contact.displayNameOrName}',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                      Text(
                                        'publicKey: ${contact.publicKey}',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                      Text(
                                        'nip05: ${contact.nip05 ?? "null"}',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                      Text(
                                        'about: ${contact.about ?? "null"}',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        Gap(16.h),
                      ],
                      // Contacts list
                      Expanded(
                        child: _buildContactsList(showTempContact, filteredContacts),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}
