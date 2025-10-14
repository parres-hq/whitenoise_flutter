import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart' show Reaction;
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/reaction_converter.dart';

void main() {
  group('ReactionConverter Tests', () {
    group('fromReactionSummary', () {
      final haterUser = domain_user.User(
        id: 'hater_user_123',
        displayName: 'Hater John',
        nip05: 'john@hater.com',
        publicKey: 'npub1_hater_john_123',
      );
      final niceUser = domain_user.User(
        id: 'nice_user_456',
        displayName: 'Nice Jane',
        nip05: 'jane@nice.com',
        publicKey: 'npub1_nice_jane_456',
      );

      final dislikeReaction = UserReaction(
        user: 'npub1_hater_john_123',
        emoji: '👎',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234567890000),
      );
      final loveReaction = UserReaction(
        user: 'npub1_nice_jane_456',
        emoji: '❤️',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1234567891000),
      );

      group('when all users are known', () {
        final reactionSummary = ReactionSummary(
          byEmoji: [],
          userReactions: [
            dislikeReaction,
            loveReaction,
          ],
        );
        final usersMap = <String, domain_user.User>{
          'npub1_hater_john_123': haterUser,
          'npub1_nice_jane_456': niceUser,
        };
        test('converts to Reaction list with existing users', () {
          final result = ReactionConverter.fromReactionSummary(
            reactionSummary: reactionSummary,
            usersMap: usersMap,
          );

          expect(result, hasLength(2));
          final firstReaction = result[0];
          final secondReaction = result[1];

          expect(firstReaction, isA<Reaction>());
          expect(firstReaction.emoji, '👎');
          expect(firstReaction.user, haterUser);

          expect(secondReaction, isA<Reaction>());
          expect(secondReaction.emoji, '❤️');
          expect(secondReaction.user, niceUser);
        });
      });

      group('with unknown user', () {
        final reactionSummary = ReactionSummary(
          byEmoji: [],
          userReactions: [
            dislikeReaction,
            loveReaction,
          ],
        );
        final usersMap = <String, domain_user.User>{
          'npub1_hater_john_123': haterUser,
        };

        test('converts reaction with unknown user', () {
          final result = ReactionConverter.fromReactionSummary(
            reactionSummary: reactionSummary,
            usersMap: usersMap,
          );

          final firstReaction = result[0];
          expect(firstReaction, isA<Reaction>());
          expect(firstReaction.emoji, '👎');
          expect(firstReaction.user, haterUser);

          final secondReaction = result[1];
          expect(secondReaction, isA<Reaction>());
          expect(secondReaction.emoji, '❤️');

          final secondReactionUser = secondReaction.user;
          expect(secondReactionUser, isA<domain_user.User>());
          expect(secondReactionUser.id, 'npub1_nice_jane_456');
          expect(secondReactionUser.displayName, 'shared.unknownUser'.tr());
          expect(secondReactionUser.nip05, '');
          expect(secondReactionUser.publicKey, 'npub1_nice_jane_456');
        });
      });

      group('when reaction summary is empty', () {
        final reactionSummary = const ReactionSummary(
          byEmoji: [],
          userReactions: [],
        );

        final usersMap = <String, domain_user.User>{
          'npub1_hater_john_123': haterUser,
          'npub1_nice_jane_456': niceUser,
        };

        test('returns empty list', () {
          final result = ReactionConverter.fromReactionSummary(
            reactionSummary: reactionSummary,
            usersMap: usersMap,
          );
          expect(result, isEmpty);
        });
      });
    });
  });
}
