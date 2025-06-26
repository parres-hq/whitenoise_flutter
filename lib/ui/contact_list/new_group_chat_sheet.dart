import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/contact_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NewGroupChatSheet extends ConsumerStatefulWidget {
  const NewGroupChatSheet({super.key});

  @override
  ConsumerState<NewGroupChatSheet> createState() => _NewGroupChatSheetState();

  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: 'New group chat',
      barrierColor: Colors.transparent,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => const NewGroupChatSheet(),
    );
  }
}

class _NewGroupChatSheetState extends ConsumerState<NewGroupChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<ContactModel> _selectedContacts = {};
  final Map<String, PublicKey> _publicKeyMap = {};
  final _logger = Logger('NewGroupChatSheet');

  // Cache for converted contacts
  List<ContactModel> _allContactModels = [];
  Map<PublicKey, MetadataData?>? _lastProcessedContacts;
  bool _isProcessingContacts = false;

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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData != null) {
        _logger.info('NewGroupChatSheet: Found active account: ${activeAccountData.pubkey}');
        await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);

        _logger.info('NewGroupChatSheet: Contacts loaded successfully');
      } else {
        _logger.severe('NewGroupChatSheet: No active account found');
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
      _logger.severe('NewGroupChatSheet: Error loading contacts: $e');
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

  Future<void> _processContacts(Map<PublicKey, MetadataData?>? contacts) async {
    if (contacts == null) {
      _allContactModels = [];
      _publicKeyMap.clear();
      return;
    }

    // Check if we need to reprocess (contacts changed)
    if (_lastProcessedContacts == contacts && _allContactModels.isNotEmpty) {
      return; // Already processed these contacts
    }

    if (_isProcessingContacts) return; // Already processing

    setState(() {
      _isProcessingContacts = true;
    });

    try {
      final contactModels = <ContactModel>[];
      _publicKeyMap.clear();

      for (final entry in contacts.entries) {
        try {
          final npubString = await exportAccountNpub(pubkey: entry.key);

          final contactModel = ContactModel.fromMetadata(
            publicKey: npubString,
            metadata: entry.value,
          );

          _publicKeyMap[npubString] = entry.key;
          contactModels.add(contactModel);
        } catch (e) {
          _logger.warning('Failed to convert PublicKey to npub: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _allContactModels = contactModels;
          _lastProcessedContacts = contacts;
          _isProcessingContacts = false;
        });
      }
    } catch (e) {
      _logger.severe('Error processing contacts: $e');
      if (mounted) {
        setState(() {
          _isProcessingContacts = false;
        });
      }
    }
  }

  List<ContactModel> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return _allContactModels;

    return _allContactModels
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

  void _toggleContactSelection(ContactModel contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  Widget _buildContactsList() {
    final filteredContacts = _getFilteredContacts();

    if (filteredContacts.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No contacts found' : 'No contacts match your search',
          style: TextStyle(fontSize: 16.sp),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        final isSelected = _selectedContacts.contains(contact);

        return ContactListTile(
          contact: contact,
          isSelected: isSelected,
          onTap: () => _toggleContactSelection(contact),
          enableSwipeToDelete: true,
          onDelete: () async {
            try {
              // Get the real PublicKey from our map using the npub string
              final realPublicKey = _publicKeyMap[contact.publicKey];
              if (realPublicKey != null) {
                // Use the proper method to remove contact from Rust backend
                await ref.read(contactsProvider.notifier).removeContactByPublicKey(realPublicKey);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Contact removed successfully',
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to remove contact: $e',
                    ),
                  ),
                );
              }
            }
          },
          showCheck: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);

    // Process contacts when they change
    if (contactsState.contacts != null && !_isProcessingContacts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processContacts(contactsState.contacts);
      });
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          CustomTextField(
            textController: _searchController,
            hintText: 'Search contact or public key...',
          ),
          Expanded(
            child:
                contactsState.isLoading || _isProcessingContacts
                    ? const Center(child: CircularProgressIndicator())
                    : contactsState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading contacts',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          Text(
                            contactsState.error!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.colors.baseMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: _loadContacts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _buildContactsList(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
            ).copyWith(bottom: 32.h),
            child: AppFilledButton(
              onPressed:
                  _selectedContacts.isNotEmpty
                      ? () {
                        Navigator.pop(context);
                        GroupChatDetailsSheet.show(
                          context: context,
                          selectedContacts: _selectedContacts.toList(),
                        );
                      }
                      : null,
              title: 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}
