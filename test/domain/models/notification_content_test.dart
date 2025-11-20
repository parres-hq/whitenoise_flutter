import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/notification_content.dart';

void main() {
  group('NotificationContent', () {
    late Map<String, dynamic> testPayload;

    setUp(() {
      testPayload = {
        'type': 'new_message',
        'groupId': 'group123',
        'messageId': 'msg123',
        'sender': 'pubkey123',
        'deepLink': 'whitenoise://chats/group123',
      };
    });

    group('constructor', () {
      late NotificationContent content;

      setUp(() {
        content = NotificationContent(
          title: 'Test Chat',
          body: 'Test message',
          groupKey: 'group123',
          payload: testPayload,
        );
      });

      test('title matches provided value', () {
        expect(content.title, 'Test Chat');
      });

      test('body matches provided value', () {
        expect(content.body, 'Test message');
      });

      test('groupKey matches provided value', () {
        expect(content.groupKey, 'group123');
      });

      test('payload matches provided map', () {
        expect(content.payload, testPayload);
      });

      test('payload contains expected type', () {
        expect(content.payload['type'], 'new_message');
      });

      test('payload contains expected groupId', () {
        expect(content.payload['groupId'], 'group123');
      });

      test('payload contains expected deepLink', () {
        expect(content.payload['deepLink'], 'whitenoise://chats/group123');
      });
    });

    group('equality', () {
      late NotificationContent content1;
      late NotificationContent content2;

      setUp(() {
        content1 = NotificationContent(
          title: 'Test Chat',
          body: 'Test message',
          groupKey: 'group123',
          payload: testPayload,
        );
      });

      test('same values are equal', () {
        content2 = NotificationContent(
          title: 'Test Chat',
          body: 'Test message',
          groupKey: 'group123',
          payload: testPayload,
        );
        expect(content1, equals(content2));
      });

      test('different title are not equal', () {
        content2 = NotificationContent(
          title: 'Different Chat',
          body: 'Test message',
          groupKey: 'group123',
          payload: testPayload,
        );
        expect(content1, isNot(equals(content2)));
      });

      test('different body are not equal', () {
        content2 = NotificationContent(
          title: 'Test Chat',
          body: 'Different message',
          groupKey: 'group123',
          payload: testPayload,
        );
        expect(content1, isNot(equals(content2)));
      });

      test('different groupKey are not equal', () {
        content2 = NotificationContent(
          title: 'Test Chat',
          body: 'Test message',
          groupKey: 'group456',
          payload: testPayload,
        );
        expect(content1, isNot(equals(content2)));
      });
    });

    group('copyWith', () {
      late NotificationContent original;
      late NotificationContent copied;

      setUp(() {
        original = NotificationContent(
          title: 'Original Title',
          body: 'Original Body',
          groupKey: 'group123',
          payload: testPayload,
        );
      });

      test('updates title', () {
        copied = original.copyWith(title: 'New Title');
        expect(copied.title, 'New Title');
      });

      test('preserves body when updating title', () {
        copied = original.copyWith(title: 'New Title');
        expect(copied.body, 'Original Body');
      });

      test('updates body', () {
        copied = original.copyWith(body: 'New Body');
        expect(copied.body, 'New Body');
      });

      test('preserves title when updating body', () {
        copied = original.copyWith(body: 'New Body');
        expect(copied.title, 'Original Title');
      });

      test('updates groupKey', () {
        copied = original.copyWith(groupKey: 'group456');
        expect(copied.groupKey, 'group456');
      });

      test('preserves other fields when updating groupKey', () {
        copied = original.copyWith(groupKey: 'group456');
        expect(copied.title, 'Original Title');
        expect(copied.body, 'Original Body');
      });
    });
  });
}
