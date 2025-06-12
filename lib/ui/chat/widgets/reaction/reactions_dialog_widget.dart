import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';

import '../../../core/themes/colors.dart';

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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // reactions
              buildReactions(context),
              const SizedBox(height: 10),
              // message
              buildMessage(),
              const SizedBox(height: 10),
              // context menu
              buildMenuItems(context),
            ],
          ),
        ),
      ),
    );
  }

  Align buildMenuItems(BuildContext context) {
    return Align(
      alignment: widget.widgetAlignment,
      child: // contextMenu for reply, copy, delete
          Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * widget.menuItemsWidth,
          decoration: BoxDecoration(
            color: AppColors.glitch80,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var item in widget.menuItems)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            clickedContextMenuIndex = widget.menuItems.indexOf(
                              item,
                            );
                          });

                          Navigator.of(context).pop();
                          widget.onContextMenuTap(item);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color:
                                    item.isDestructive
                                        ? Colors.red
                                        : AppColors.glitch900,
                              ),
                            ),
                            Pulse(
                              duration: const Duration(milliseconds: 100),
                              animate:
                                  clickedContextMenuIndex ==
                                  widget.menuItems.indexOf(item),
                              child: Icon(
                                size: 20,
                                item.icon,
                                color:
                                    item.isDestructive
                                        ? Colors.red
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (widget.menuItems.last != item)
                      Container(color: Colors.grey.shade300, height: 1),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Align buildMessage() {
    return Align(
      alignment: widget.widgetAlignment,
      child: Hero(tag: widget.id, child: widget.messageWidget),
    );
  }

  Align buildReactions(BuildContext context) {
    return Align(
      alignment: widget.widgetAlignment,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.glitch80,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var reaction in widget.reactions)
                FadeInLeft(
                  from:
                      0 + (widget.reactions.indexOf(reaction) * 20).toDouble(),
                  duration: const Duration(milliseconds: 50),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        reactionClicked = true;
                        clickedReactionIndex = widget.reactions.indexOf(
                          reaction,
                        );
                      });
                      Navigator.of(context).pop();
                      widget.onReactionTap(reaction);
                    },
                    child: Pulse(
                      duration: const Duration(milliseconds: 50),
                      animate:
                          reactionClicked &&
                          clickedReactionIndex ==
                              widget.reactions.indexOf(reaction),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7.0, 2.0, 7.0, 2),
                        decoration: BoxDecoration(
                          color:
                              reaction == '⋯'
                                  ? AppColors.glitch200
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reaction,
                          style: const TextStyle(fontSize: 22),
                        ),
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
