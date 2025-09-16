import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/constants.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/chat_navigation_extension.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_group_chat_sheet.dart';
import 'package:whitenoise/ui/contact_list/start_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class NewChatBottomSheet extends ConsumerStatefulWidget {
  const NewChatBottomSheet({super.key});

  @override
  ConsumerState<NewChatBottomSheet> createState() => _NewChatBottomSheetState();

  static Future<void> show(BuildContext context) {
    return WnBottomSheet.show(
      context: context,
      title: 'Start New Chat',
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
  bool _isLoadingUserProfileData = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);
    // Load follows when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollows();
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
    final originalText = _searchController.text;
    final trimmedText = originalText.replaceAll(RegExp(r'\s+'), '');

    if (originalText != trimmedText) {
      _searchController.value = _searchController.value.copyWith(
        text: trimmedText,
        selection: TextSelection.collapsed(offset: trimmedText.length),
      );
    }

    setState(() {
      _searchQuery = trimmedText;
      _tempContact = null;
    });

    // If it's a valid public key, fetch metadata
    if (_isValidPublicKey(_searchQuery)) {
      _getUserProfileDataForPublicKey(_searchQuery);
    }
  }

  void _onScrollChanged() {
    // Unfocus the text field when user starts scrolling
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _loadFollows() async {
    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';

      if (activePubkey.isNotEmpty) {
        _logger.info('NewChatBottomSheet: Found active account: $activePubkey');
        await ref.read(followsProvider.notifier).loadFollows();
        _logger.info('NewChatBottomSheet: Contacts loaded successfully');
      } else {
        _logger.severe('NewChatBottomSheet: No active account found');
        if (mounted) {
          ref.showErrorToast('No active account found');
        }
      }
    } catch (e) {
      _logger.severe('NewChatBottomSheet: Error loading follows: $e');
      if (mounted) {
        ref.showErrorToast('Error loading follows: $e');
      }
    }
  }

  bool _isValidPublicKey(String input) {
    return input.trim().isValidPublicKey;
  }

  Future<void> _getUserProfileDataForPublicKey(String publicKey) async {
    if (_isLoadingUserProfileData) return;

    setState(() {
      _isLoadingUserProfileData = true;
    });

    try {
      final userProfileDataNotifier = ref.read(userProfileDataProvider.notifier);
      final userProfileData = await userProfileDataNotifier.getUserProfileData(publicKey.trim());

      if (mounted) {
        setState(() {
          _tempContact = userProfileData;
          _isLoadingUserProfileData = false;
        });
      }
    } catch (e) {
      _logger.warning('Failed to get user profile data for public key: $e');
      if (mounted) {
        setState(() {
          _tempContact = ContactModel(
            displayName: 'Unknown User',
            publicKey: publicKey.trim(),
          );
          _isLoadingUserProfileData = false;
        });
      }
    }
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
            'Error loading follows',
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
            onPressed: _loadFollows,
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
                  'Loading user profile...',
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
        NewChatTile(
          title: 'Help and Feedback',
          iconPath: AssetsPaths.icFeedback,
          onTap: () async {
            Navigator.pop(context);

            try {
              final userProfileDataNotifier = ref.read(userProfileDataProvider.notifier);
              final supportUserProfileData = await userProfileDataNotifier.getUserProfileData(
                kSupportNpub,
              );
              _handleContactTap(supportUserProfileData);
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

    final showTempContact =
        _searchQuery.isNotEmpty &&
        _isValidPublicKey(_searchQuery) &&
        filteredContacts.isEmpty &&
        _tempContact != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WnTextFormField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                size: FieldSize.small,
                hintText: 'Search contact or public key...',
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: WnImage(
                      AssetsPaths.icSearch,
                      color: context.colors.primary,
                      size: 16.w,
                    ),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: _scanQRCode,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14.w),
                      child: WnImage(
                        AssetsPaths.icScan,
                        size: 16.w,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Gap(4.w),
            WnIconButton(
              iconPath: AssetsPaths.icPaste,
              onTap:
                  () async => await ClipboardUtils.pasteWithToast(
                    ref: ref,
                    onPaste: (text) {
                      _searchController.text = text;
                    },
                  ),
              padding: 14.w,
              size: 44.h,
            ),
          ],
        ),
        Gap(12.h),
        // Scrollable content area that goes to bottom
        Expanded(
          child:
              followsState.isLoading
                  ? _buildContactsLoadingWidget()
                  : followsState.error != null
                  ? _buildErrorWidget(followsState.error!)
                  : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // Main options (New Group Chat, Help & Feedback) - scrollable with content
                        _buildMainOptions(),
                        Gap(12.h),
                        // DEBUG: Raw follows section
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
                                  'Total raw follows: ${followsState.follows.length}',
                                  style: TextStyle(
                                    color: context.colors.mutedForeground,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                Gap(8.h),
                                ...followsState.follows.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final user = entry.value;
                                  final contact = ContactModel.fromMetadata(
                                    pubkey: user.pubkey,
                                    metadata: user.metadata,
                                  );
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
                        if (showTempContact) ...[
                          _isLoadingUserProfileData
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
                                  _isLoadingUserProfileData
                                      ? const CircularProgressIndicator()
                                      : Text(
                                        _searchQuery.isEmpty
                                            ? 'No follows found'
                                            : _isValidPublicKey(_searchQuery)
                                            ? 'Loading metadata...'
                                            : 'No follows match your search',
                                        style: TextStyle(
                                          color: context.colors.mutedForeground,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                            ),
                          ),
                        ] else ...[
                          ...filteredContacts.map(
                            (contact) => Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: ContactListTile(
                                contact: contact,
                                onTap: () => _handleContactTap(contact),
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
      child: Padding(
        padding: const EdgeInsets.all(13).w,
        child: Row(
          children: [
            WnImage(
              iconPath,
              color: context.colors.primary,
              size: 16.w,
            ),
            Gap(10.w),
            Text(
              title,
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(8.w),
            WnImage(
              AssetsPaths.icChevronRight,
              color: context.colors.primary,
              width: 5.7.w,
              height: 10.w,
            ),
          ],
        ),
      ),
    );
  }
}
