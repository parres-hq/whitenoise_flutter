import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';

import '../../../domain/models/contact_model.dart';
import '../../core/themes/assets.dart';
import '../../core/themes/src/extensions.dart';

class ContactListTile extends StatelessWidget {
  final ContactModel contact;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showCheck;
  final bool showExpansionArrow;
  final bool enableSwipeToDelete;

  const ContactListTile({
    required this.contact,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showCheck = false,
    this.showExpansionArrow = false,
    this.enableSwipeToDelete = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final contactTile = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child:
                    contact.imagePath != null && contact.imagePath!.isNotEmpty
                        ? Image.network(
                          contact.imagePath!,
                          width: 56.w,
                          height: 56.w,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Center(
                                child: Text(
                                  contact.avatarLetter,
                                  style: TextStyle(
                                    color: context.colors.neutral,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        )
                        : Center(
                          child: Text(
                            contact.avatarLetter,
                            style: TextStyle(
                              color: context.colors.neutral,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.displayNameOrName,
                          style: TextStyle(
                            color: context.colors.secondaryForeground,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Gap(6.w),
                      if (contact.nip05 != null && contact.nip05!.isNotEmpty)
                        SvgPicture.asset(
                          AssetsPaths.icVerifiedUser,
                          height: 12.w,
                          width: 12.w,
                        ),
                    ],
                  ),
                  // Show display name if different from name
                  if (contact.displayName != null &&
                      contact.displayName!.isNotEmpty &&
                      contact.displayName != contact.name) ...[
                    Gap(2.h),
                    Text(
                      contact.displayName!,
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show about if available
                  if (contact.about != null && contact.about!.isNotEmpty) ...[
                    Gap(2.h),
                    Text(
                      contact.about!.length > 60
                          ? '${contact.about!.substring(0, 60)}...'
                          : contact.about!,
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show NIP-05 if available
                  if (contact.nip05 != null && contact.nip05!.isNotEmpty) ...[
                    Gap(2.h),
                    Text(
                      contact.nip05!,
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show website if available
                  if (contact.website != null && contact.website!.isNotEmpty) ...[
                    Gap(2.h),
                    Text(
                      contact.website!,
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 11.sp,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Show lightning address if available
                  if (contact.lud16 != null && contact.lud16!.isNotEmpty) ...[
                    Gap(2.h),
                    Text(
                      '⚡ ${contact.lud16!}',
                      style: TextStyle(
                        color: context.colors.mutedForeground,
                        fontSize: 11.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Public key display removed per user request
                ],
              ),
            ),
            if (showCheck) ...[
              Gap(16.w),
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? context.colors.primary : context.colors.baseMuted,
                    width: 1.5.w,
                  ),
                  color: isSelected ? context.colors.primary : Colors.transparent,
                ),
                child: isSelected ? Icon(Icons.check, size: 12.w, color: Colors.white) : null,
              ),
            ] else if (showExpansionArrow) ...[
              Gap(16.w),
              SvgPicture.asset(AssetsPaths.icExpand, width: 11.w, height: 18.w),
            ],
          ],
        ),
      ),
    );

    // If swipe to delete is enabled, wrap with Dismissible
    if (enableSwipeToDelete && onDelete != null) {
      return Dismissible(
        key: Key(contact.publicKey),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Show confirmation dialog
          return await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Remove Contact'),
                  content: Text(
                    'Are you sure you want to remove ${contact.displayNameOrName} from your contacts?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
          );
        },
        onDismissed: (direction) {
          onDelete!();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 24.w),
          color: Colors.red,
          child: Icon(CarbonIcons.trash_can, color: Colors.white, size: 24.w),
        ),
        child: contactTile,
      );
    }

    return contactTile;
  }
}
