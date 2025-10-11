import 'package:whitenoise/domain/models/message_model.dart';

class ReactionComparisonService {
  static bool areDifferent(List<Reaction> reactionsA, List<Reaction> reactionsB) {
    if (reactionsA.length != reactionsB.length) return true;
    final reactionsMapA = _buildReactionMap(reactionsA);
    final reactionsMapB = _buildReactionMap(reactionsB);
    if (reactionsMapA.keys.length != reactionsMapB.keys.length) return true;
    for (final emoji in reactionsMapA.keys) {
      if (!reactionsMapB.containsKey(emoji) ||
          !_areUserListsEqual(reactionsMapA[emoji]!, reactionsMapB[emoji]!)) {
        return true;
      }
    }
    return false;
  }

  static Map<String, List<String>> _buildReactionMap(List<Reaction> reactions) {
    final map = <String, List<String>>{};
    for (final reaction in reactions) {
      map.putIfAbsent(reaction.emoji, () => []).add(reaction.user.publicKey);
    }
    return map;
  }

  static bool _areUserListsEqual(List<String> users1, List<String> users2) {
    if (users1.length != users2.length) return false;
    final usersSet1 = Set<String>.from(users1);
    final usersSet2 = Set<String>.from(users2);
    if (usersSet1.length != usersSet2.length) return false;
    return usersSet1.containsAll(usersSet2);
  }
}
