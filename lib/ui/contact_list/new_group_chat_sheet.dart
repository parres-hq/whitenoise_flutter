import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/dummy_data/dummy_contacts.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/contact_list/group_chat_details_sheet.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class NewGroupChatSheet extends StatefulWidget {
  const NewGroupChatSheet({super.key});

  @override
  State<NewGroupChatSheet> createState() => _NewGroupChatSheetState();

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

class _NewGroupChatSheetState extends State<NewGroupChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ContactModel> _filteredContacts = [];
  final Set<ContactModel> _selectedContacts = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _filteredContacts = dummyContacts;
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
      _filteredContacts = _getFilteredContacts();
    });
  }

  List<ContactModel> _getFilteredContacts() {
    if (_searchQuery.isEmpty) return dummyContacts;
    return dummyContacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(_searchQuery.toLowerCase()),
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
    return Column(
      children: [
        CustomTextField(
          textController: _searchController,
          hintText: 'Search contact or public key...',
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: _filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = _filteredContacts[index];
              final isSelected = _selectedContacts.contains(contact);

              return ContactListTile(
                contact: contact,
                isSelected: isSelected,
                onTap: () => _toggleContactSelection(contact),
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
