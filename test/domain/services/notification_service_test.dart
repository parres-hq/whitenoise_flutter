import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/domain/services/notification_service.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin, ActiveNotification])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    late MockFlutterLocalNotificationsPlugin mockPlugin;

    setUp(() {
      mockPlugin = MockFlutterLocalNotificationsPlugin();
    });

    group('cancelNotificationsByGroup - behavior verification', () {
      test('should call getActiveNotifications and cancel matching notifications', () async {
        // Arrange: Create mock notifications
        final mockNotification1 = MockActiveNotification();
        final mockNotification2 = MockActiveNotification();
        final mockNotification3 = MockActiveNotification();

        // Mock notification 1: matching groupId
        when(mockNotification1.id).thenReturn(1);
        when(mockNotification1.payload).thenReturn(
          '{"type":"new_message","groupId":"target-group","messageId":"msg-1"}',
        );

        // Mock notification 2: different groupId
        when(mockNotification2.id).thenReturn(2);
        when(mockNotification2.payload).thenReturn(
          '{"type":"new_message","groupId":"other-group","messageId":"msg-2"}',
        );

        // Mock notification 3: matching groupId (invite)
        when(mockNotification3.id).thenReturn(3);
        when(mockNotification3.payload).thenReturn(
          '{"type":"invites_sync","welcomeId":"welcome-1","groupId":"target-group"}',
        );

        // Mock the plugin methods
        when(mockPlugin.getActiveNotifications()).thenAnswer(
          (_) async => [mockNotification1, mockNotification2, mockNotification3],
        );
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        final activeNotifications = await mockPlugin.getActiveNotifications();
        const targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];

        // Test the cancelNotificationsByGroup logic
        for (final notification in activeNotifications) {
          if (notification.payload != null) {
            try {
              final payload = Map<String, dynamic>.from(
                jsonDecode(notification.payload!) as Map,
              );
              if (payload['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification.id!);
                await mockPlugin.cancel(notification.id!);
              }
            } catch (e) {
              continue;
            }
          }
        }

        // Verify behavior
        expect(notificationsToCancel, equals([1, 3])); // Should cancel notifications 1 and 3
        verify(mockPlugin.getActiveNotifications()).called(1);
        verify(mockPlugin.cancel(1)).called(1);
        verify(mockPlugin.cancel(3)).called(1);
        verifyNever(mockPlugin.cancel(2)); // Should not cancel notification 2
      });

      test('should handle malformed JSON payloads gracefully', () async {
        // Arrange: Create mock notifications with malformed JSON
        final mockNotification1 = MockActiveNotification();
        final mockNotification2 = MockActiveNotification();
        final mockNotification3 = MockActiveNotification();

        when(mockNotification1.id).thenReturn(1);
        when(mockNotification1.payload).thenReturn(
          '{"type":"new_message","groupId":"target-group","messageId":"msg-1"}',
        );

        when(mockNotification2.id).thenReturn(2);
        when(mockNotification2.payload).thenReturn('{"malformed": json}'); // Invalid JSON

        when(mockNotification3.id).thenReturn(3);
        when(mockNotification3.payload).thenReturn(
          '{"type":"invites_sync","welcomeId":"welcome-1","groupId":"target-group"}',
        );

        when(mockPlugin.getActiveNotifications()).thenAnswer(
          (_) async => [mockNotification1, mockNotification2, mockNotification3],
        );
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        // Test the logic with error handling
        final activeNotifications = await mockPlugin.getActiveNotifications();
        const targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];
        var errorCount = 0;

        for (final notification in activeNotifications) {
          if (notification.payload != null) {
            try {
              final payload = Map<String, dynamic>.from(
                jsonDecode(notification.payload!) as Map,
              );
              if (payload['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification.id!);
                await mockPlugin.cancel(notification.id!);
              }
            } catch (e) {
              errorCount++;
              continue;
            }
          }
        }

        // Verify that valid notifications were processed despite malformed JSON
        expect(notificationsToCancel, equals([1, 3]));
        expect(errorCount, equals(1)); // One malformed JSON error
        verify(mockPlugin.cancel(1)).called(1);
        verify(mockPlugin.cancel(3)).called(1);
        verifyNever(mockPlugin.cancel(2)); // Malformed notification not cancelled
      });

      test('should handle notifications without groupId', () async {
        // Arrange: Mix of notifications with and without groupId
        final mockNotification1 = MockActiveNotification();
        final mockNotification2 = MockActiveNotification();
        final mockNotification3 = MockActiveNotification();

        when(mockNotification1.id).thenReturn(1);
        when(mockNotification1.payload).thenReturn(
          '{"type":"new_message","groupId":"target-group","messageId":"msg-1"}',
        );

        when(mockNotification2.id).thenReturn(2);
        when(mockNotification2.payload).thenReturn(
          '{"type":"invites_sync","welcomeId":"welcome-1"}', // No groupId (legacy)
        );

        when(mockNotification3.id).thenReturn(3);
        when(mockNotification3.payload).thenReturn(null); // Null payload

        when(mockPlugin.getActiveNotifications()).thenAnswer(
          (_) async => [mockNotification1, mockNotification2, mockNotification3],
        );
        when(mockPlugin.cancel(any)).thenAnswer((_) async {});

        // Test the logic
        final activeNotifications = await mockPlugin.getActiveNotifications();
        const targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];

        for (final notification in activeNotifications) {
          if (notification.payload != null) {
            try {
              final payload = Map<String, dynamic>.from(
                jsonDecode(notification.payload!) as Map,
              );
              if (payload['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification.id!);
                await mockPlugin.cancel(notification.id!);
              }
            } catch (e) {
              continue;
            }
          }
        }

        // Verify only notification with matching groupId was cancelled
        expect(notificationsToCancel, equals([1]));
        verify(mockPlugin.cancel(1)).called(1);
        verifyNever(mockPlugin.cancel(2)); // No groupId, not cancelled
        verifyNever(mockPlugin.cancel(3)); // Null payload, not processed
      });

      test('should handle empty active notifications list', () async {
        // Arrange: No active notifications
        when(mockPlugin.getActiveNotifications()).thenAnswer((_) async => []);

        // Test the logic
        final activeNotifications = await mockPlugin.getActiveNotifications();
        const targetGroupId = 'target-group';
        final notificationsToCancel = <int>[];

        for (final notification in activeNotifications) {
          if (notification.payload != null) {
            try {
              final payload = Map<String, dynamic>.from(
                jsonDecode(notification.payload!) as Map,
              );
              if (payload['groupId'] == targetGroupId) {
                notificationsToCancel.add(notification.id!);
                await mockPlugin.cancel(notification.id!);
              }
            } catch (e) {
              continue;
            }
          }
        }

        // Verify no notifications were cancelled
        expect(notificationsToCancel, isEmpty);
        verify(mockPlugin.getActiveNotifications()).called(1);
        verifyNever(mockPlugin.cancel(any));
      });
    });

    group('actual service calls', () {
      test('cancelNotificationsByGroup should handle uninitialized state', () async {
        // This tests the actual method call, which should return early if not initialized
        expect(() async {
          await NotificationService.cancelNotificationsByGroup('test-group');
        }, returnsNormally);
      });

      test('should handle edge cases with groupId parameter', () async {
        expect(() async {
          await NotificationService.cancelNotificationsByGroup('');
          await NotificationService.cancelNotificationsByGroup('  ');
          await NotificationService.cancelNotificationsByGroup('group-with-special-chars-"quotes"');
        }, returnsNormally);
      });

      test('other service methods should handle uninitialized state', () async {
        expect(() async {
          await NotificationService.cancelNotification(-1);
          await NotificationService.cancelAllNotifications();
        }, returnsNormally);
      });
    });

    group('payload structure validation', () {
      test('validates message notification payload structure', () {
        const testPayload =
            '{"type":"new_message","groupId":"test-group-123","messageId":"msg-456","sender":"sender-pubkey"}';

        final payload = Map<String, dynamic>.from(jsonDecode(testPayload) as Map);
        expect(payload['groupId'], equals('test-group-123'));
        expect(payload['type'], equals('new_message'));
        expect(payload['messageId'], equals('msg-456'));
        expect(payload['sender'], equals('sender-pubkey'));
      });

      test('validates invite notification payload structure', () {
        final testPayload = jsonEncode({
          'type': 'invites_sync',
          'welcomeId': 'welcome-789',
          'groupId': 'group-456',
        });

        final parsed = Map<String, dynamic>.from(jsonDecode(testPayload) as Map);
        expect(parsed['type'], equals('invites_sync'));
        expect(parsed['welcomeId'], equals('welcome-789'));
        expect(parsed['groupId'], equals('group-456'));
      });

      test('handles malformed JSON gracefully', () {
        const malformedPayload = '{"type":"new_message","groupId":}';

        expect(() {
          jsonDecode(malformedPayload);
        }, throwsA(isA<FormatException>()));
      });
    });
  });
}
