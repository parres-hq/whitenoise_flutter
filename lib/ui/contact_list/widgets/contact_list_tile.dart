import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/string_extensions.dart';

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

  Future<String> _getNpub(String publicKeyHex) async {
    try {
      final publicKey = await publicKeyFromString(publicKeyString: publicKeyHex);
      final npub = await exportAccountNpub(pubkey: publicKey);
      return npub.formatPublicKey();
    } catch (e) {
      // Return the full hex key as fallback
      return publicKeyHex.formatPublicKey();
    }
  }

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
                  color: context.colors.warning,
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
                    ],
                  ),
                  Gap(2.h),
                  FutureBuilder<String>(
                    future: _getNpub(contact.publicKey),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Loading...',
                          style: TextStyle(
                            color: context.colors.mutedForeground.withValues(alpha: 0.6),
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Text(
                          snapshot.data!,
                          style: TextStyle(
                            color: context.colors.mutedForeground,
                            fontSize: 12.sp,
                            fontFamily: 'monospace',
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error loading npub',
                          style: TextStyle(
                            color: context.colors.mutedForeground.withValues(alpha: 0.6),
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
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
