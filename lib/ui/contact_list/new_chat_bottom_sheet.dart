import 'dart:async';

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
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScrollChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final originalText = _searchController.text;
    String processedText = originalText;

    // Only remove whitespace if it looks like a public key (starts with npub or is hex-like)
    if (originalText.startsWith('npub')) {
      processedText = originalText.replaceAll(RegExp(r'\s+'), '');

      // Update the controller if we removed whitespace
      if (originalText != processedText) {
        _searchController.value = _searchController.value.copyWith(
          text: processedText,
          selection: TextSelection.collapsed(offset: processedText.length),
        );
      }
    }

    // Debounce the search to avoid too many filter operations
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = processedText;
          _tempContact = null;
        });

        // If it's a valid public key, fetch metadata
        if (_isValidPublicKey(_searchQuery)) {
          _getUserProfileDataForPublicKey(_searchQuery);
        }
      }
    });
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

  Widget _buildContactsList({
    required FollowsState followsState,
    required List<ContactModel> filteredContacts,
    required bool showTempContact,
  }) {
    if (followsState.isLoading) {
      return SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildMainOptions(),
            Gap(26.h),
            const _LoadingContactList(),
            Gap(60.h),
          ],
        ),
      );
    }

    // Calculate total items in the list
    int totalItems = 0;

    // Count for main options section
    totalItems += 1; // main options section

    // Count gap after main options
    totalItems += 1; // gap

    // Count contact items
    if (showTempContact) {
      totalItems += 1; // temp contact
      totalItems += 1; // gap after temp contact
    } else if (filteredContacts.isEmpty) {
      totalItems += 1; // empty state
    } else {
      totalItems += filteredContacts.length; // contact items
    }

    // Count bottom padding
    totalItems += 1; // bottom gap

    return ListView.builder(
      controller: _scrollController,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        int currentIndex = 0;

        // Main options section
        if (index == currentIndex) {
          return _buildMainOptions();
        }
        currentIndex++;

        // Gap after main options
        if (index == currentIndex) {
          return Gap(26.h);
        }
        currentIndex++;

        if (showTempContact) {
          // Temp contact
          if (index == currentIndex) {
            return _isLoadingUserProfileData
                ? const ContactListTileLoading()
                : ContactListTile(
                  contact: _tempContact!,
                  onTap: () => _handleContactTap(_tempContact!),
                  preformattedPublicKey: _tempContact!.formattedPublicKey,
                );
          }
          currentIndex++;

          // Gap after temp contact
          if (index == currentIndex) {
            return Gap(16.h);
          }
          currentIndex++;
        } else if (filteredContacts.isEmpty) {
          // Empty state
          if (index == currentIndex) {
            return SizedBox(
              child:
                  _isLoadingUserProfileData
                      ? const ContactListTileLoading()
                      : Center(
                        child: Text(
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
            );
          }
          currentIndex++;
        } else {
          // Contact items
          final contactIndex = index - currentIndex;
          if (contactIndex < filteredContacts.length) {
            final contact = filteredContacts[contactIndex];
            return Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: ContactListTile(
                contact: contact,
                onTap: () => _handleContactTap(contact),
                preformattedPublicKey: contact.formattedPublicKey,
              ),
            );
          }
          currentIndex += filteredContacts.length;
        }

        // Bottom padding
        if (index == currentIndex) {
          return Gap(60.h);
        }

        return const SizedBox.shrink();
      },
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
              followsState.error != null
                  ? _buildErrorWidget(followsState.error!)
                  : _buildContactsList(
                    followsState: followsState,
                    filteredContacts: filteredContacts,
                    showTempContact: showTempContact,
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

class _LoadingContactList extends StatelessWidget {
  const _LoadingContactList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        8,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: const ContactListTileLoading(),
        ),
      ),
    );
  }
}
