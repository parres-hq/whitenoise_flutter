import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact removed successfully'),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove contact: $e'),
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
    final filteredContacts = ref.read(contactsProvider.notifier).getFilteredContacts(_searchQuery);

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
