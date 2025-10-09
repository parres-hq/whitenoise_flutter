import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class ReactionsDialogWidget extends StatefulWidget {
  const ReactionsDialogWidget({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.onReactionTap,
    required this.onContextMenuTap,
    List<MenuItem>? menuItems,
    this.reactions = DefaultData.reactions,
    this.widgetAlignment = Alignment.centerRight,
    this.menuItemsWidth = 0.50,
    this.messagePosition,
  }) : _menuItems = menuItems;

  // Id for the hero widget
  final String id;

  // The message widget to be displayed in the dialog
  final Widget messageWidget;

  // The callback function to be called when a reaction is tapped
  final Function(String) onReactionTap;

  // The callback function to be called when a context menu item is tapped
  final Function(MenuItem) onContextMenuTap;

  // The list of menu items to be displayed in the context menu
  final List<MenuItem>? _menuItems;

  List<MenuItem> get menuItems => _menuItems ?? DefaultData.menuItems;

  // The list of reactions to be displayed
  final List<String> reactions;

  // The alignment of the widget
  final Alignment widgetAlignment;

  // The width of the menu items
  final double menuItemsWidth;

  // The position of the message on screen (optional)
  final Offset? messagePosition;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _PositionedContent(
                  messagePosition: widget.messagePosition,
                  menuItemsCount: widget.menuItems.length,
                  buildReactions: () => buildReactions(context),
                  buildMessage: buildMessage,
                  buildMenuItems: () => buildMenuItems(context),
                  constraints: constraints,
                );
              },
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
        margin: EdgeInsets.symmetric(horizontal: 18.w),
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
                            child: WnImage(
                              widget.menuItems[index].assetPath,
                              width: 20.sp,
                              height: 20.sp,
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
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        child: widget.messageWidget,
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
        Gap(12.w),
        for (var reaction in widget.reactions) _buildReactionItem(reaction),
        _buildAddReactionButton(),
        Gap(12.w),
      ],
    );
  }

  Widget _buildReactionItem(String reaction) {
    return InkWell(
      onTap: () {
        setState(() {
          reactionClicked = true;
          clickedReactionIndex = widget.reactions.indexOf(reaction);
        });
        Navigator.of(context).pop();
        widget.onReactionTap(reaction);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale:
            reactionClicked && clickedReactionIndex == widget.reactions.indexOf(reaction)
                ? 1.2
                : 1.0,
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
    );
  }

  Widget _buildAddReactionButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        // Trigger the emoji picker by calling onReactionTap with a special value
        widget.onReactionTap('⋯');
      },
      child: WnImage(
        AssetsPaths.icFaceAdd,
        width: 22.w,
        height: 22.w,
        color: context.colors.primary,
      ),
    );
  }
}

class _PositionedContent extends StatelessWidget {
  const _PositionedContent({
    required this.messagePosition,
    required this.menuItemsCount,
    required this.buildReactions,
    required this.buildMessage,
    required this.buildMenuItems,
    required this.constraints,
  });

  final Offset? messagePosition;
  final int menuItemsCount;
  final Widget Function() buildReactions;
  final Widget Function() buildMessage;
  final Widget Function() buildMenuItems;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final reactionBarHeight = 56.h; // Approximate height of reaction bar
    final menuItemsHeight = (menuItemsCount * 48.h) + 32.h; // Menu items + bottom gap
    final gapBetweenReactionsAndMessage = 16.h;
    final gapBetweenMessageAndMenu = 16.h;

    final heightBelowMessage = gapBetweenMessageAndMenu + menuItemsHeight;

    if (messagePosition != null) {
      final topSpacing = _calculateTopSpacing(
        context: context,
        reactionBarHeight: reactionBarHeight,
        heightBelowMessage: heightBelowMessage,
        gapBetweenReactionsAndMessage: gapBetweenReactionsAndMessage,
      );

      return _buildPositionedLayout(
        topSpacing: topSpacing,
        gapBetweenReactionsAndMessage: gapBetweenReactionsAndMessage,
        gapBetweenMessageAndMenu: gapBetweenMessageAndMenu,
      );
    }

    return _buildCenteredLayout();
  }

  double _calculateTopSpacing({
    required BuildContext context,
    required double reactionBarHeight,
    required double heightBelowMessage,
    required double gapBetweenReactionsAndMessage,
  }) {
    // Get the safe area insets to adjust for status bar, notch, etc.
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;

    // The position passed is the top of the message widget in global coordinates
    // Adjust by subtracting the top safe area inset because dialog is inside SafeArea
    final messageTopPosition = messagePosition!.dy - topInset;
    final screenHeight = constraints.maxHeight;

    // Calculate where the reactions bar should be positioned (above the message)
    // This offset accounts for typical message padding and visual spacing
    final reactionBarOffset = 40.h;
    // Additional upward adjustment for better visual alignment
    final visualAlignmentOffset = 16.h;
    final messageTopY = messageTopPosition - reactionBarOffset - visualAlignmentOffset;

    final spaceBelow = screenHeight - messageTopPosition - 40.h;

    // Check if we need to move the message up to fit the menu
    final adjustedMessageTopY =
        spaceBelow < heightBelowMessage
            ? (messageTopY - (heightBelowMessage - spaceBelow)).clamp(
              reactionBarHeight + gapBetweenReactionsAndMessage + 20.h, // Minimum top position
              messageTopY, // Don't move down, only up
            )
            : messageTopY;

    // Position with reactions above the message position
    return (adjustedMessageTopY - reactionBarHeight - gapBetweenReactionsAndMessage).clamp(
      0.0,
      screenHeight,
    );
  }

  Widget _buildPositionedLayout({
    required double topSpacing,
    required double gapBetweenReactionsAndMessage,
    required double gapBetweenMessageAndMenu,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gap(topSpacing),
        buildReactions(),
        Gap(gapBetweenReactionsAndMessage),
        buildMessage(),
        Gap(gapBetweenMessageAndMenu),
        buildMenuItems(),
        const Spacer(),
      ],
    );
  }

  Widget _buildCenteredLayout() {
    return Column(
      children: [
        const Spacer(),
        buildReactions(),
        Gap(16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: buildMessage(),
        ),
        Gap(16.h),
        buildMenuItems(),
        Gap(32.h),
      ],
    );
  }
}
