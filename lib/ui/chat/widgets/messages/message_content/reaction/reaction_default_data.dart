import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_menu_item.dart';

class DefaultData {
  // default list of five reactions to be displayed from emojis and a plus icon at the end
  // the plus icon will be used to add more reactions
  static const List<String> reactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😠',
    '⋯',
  ];

  // The default list of menuItems
  static const List<MenuItem> menuItems = [reply, copy, delete];

  static const List<MenuItem> myMessageMenuItems = [
    edit,
    copy,
    delete,
  ];

  static const MenuItem reply = MenuItem(
    label: 'Reply',
    icon: CarbonIcons.reply,
  );

  static const MenuItem copy = MenuItem(label: 'Copy', icon: CarbonIcons.copy);

  static const MenuItem edit = MenuItem(label: 'Edit', icon: CarbonIcons.edit);

  static const MenuItem delete = MenuItem(
    label: 'Delete',
    icon: CarbonIcons.delete,
    isDestructive: true,
  );
}
