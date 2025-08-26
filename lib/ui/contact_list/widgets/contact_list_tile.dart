import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ContactListTile extends StatelessWidget {
  final ContactModel contact;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showCheck;
  final bool showExpansionArrow;
  final Widget? trailingIcon;
  final bool enableSwipeToDelete;

  const ContactListTile({
    required this.contact,
    this.onTap,
    this.onDelete,
    this.isSelected = false,
    this.showCheck = false,
    this.showExpansionArrow = false,
    this.trailingIcon,
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
    final contactImagePath = contact.imagePath ?? '';
    final contactTile = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            WnAvatar(
              imageUrl: contactImagePath,
              displayName: contact.displayName,
              size: 56.w,
              showBorder: contactImagePath.isEmpty,
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
                          contact.displayName,
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
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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
                      // Show npub while loading immediately
                      return Text(
                        contact.publicKey.formatPublicKey(),
                        style: TextStyle(
                          color: context.colors.mutedForeground,
                          fontSize: 12.sp,
                          fontFamily: 'monospace',
                        ),
                      );
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
                child:
                    isSelected
                        ? WnImage(
                          AssetsPaths.icCheckmark,
                          size: 16.w,
                          color: context.colors.primaryForeground,
                        )
                        : null,
              ),
            ] else if (trailingIcon != null) ...[
              Gap(16.w),
              trailingIcon!,
            ] else if (showExpansionArrow) ...[
              Gap(16.w),
              WnImage(AssetsPaths.icExpand, width: 11.w, height: 18.w),
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
                    'Are you sure you want to remove ${contact.displayName} from your contacts?',
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
          child: WnImage(
            AssetsPaths.icTrashCan,
            color: context.colors.primary,
            size: 24.w,
          ),
        ),
        child: contactTile,
      );
    }

    return contactTile;
  }
}

class _SkeletonLine extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.05, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(2.r),
          ),
        );
      },
    );
  }
}
