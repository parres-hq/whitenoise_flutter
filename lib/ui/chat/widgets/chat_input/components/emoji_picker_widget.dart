import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmojiPickerWidget extends StatelessWidget {
  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.onBackspacePressed,
  });

  final ValueChanged<Emoji> onEmojiSelected;
  final VoidCallback onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => onEmojiSelected(emoji),
        onBackspacePressed: onBackspacePressed,
        config: Config(
          height: 256.h,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          ),
          viewOrderConfig: const ViewOrderConfig(
            top: EmojiPickerItem.categoryBar,
            middle: EmojiPickerItem.emojiView,
            bottom: EmojiPickerItem.searchBar,
          ),
          bottomActionBarConfig: BottomActionBarConfig(enabled: false),
        ),
      ),
    );
  }
}