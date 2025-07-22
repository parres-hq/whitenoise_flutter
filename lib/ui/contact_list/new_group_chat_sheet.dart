import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/contact_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class NewGroupChatSheet extends ConsumerStatefulWidget {
  final ValueChanged<GroupData?>? onGroupCreated;

  const NewGroupChatSheet({super.key, this.onGroupCreated});

  @override
  ConsumerState<NewGroupChatSheet> createState() => _NewGroupChatSheetState();

  static Future<void> show(BuildContext context, {ValueChanged<GroupData?>? onGroupCreated}) {
    return CustomBottomSheet.show(
      context: context,
      title: 'New group chat',
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder: (context) => NewGroupChatSheet(onGroupCreated: onGroupCreated),
    );
  }
}

class _NewGroupChatSheetState extends ConsumerState<NewGroupChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<ContactModel> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  void _toggleContactSelection(ContactModel contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
    });
  }

  Widget _buildContactsList(List<ContactModel> filteredContacts) {
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
              // Get the real PublicKey from the provider using the npub string
              final realPublicKey = ref
                  .read(contactsProvider.notifier)
                  .getPublicKeyForContact(contact.publicKey);
              if (realPublicKey != null) {
                await ref.read(contactsProvider.notifier).removeContactByPublicKey(realPublicKey);
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
          showCheck: true,
        );
      },
    );
  }

  List<ContactModel> _getFilteredContacts(List<ContactModel>? contacts, String? currentUserPubkey) {
    if (contacts == null) return [];

    // First filter out the creator (current user) from the contacts
    final contactsWithoutCreator =
        contacts.where((contact) {
          // Compare public keys, ensuring both are trimmed and lowercased for comparison
          return currentUserPubkey == null ||
              contact.publicKey.trim().toLowerCase() != currentUserPubkey.trim().toLowerCase();
        }).toList();

    // Then apply search filter if there's a search query
    if (_searchQuery.isEmpty) return contactsWithoutCreator;

    return contactsWithoutCreator
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
    final activeAccount = ref.watch(activeAccountProvider);
    final filteredContacts = _getFilteredContacts(contactsState.contactModels, activeAccount);

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
                contactsState.isLoading
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
                            onPressed: () {
                              // Navigate back - contacts should be loaded by new_chat_bottom_sheet
                              Navigator.of(context).pop();
                            },
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                    : _buildContactsList(filteredContacts),
          ),
          AppFilledButton(
            onPressed:
                _selectedContacts.isNotEmpty
                    ? () {
                      Navigator.pop(context);
                      GroupChatDetailsSheet.show(
                        context: context,
                        selectedContacts: _selectedContacts.toList(),
                        onGroupCreated: widget.onGroupCreated,
                      );
                    }
                    : null,
            title: 'Continue',
          ),
        ],
      ),
    );
  }
}
