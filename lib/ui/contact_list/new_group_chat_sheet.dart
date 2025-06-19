import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/contact_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
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
  final Map<String, PublicKey> _publicKeyMap = {}; // Map ContactModel.publicKey to real PublicKey

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
      debugPrint('Error loading contacts in new group chat: $e');
      // Handle error through proper method
      debugPrint('Failed to load contacts: $e');
    }
  }

  List<ContactModel> _getFilteredContacts(Map<PublicKey, Metadata?>? contacts) {
    if (contacts == null) return [];
    
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

    if (_searchQuery.isEmpty) return contactModels;
    
    return contactModels
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              contact.displayNameOrName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (contact.nip05?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              contact.publicKey.toLowerCase().contains(_searchQuery.toLowerCase()),
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


  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = _getFilteredContacts(contactsState.contacts);

    return Column(
      children: [
        CustomTextField(
          textController: _searchController,
          hintText: 'Search contact or public key...',
        ),
        Expanded(
          child: contactsState.isLoading
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
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          ElevatedButton(
                            onPressed: _loadContacts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : filteredContacts.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No contacts found'
                                : 'No contacts match your search',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                                  // Get the real PublicKey from our map
                                  final realPublicKey = _publicKeyMap[contact.publicKey];
                                  if (realPublicKey != null) {
                                    // Use the proper method to remove contact from Rust backend
                                    await ref.read(contactsProvider.notifier).removeContactByPublicKey(realPublicKey);
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Contact removed successfully')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to remove contact: $e')),
                                    );
                                  }
                                }
                              },
                              showCheck: true,
                            );
                          },
                        ),
        ),
        CustomFilledButton(
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
          bottomPadding: 16.h,
        ),
      ],
    );
  }
}
