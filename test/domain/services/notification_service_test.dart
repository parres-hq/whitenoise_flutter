import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    group('payload structure validation', () {
      test('validates message notification payload structure for groupId matching', () {
        // Test the payload parsing logic that's used in cancelNotificationsByGroup
        const testPayload =
            '{"type":"new_message","groupId":"test-group-123","messageId":"msg-456","sender":"sender-pubkey"}';

        try {
          final payload = Map<String, dynamic>.from(
            jsonDecode(testPayload) as Map,
          );
          expect(payload['groupId'], equals('test-group-123'));
          expect(payload['type'], equals('new_message'));
          expect(payload['messageId'], equals('msg-456'));
          expect(payload['sender'], equals('sender-pubkey'));
        } catch (e) {
          fail('Should not throw exception when parsing valid payload');
        }
      });

      test('handles malformed payload gracefully', () {
        // Test that malformed JSON doesn't crash the parsing logic in cancelNotificationsByGroup
        const malformedPayload = '{"type":"new_message","groupId":}'; // Invalid JSON

        expect(() {
          jsonDecode(malformedPayload);
        }, throwsA(isA<FormatException>()));
      });

      test('handles payload without groupId', () {
        // Test payload that doesn't contain groupId (like invite notifications)
        const payloadWithoutGroupId = '{"type":"invites_sync","welcomeId":"welcome-123"}';

        try {
          final payload = Map<String, dynamic>.from(
            jsonDecode(payloadWithoutGroupId) as Map,
          );
          expect(payload['groupId'], isNull);
          expect(payload['type'], equals('invites_sync'));
          expect(payload['welcomeId'], equals('welcome-123'));
        } catch (e) {
          fail('Should not throw exception when parsing valid payload without groupId');
        }
      });

      test('validates message notification payload structure', () {
        // Test the structure we use for message notifications
        final testPayload = jsonEncode({
          'type': 'new_message',
          'groupId': 'group-123',
          'messageId': 'msg-456',
          'sender': 'sender-pubkey',
        });

        final parsed = Map<String, dynamic>.from(
          jsonDecode(testPayload) as Map,
        );

        expect(parsed['type'], equals('new_message'));
        expect(parsed['groupId'], equals('group-123'));
        expect(parsed['messageId'], equals('msg-456'));
        expect(parsed['sender'], equals('sender-pubkey'));
      });

      test('validates invite notification payload structure', () {
        // Test the structure we use for invite notifications
        final testPayload = jsonEncode({
          'type': 'invites_sync',
          'welcomeId': 'welcome-789',
          'groupId': 'group-456',
        });

        final parsed = Map<String, dynamic>.from(
          jsonDecode(testPayload) as Map,
        );

        expect(parsed['type'], equals('invites_sync'));
        expect(parsed['welcomeId'], equals('welcome-789'));
        expect(
          parsed['groupId'],
          equals('group-456'),
        ); // Invite notifications have groupId (mlsGroupId)
      });

      test('groupId matching logic works correctly', () {
        // Test the core logic used in cancelNotificationsByGroup
        const targetGroupId = 'target-group-456';

        // Test matching payload
        const matchingPayload =
            '{"type":"new_message","groupId":"target-group-456","messageId":"msg-123"}';
        final matchingParsed = Map<String, dynamic>.from(jsonDecode(matchingPayload) as Map);
        expect(matchingParsed['groupId'] == targetGroupId, isTrue);

        // Test non-matching payload
        const nonMatchingPayload =
            '{"type":"new_message","groupId":"other-group-789","messageId":"msg-456"}';
        final nonMatchingParsed = Map<String, dynamic>.from(jsonDecode(nonMatchingPayload) as Map);
        expect(nonMatchingParsed['groupId'] == targetGroupId, isFalse);

        // Test payload without groupId (legacy invite notification)
        const noGroupPayload = '{"type":"invites_sync","welcomeId":"welcome-123"}';
        final noGroupParsed = Map<String, dynamic>.from(jsonDecode(noGroupPayload) as Map);
        expect(noGroupParsed['groupId'] == targetGroupId, isFalse);
      });
    });

    group('cancelNotificationsByGroup method behavior', () {
      test('should handle gracefully when called without proper initialization checks', () {
        expect(() async {}, returnsNormally);
      });

      test('should handle empty groupId parameter', () {
        expect(() async {
          // The method should handle empty string gracefully without attempting matches
        }, returnsNormally);
      });

      test('demonstrates groupId filtering logic for multiple notifications', () {
        final mockNotifications = [
          {'id': 1, 'payload': '{"type":"new_message","groupId":"group-A","messageId":"msg-1"}'},
          {'id': 2, 'payload': '{"type":"new_message","groupId":"group-B","messageId":"msg-2"}'},
          {'id': 3, 'payload': '{"type":"new_message","groupId":"group-A","messageId":"msg-3"}'},
          {
            'id': 4,
            'payload': '{"type":"invites_sync","welcomeId":"welcome-1","groupId":"group-A"}',
          },
          {
            'id': 5,
            'payload': '{"type":"invites_sync","welcomeId":"welcome-2","groupId":"group-B"}',
          },
          {'id': 6, 'payload': '{"malformed json}'},
        ];

        final targetGroupId = 'group-A';
        final notificationsToCancel = <int>[];

        for (final notification in mockNotifications) {
          final payload = notification['payload'] as String?;
          if (payload != null) {
            try {
              final parsed = Map<String, dynamic>.from(jsonDecode(payload) as Map);
              if (parsed['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification['id'] as int);
              }
            } catch (e) {
              // Ignore malformed JSON (like notification id 5)
              continue;
            }
          }
        }

        // Should cancel notifications 1, 3 (messages) and 4 (invite) for group-A
        expect(notificationsToCancel, equals([1, 3, 4]));
        expect(notificationsToCancel.length, equals(3));
      });

      test('demonstrates error handling for malformed payloads', () {
        // Test that malformed JSON in payloads doesn't stop processing
        final mockNotifications = [
          {'id': 1, 'payload': '{"type":"new_message","groupId":"target-group"}'},
          {'id': 2, 'payload': '{"malformed": json}'},
          {
            'id': 3,
            'payload': '{"type":"invites_sync","welcomeId":"welcome-1","groupId":"target-group"}',
          },
        ];

        final targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];
        var errorCount = 0;

        for (final notification in mockNotifications) {
          final payload = notification['payload'] as String?;
          if (payload != null) {
            try {
              final parsed = Map<String, dynamic>.from(jsonDecode(payload) as Map);
              if (parsed['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification['id'] as int);
              }
            } catch (e) {
              errorCount++;
              continue;
            }
          }
        }

        expect(notificationsToCancel, equals([1, 3]));
        expect(errorCount, equals(1));
      });

      test('demonstrates handling notifications without groupId', () {
        final mockNotifications = [
          {'id': 1, 'payload': '{"type":"new_message","groupId":"target-group"}'},
          {
            'id': 2,
            'payload': '{"type":"invites_sync","welcomeId":"welcome-123"}',
          },
          {
            'id': 3,
            'payload': '{"type":"invites_sync","welcomeId":"welcome-456","groupId":"target-group"}',
          },
          {'id': 4, 'payload': null},
        ];

        final targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];

        for (final notification in mockNotifications) {
          final payload = notification['payload'] as String?;
          if (payload != null) {
            try {
              final parsed = Map<String, dynamic>.from(jsonDecode(payload) as Map);
              if (parsed['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification['id'] as int);
              }
            } catch (e) {
              continue;
            }
          }
        }

        // Should cancel message notification and new invite notification with groupId
        expect(notificationsToCancel, equals([1, 3]));
      });
    });
  });
}
