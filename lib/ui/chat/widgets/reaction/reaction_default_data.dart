import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';

class DefaultData {
  // default list of five reactions to be displayed from emojis and a plus icon at the end
  // the plus icon will be used to add more reactions
  static const List<String> reactions = [
    '❤️',
    '👍️',
    '👎️',
    '😂️',
    '🚀',
    '😢',
    '🔥',
  ];

  // The default list of menuItems (for other users' messages - no delete option)
  static const List<MenuItem> menuItems = [reply, copy];

  static const List<MenuItem> myMessageMenuItems = [reply, copy, delete];

  static const MenuItem reply = MenuItem(
    label: 'Reply',
    assetPath: AssetsPaths.icReply,
  );

  static const MenuItem copy = MenuItem(
    label: 'Copy',
    assetPath: AssetsPaths.icCopy,
  );

  static const MenuItem delete = MenuItem(
    label: 'Delete',
    assetPath: AssetsPaths.icDelete,
    isDestructive: true,
  );
}
