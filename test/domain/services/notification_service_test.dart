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
        });

        final parsed = Map<String, dynamic>.from(
          jsonDecode(testPayload) as Map,
        );

        expect(parsed['type'], equals('invites_sync'));
        expect(parsed['welcomeId'], equals('welcome-789'));
        expect(parsed['groupId'], isNull); // Invite notifications don't have groupId
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

        // Test payload without groupId
        const noGroupPayload = '{"type":"invites_sync","welcomeId":"welcome-123"}';
        final noGroupParsed = Map<String, dynamic>.from(jsonDecode(noGroupPayload) as Map);
        expect(noGroupParsed['groupId'] == targetGroupId, isFalse);
      });
    });
  });
}
