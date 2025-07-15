import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ReactionsDialogWidget extends StatefulWidget {
  const ReactionsDialogWidget({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.onReactionTap,
    required this.onContextMenuTap,
    this.menuItems = DefaultData.menuItems,
    this.reactions = DefaultData.reactions,
    this.widgetAlignment = Alignment.centerRight,
    this.menuItemsWidth = 0.50,
  });

  // Id for the hero widget
  final String id;

  // The message widget to be displayed in the dialog
  final Widget messageWidget;

  // The callback function to be called when a reaction is tapped
  final Function(String) onReactionTap;

  // The callback function to be called when a context menu item is tapped
  final Function(MenuItem) onContextMenuTap;

  // The list of menu items to be displayed in the context menu
  final List<MenuItem> menuItems;

  // The list of reactions to be displayed
  final List<String> reactions;

  // The alignment of the widget
  final Alignment widgetAlignment;

  // The width of the menu items
  final double menuItemsWidth;

  @override
  State<ReactionsDialogWidget> createState() => _ReactionsDialogWidgetState();
}

class _ReactionsDialogWidgetState extends State<ReactionsDialogWidget> {
  // state variables for activating the animation
  bool reactionClicked = false;
  int? clickedReactionIndex;
  int? clickedContextMenuIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close the dialog when tapping outside the menu
        Navigator.of(context).pop();
      },
      child: Material(
        color: context.colors.overlay.withValues(alpha: 0.06),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                buildReactions(context),
                Gap(16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: buildMessage(),
                ),
                Gap(16.h),
                buildMenuItems(context),
                Gap(32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMenuItems(BuildContext context) {
    return Align(
      alignment: widget.widgetAlignment,
      child: Container(
        width: MediaQuery.of(context).size.width * widget.menuItemsWidth,
        margin: EdgeInsets.symmetric(horizontal: 48.w),
        decoration: BoxDecoration(
          color: context.colors.primaryForeground,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int index = 0; index < widget.menuItems.length; index++)
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        clickedContextMenuIndex = index;
                      });
                      Navigator.of(context).pop();
                      widget.onContextMenuTap(widget.menuItems[index]);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.menuItems[index].label,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color:
                                    widget.menuItems[index].isDestructive
                                        ? context.colors.destructive
                                        : context.colors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Pulse(
                            duration: const Duration(milliseconds: 100),
                            animate: clickedContextMenuIndex == index,
                            child: Icon(
                              widget.menuItems[index].icon,
                              size: 20.sp,
                              color:
                                  widget.menuItems[index].isDestructive
                                      ? context.colors.destructive
                                      : context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index != widget.menuItems.length - 1)
                    Container(
                      height: 1.h,
                      color: context.colors.border,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget buildMessage() {
    return Align(
      alignment: widget.widgetAlignment,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        child: Hero(
          tag: widget.id,
          child: widget.messageWidget,
        ),
      ),
    );
  }

  Widget buildReactions(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.primaryForeground,
      ),
      child: _buildRowReactions(),
    );
  }

  Widget _buildRowReactions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 6.w,
      children: [
        Gap(24.w),
        for (var reaction in widget.reactions) _buildReactionItem(reaction),
        _buildAddReactionButton(),
        Gap(24.w),
      ],
    );
  }

  Widget _buildReactionItem(String reaction) {
    return FadeInLeft(
      from: 0 + (widget.reactions.indexOf(reaction) * 20).toDouble(),
      duration: const Duration(milliseconds: 50),
      child: InkWell(
        onTap: () {
          setState(() {
            reactionClicked = true;
            clickedReactionIndex = widget.reactions.indexOf(reaction);
          });
          Navigator.of(context).pop();
          widget.onReactionTap(reaction);
        },
        child: Pulse(
          duration: const Duration(milliseconds: 50),
          animate: reactionClicked && clickedReactionIndex == widget.reactions.indexOf(reaction),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              reaction,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddReactionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // Trigger the emoji picker by calling onReactionTap with a special value
        widget.onReactionTap('⋯');
      },
      child: SvgPicture.asset(
        AssetsPaths.icFaceAdd,
        width: 22.w,
        height: 22.w,
        colorFilter: ColorFilter.mode(
          context.colors.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
