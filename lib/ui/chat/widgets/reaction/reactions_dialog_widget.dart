import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

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

  final String id;
  final Widget messageWidget;
  final Function(String) onReactionTap;
  final Function(MenuItem) onContextMenuTap;
  final List<MenuItem> menuItems;
  final List<String> reactions;
  final Alignment widgetAlignment;
  final double menuItemsWidth;

  @override
  State<ReactionsDialogWidget> createState() => _ReactionsDialogWidgetState();
}

class _ReactionsDialogWidgetState extends State<ReactionsDialogWidget> {
  bool reactionClicked = false;
  int? clickedReactionIndex;
  int? clickedContextMenuIndex;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReactionsRow(
                reactions: widget.reactions,
                widgetAlignment: widget.widgetAlignment,
                onReactionTap: widget.onReactionTap,
                reactionClicked: reactionClicked,
                clickedReactionIndex: clickedReactionIndex,
                onReactionSelected: (index) {
                  setState(() {
                    reactionClicked = true;
                    clickedReactionIndex = index;
                  });
                  Navigator.of(context).pop();
                },
              ),
              Gap(10.h),
              Align(
                alignment: widget.widgetAlignment,
                child: Hero(
                  tag: widget.id,
                  child: widget.messageWidget,
                ),
              ),
              Gap(10.h),
              ContextMenuItems(
                menuItems: widget.menuItems,
                widgetAlignment: widget.widgetAlignment,
                menuItemsWidth: widget.menuItemsWidth,
                clickedContextMenuIndex: clickedContextMenuIndex,
                onContextMenuTap: (item) {
                  setState(() {
                    clickedContextMenuIndex = widget.menuItems.indexOf(item);
                  });
                  Navigator.of(context).pop();
                  widget.onContextMenuTap(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays context menu items for chat messages.
class ContextMenuItems extends StatelessWidget {
  const ContextMenuItems({
    super.key,
    required this.menuItems,
    required this.widgetAlignment,
    required this.onContextMenuTap,
    required this.menuItemsWidth,
    this.clickedContextMenuIndex,
  });

  final List<MenuItem> menuItems;
  final Alignment widgetAlignment;
  final Function(MenuItem) onContextMenuTap;
  final double menuItemsWidth;
  final int? clickedContextMenuIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widgetAlignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * menuItemsWidth,
          decoration: BoxDecoration(color: AppColors.glitch80, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var item in menuItems)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                      child: InkWell(
                        onTap: () => onContextMenuTap(item),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(color: item.isDestructive ? Colors.red : AppColors.glitch900),
                            ),
                            Pulse(
                              infinite: false,
                              duration: const Duration(milliseconds: 100),
                              animate: clickedContextMenuIndex == menuItems.indexOf(item),
                              child: Icon(
                                size: 20,
                                item.icon,
                                color: item.isDestructive ? Colors.red : Theme.of(context).textTheme.bodyMedium!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (menuItems.last != item) Container(color: Colors.grey.shade300, height: 1),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a row of reaction emojis.
class ReactionsRow extends StatelessWidget {
  const ReactionsRow({
    super.key,
    required this.reactions,
    required this.widgetAlignment,
    required this.onReactionTap,
    required this.onReactionSelected,
    this.reactionClicked = false,
    this.clickedReactionIndex,
  });

  final List<String> reactions;
  final Alignment widgetAlignment;
  final Function(String) onReactionTap;
  final Function(int) onReactionSelected;
  final bool reactionClicked;
  final int? clickedReactionIndex;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widgetAlignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: AppColors.glitch80, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var reaction in reactions)
                FadeInLeft(
                  from: 0 + (reactions.indexOf(reaction) * 20).toDouble(),
                  duration: const Duration(milliseconds: 50),
                  delay: const Duration(milliseconds: 0),
                  child: InkWell(
                    onTap: () {
                      final index = reactions.indexOf(reaction);
                      onReactionSelected(index);
                      onReactionTap(reaction);
                    },
                    child: Pulse(
                      infinite: false,
                      duration: const Duration(milliseconds: 50),
                      animate: reactionClicked && clickedReactionIndex == reactions.indexOf(reaction),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7.0, 2.0, 7.0, 2),
                        decoration: BoxDecoration(
                          color: reaction == '⋯' ? AppColors.glitch200 : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(reaction, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
