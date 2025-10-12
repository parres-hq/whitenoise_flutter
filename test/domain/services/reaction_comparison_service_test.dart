import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/domain/services/reaction_comparison_service.dart';

void main() {
  group('ReactionComparisonService', () {
    final alice = User(
      id: '1',
      displayName: 'Alice',
      publicKey: 'pubkeyA',
      nip05: '',
    );
    final bob = User(
      id: '2',
      displayName: 'Bob',
      publicKey: 'pubkeyB',
      nip05: '',
    );
    final charlie = User(
      id: '3',
      displayName: 'Charlie',
      publicKey: 'pubkeyC',
      nip05: '',
    );

    group('areDifferent', () {
      group('with two empty reaction lists', () {
        test('returns false', () {
          final reactionsA = <Reaction>[];
          final reactionsB = <Reaction>[];
          final result = ReactionComparisonService.areDifferent(
            reactionsA,
            reactionsB,
          );
          expect(result, false);
        });
      });

      test('returns false for identical single reactions', () {
        final reactionsA = [Reaction(emoji: '👍', user: alice)];
        final reactionsB = [Reaction(emoji: '👍', user: alice)];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, false);
      });

      test('returns false for same reactions in different order', () {
        final reactionsA = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '❤️', user: bob),
        ];
        final reactionsB = [
          Reaction(emoji: '❤️', user: bob),
          Reaction(emoji: '👍', user: alice),
        ];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, false);
      });

      test('returns false for same emoji from different users in different order', () {
        final reactionsA = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '👍', user: bob),
          Reaction(emoji: '👍', user: charlie),
        ];
        final reactionsB = [
          Reaction(emoji: '👍', user: charlie),
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '👍', user: bob),
        ];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, false);
      });

      test('returns true for different reaction counts', () {
        final reactionsA = [Reaction(emoji: '👍', user: alice)];
        final reactionsB = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '❤️', user: bob),
        ];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, true);
      });

      test('returns true for different emojis', () {
        final reactionsA = [Reaction(emoji: '👍', user: alice)];
        final reactionsB = [Reaction(emoji: '❤️', user: alice)];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, true);
      });

      test('returns true for different users with same emoji', () {
        final reactionsA = [Reaction(emoji: '👍', user: alice)];
        final reactionsB = [Reaction(emoji: '👍', user: bob)];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, true);
      });

      test('returns true when one list is empty and other is not', () {
        final reactionsA = <Reaction>[];
        final reactionsB = [Reaction(emoji: '👍', user: alice)];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, true);
      });

      test('returns true for same emoji count but different users', () {
        final reactionsA = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '👍', user: bob),
        ];
        final reactionsB = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '👍', user: charlie),
        ];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, true);
      });

      test('returns false for same complex mixed reactions in different order', () {
        final reactionsA = [
          Reaction(emoji: '👍', user: alice),
          Reaction(emoji: '👍', user: bob),
          Reaction(emoji: '❤️', user: alice),
          Reaction(emoji: '😂', user: charlie),
        ];
        final reactionsB = [
          Reaction(emoji: '❤️', user: alice),
          Reaction(emoji: '😂', user: charlie),
          Reaction(emoji: '👍', user: bob),
          Reaction(emoji: '👍', user: alice),
        ];
        final result = ReactionComparisonService.areDifferent(
          reactionsA,
          reactionsB,
        );
        expect(result, false);
      });

      test(
        'returns true when same emoji has duplicate reactions from one user vs distinct users',
        () {
          final reactionsA = [
            Reaction(emoji: '👍', user: alice),
            Reaction(emoji: '👍', user: bob),
          ];
          final reactionsB = [
            Reaction(emoji: '👍', user: alice),
            Reaction(emoji: '👍', user: alice),
          ];
          final result = ReactionComparisonService.areDifferent(
            reactionsA,
            reactionsB,
          );
          expect(result, true);
        },
      );
    });
  });
}
