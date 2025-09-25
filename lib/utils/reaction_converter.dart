import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/src/rust/api/messages.dart';

/// Converts ReactionSummary to Reaction list
class ReactionConverter {
  static List<Reaction> fromReactionSummary({
    required ReactionSummary reactionSummary,
    required Map<String, domain_user.User> usersMap,
  }) {
    final List<Reaction> convertedReactions = [];

    for (final userReaction in reactionSummary.userReactions) {
      final user =
          usersMap[userReaction.user] ??
          domain_user.User(
            id: userReaction.user,
            displayName: 'Unknown User',
            nip05: '',
            publicKey: userReaction.user,
          );

      final reaction = Reaction(
        emoji: userReaction.emoji,
        user: user,
        createdAt: userReaction.createdAt.toLocal(),
      );

      convertedReactions.add(reaction);
    }

    return convertedReactions;
  }
}
