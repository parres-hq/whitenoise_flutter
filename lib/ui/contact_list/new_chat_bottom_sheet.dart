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
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/share_invite_bottom_sheet.dart';
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

  Future<Event?> _fetchKeyPackageWithRetry(String publicKeyString) async {
    const maxAttempts = 3;
    Event? lastSuccessfulResult;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        _logger.info('Key package fetch attempt $attempt for $publicKeyString');

        // Create fresh PublicKey object for each attempt to avoid disposal issues
        final freshPubkey = await publicKeyFromString(publicKeyString: publicKeyString);
        final keyPackage = await fetchKeyPackage(pubkey: freshPubkey);

        _logger.info(
          'Key package fetch successful on attempt $attempt - result: ${keyPackage != null ? "found" : "null"}',
        );
        lastSuccessfulResult = keyPackage;
        return keyPackage; // Return immediately on success (whether null or not)
      } catch (e) {
        _logger.warning('Key package fetch attempt $attempt failed: $e');

        if (e.toString().contains('DroppableDisposedException')) {
          _logger.warning('Detected disposal exception, will retry with fresh objects');
        } else if (e.toString().contains('RustArc')) {
          _logger.warning('Detected RustArc error, will retry with fresh objects');
        } else {
          // For non-disposal errors, don't retry
          _logger.severe('Non-disposal error encountered, not retrying: $e');
          rethrow;
        }

        if (attempt == maxAttempts) {
          _logger.severe('Failed to fetch key package after $maxAttempts attempts: $e');
          throw Exception('Failed to fetch key package after $maxAttempts attempts: $e');
        }

        // Wait a bit before retry
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // This should never be reached due to the logic above, but just in case
    return lastSuccessfulResult;
  }

  Future<void> _fetchMetadataForPublicKey(String publicKey) async {
    if (_isLoadingMetadata) return;

    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      // Use metadata cache to fetch contact model
      final metadataCache = ref.read(metadataCacheProvider.notifier);
      final contactModel = await metadataCache.getContactModel(publicKey.trim());

      if (mounted) {
        setState(() {
          _tempContact = contactModel;
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
      Event? keyPackage;

      try {
        // Use retry mechanism for key package fetching
        keyPackage = await _fetchKeyPackageWithRetry(contact.publicKey);
        _logger.info('Raw key package fetch result for ${contact.publicKey}: $keyPackage');
        _logger.info('Key package is null: ${keyPackage == null}');
        _logger.info('Key package type: ${keyPackage.runtimeType}');
      } catch (e) {
        _logger.warning(
          'Failed to fetch key package for ${contact.publicKey} after all retries: $e',
        );
        keyPackage = null;
      }

      if (mounted) {
        _logger.info('=== UI Decision Logic ===');
        _logger.info('keyPackage != null: ${keyPackage != null}');
        _logger.info(
          'Final decision: ${keyPackage != null ? "StartSecureChatBottomSheet" : "ShareInviteBottomSheet"}',
        );

        if (keyPackage != null) {
          _logger.info('Showing StartSecureChatBottomSheet for secure chat');
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
          _logger.info('Showing ShareInviteBottomSheet for sharing invite');
          ShareInviteBottomSheet.show(
            context: context,
            contacts: [contact],
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
              // Use metadata cache for support contact
              final metadataCache = ref.read(metadataCacheProvider.notifier);
              final supportContact = await metadataCache.getContactModel(kSupportNpub);

              if (context.mounted) {
                _handleContactTap(supportContact);
              }
            } catch (e) {
              _logger.warning('Failed to fetch metadata for support contact: $e');

              final basicContact = ContactModel(
                name: 'Support',
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
      mainAxisSize: MainAxisSize.min,
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
        // Show message when no contacts or build the list
        if (filteredContacts.isEmpty && !showTempContact)
          SizedBox(
            height: 200.h, // Fixed height for the message
            child: Center(
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
            ),
          )
        else
          // Build contacts list without ListView.builder to avoid nested scrolling
          ...filteredContacts.map(
            (contact) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ContactListTile(
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
              ),
            ),
          ),
        // Add some bottom padding
        Gap(40.h),
      ],
    );
  }

  Widget _buildContactsLoadingWidget() {
    return Center(
      child: SizedBox(
        width: 32.w,
        height: 32.w,
        child: CircularProgressIndicator(
          strokeWidth: 4.0,
          valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.onSurface),
        ),
      ),
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
                  ? _buildContactsLoadingWidget()
                  : contactsState.error != null
                  ? _buildErrorWidget(contactsState.error!)
                  : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Main options (New Group Chat, Help & Feedback) - now scrollable
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
                        // Contacts list - now part of the scrollable content
                        _buildContactsList(showTempContact, filteredContacts),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}
