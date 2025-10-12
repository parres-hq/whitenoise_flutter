import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
  static List<MenuItem> get menuItems => [reply, copy];

  static List<MenuItem> get myMessageMenuItems => [reply, copy, delete];

  static MenuItem get reply => MenuItem(
    label: 'chats.replyAction'.tr(),
    assetPath: AssetsPaths.icReply,
  );

  static MenuItem get copy => MenuItem(
    label: 'chats.copyAction'.tr(),
    assetPath: AssetsPaths.icCopy,
  );

  static MenuItem get delete => MenuItem(
    label: 'chats.deleteAction'.tr(),
    assetPath: AssetsPaths.icDelete,
    isDestructive: true,
  );
}
