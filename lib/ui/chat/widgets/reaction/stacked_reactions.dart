import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class StackedReactions extends StatelessWidget {
  const StackedReactions({
    super.key,
    required this.reactions,
    this.size = 11.0,
    this.stackedValue = 4.0,
    this.direction = TextDirection.ltr,
  });

  // List of reactions
  final List<String> reactions;

  // Size of the reaction icon/text
  final double size;

  // Value used to calculate the horizontal offset of each reaction
  final double stackedValue;

  // Text direction (LTR or RTL)
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    Map<String, int> emojiCounts = {};

    for (var emoji in reactions) {
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
    }

    List<Map<String, dynamic>> emojis = emojiCounts.entries.map((e) => {'emoji': e.key, 'count': e.value}).toList();

    // Limit the number of displayed reactions to 5 for performance
    final reactionsToShow = emojis.length > 5 ? emojis.sublist(0, 5) : emojis;

    // Calculate the remaining number of reactions (if any)
    final remaining = emojis.length - reactionsToShow.length;

    // Helper function to create a reaction widget with proper styling
    Widget createReactionWidget(Map<String, dynamic> reaction, int index) {
      if (reaction['count'] == 1) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.glitch200,
            border: Border.all(
              color: AppColors.white, // or any custom color
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Text(reaction['emoji'], style: TextStyle(fontSize: size)),
            ),
          ),
        );
      } else {
        return Container(
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.glitch200,
            border: Border.all(
              color: AppColors.white, // or any custom color
              width: 1,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Text(" ${reaction['emoji']}${reaction['count']} ", style: TextStyle(fontSize: size)),
            ),
          ),
        );
      }
    }

    // Build the list of reaction widgets using the helper function
    final reactionWidgets =
        reactionsToShow.asMap().entries.map((entry) {
          final index = entry.key;
          final reaction = entry.value;
          return createReactionWidget(reaction, index);
        }).toList();

    return reactions.isEmpty
        ? const SizedBox.shrink()
        : Row(
          children: [
            Row(
              // Efficiently display reactions based on direction
              children: direction == TextDirection.ltr ? reactionWidgets.reversed.toList() : reactionWidgets,
            ),
            // Show remaining count only if there are more than 5 reactions
            if (remaining > 0)
              Container(
                padding: const EdgeInsets.all(2.0),
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface,
                      offset: const Offset(0.0, 1.0),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Text('+$remaining', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ),
          ],
        );
  }
}
