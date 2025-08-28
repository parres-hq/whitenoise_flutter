import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/chat_navigation_extension.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_group_chat_sheet.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class NewChatBottomSheet extends ConsumerStatefulWidget {
  const NewChatBottomSheet({super.key});

  @override
  ConsumerState<NewChatBottomSheet> createState() => _NewChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return WnBottomSheet.show(
      context: context,
      title: 'New chat',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      useSafeArea: false,
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
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;

      if (activeAccount != null) {
        _logger.info('NewChatBottomSheet: Found active account: ${activeAccount.pubkey}');
        await ref.read(contactsProvider.notifier).loadContacts(activeAccount.pubkey);
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
    return input.trim().isValidPublicKey;
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
            displayName: 'Unknown User',
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

    // 2. Apply search filter if needed
    final query = _searchQuery.trim().toLowerCase();
    final filteredContacts =
        query.isEmpty
            ? deduplicatedContacts
            : deduplicatedContacts.where((contact) {
              final displayName = contact.displayName.toLowerCase();
              final nip05 = contact.nip05?.toLowerCase() ?? '';
              final about = contact.about?.toLowerCase() ?? '';
              final publicKey = contact.publicKey.toLowerCase();

              return displayName.contains(query) ||
                  nip05.contains(query) ||
                  about.contains(query) ||
                  publicKey.contains(query);
            }).toList();

    // 3. Sort the filtered contacts alphabetically (Unknown User at bottom) for consistent ordering
    filteredContacts.sort((a, b) {
      final aName = a.displayName;
      final bName = b.displayName;

      // Put "Unknown User" entries at the bottom
      if (aName == 'Unknown User' && bName != 'Unknown User') return 1;
      if (bName == 'Unknown User' && aName != 'Unknown User') return -1;
      if (aName == 'Unknown User' && bName == 'Unknown User') return 0;

      // Normal alphabetical sorting for everything else
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return filteredContacts;
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
            if (group != null && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.pop();
                  context.navigateToGroupChatAndPopToHome(group);
                }
              });
            }
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

  Future<void> _scanQRCode() async {
    // Navigate to the contact QR scan screen
    context.push(Routes.contactQrScan);
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
        NewChatTile(
          title: 'New Group Chat',
          iconPath: AssetsPaths.icGroupChat,
          onTap: () {
            Navigator.pop(context);
            NewGroupChatSheet.show(context);
          },
        ),
        Gap(18.h),
        NewChatTile(
          title: 'Help and Feedback',
          iconPath: AssetsPaths.icFeedback,
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
                displayName: 'Support',
                publicKey: kSupportNpub,
              );

              if (context.mounted) {
                _handleContactTap(basicContact);
              }
            }
          },
        ),
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
      children: [
        // Search field - not auto-focused
        WnTextFormField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          hintText: 'Search contact or public key...',
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.all(12.w),
              child: SvgPicture.asset(
                AssetsPaths.icSearch,
                colorFilter: ColorFilter.mode(
                  context.colors.primary,
                  BlendMode.srcIn,
                ),
                width: 20.sp,
                height: 20.sp,
              ),
            ),
            suffixIcon: GestureDetector(
              onTap: _scanQRCode,
              child: Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: SvgPicture.asset(
                  AssetsPaths.icScan,
                  width: 16.w,
                  height: 16.w,
                  colorFilter: ColorFilter.mode(
                    context.colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
        Gap(16.h),
        // Scrollable content area that goes to bottom
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
                        // Main options (New Group Chat, Help & Feedback) - scrollable with content
                        Gap(26.h),
                        _buildMainOptions(),
                        Gap(26.h),
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
                                          'name: ${contact.displayName}',
                                          style: TextStyle(
                                            color: context.colors.mutedForeground,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                        Text(
                                          'displayName: ${contact.displayName}',
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
                        // Contacts list - inline with scrollable content
                        if (showTempContact) ...[
                          _isLoadingMetadata
                              ? _buildLoadingContactTile()
                              : ContactListTile(
                                contact: _tempContact!,
                                onTap: () => _handleContactTap(_tempContact!),
                              ),
                          Gap(16.h),
                        ] else if (filteredContacts.isEmpty) ...[
                          SizedBox(
                            height: 200.h,
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
                          ),
                        ] else ...[
                          // Contacts list - all contacts as individual widgets in the scroll view
                          ...filteredContacts.map(
                            (contact) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
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
                        ],
                        // Add bottom padding to ensure content can scroll past the bottom
                        Gap(60.h),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }
}

class NewChatTile extends StatelessWidget {
  const NewChatTile({
    super.key,
    required this.onTap,
    required this.title,
    required this.iconPath,
  });

  final VoidCallback? onTap;
  final String title;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
            width: 20.w,
            height: 20.w,
          ),
          Gap(10.w),
          Text(
            title,
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 18.sp,
            ),
          ),
          Gap(8.w),

          SvgPicture.asset(
            AssetsPaths.icChevronRight,
            colorFilter: ColorFilter.mode(
              context.colors.primary,
              BlendMode.srcIn,
            ),
            width: 8.55.w,
            height: 15.w,
          ),
        ],
      ),
    );
  }
}
