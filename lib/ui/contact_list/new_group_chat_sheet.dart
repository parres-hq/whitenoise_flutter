import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/ui/contact_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_field.dart';

class NewGroupChatSheet extends ConsumerStatefulWidget {
  final ValueChanged<Group?>? onGroupCreated;

  const NewGroupChatSheet({super.key, this.onGroupCreated});

  @override
  ConsumerState<NewGroupChatSheet> createState() => _NewGroupChatSheetState();

  static Future<void> show(BuildContext context, {ValueChanged<Group?>? onGroupCreated}) {
    return WnBottomSheet.show(
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
    final originalText = _searchController.text;
    String processedText = originalText;

    // Only remove whitespace if it looks like a public key (starts with npub or is hex-like)
    if (originalText.startsWith('npub1')) {
      processedText = originalText.replaceAll(RegExp(r'\s+'), '');

      // Update the controller if we removed whitespace
      if (originalText != processedText) {
        _searchController.value = _searchController.value.copyWith(
          text: processedText,
          selection: TextSelection.collapsed(offset: processedText.length),
        );
      }
    }

    setState(() {
      _searchQuery = processedText;
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
              contact.displayName.toLowerCase().contains(
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
    final followsState = ref.watch(followsProvider);
    final activeAccount = ref.watch(activePubkeyProvider);
    final follows = followsState.follows;
    final contactModels = follows.map(
      (follow) => ContactModel.fromMetadata(pubkey: follow.pubkey, metadata: follow.metadata),
    );
    final filteredContacts = _getFilteredContacts(contactModels.toList(), activeAccount);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          WnTextField(
            textController: _searchController,
            hintText: 'Search contact or public key...',
          ),
          Expanded(
            child:
                followsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : followsState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading contacts',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          Gap(8.h),
                          Text(
                            followsState.error!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.colors.baseMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Gap(16.h),
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
          WnFilledButton(
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
            label: 'Continue',
          ),
        ],
      ),
    );
  }
}
