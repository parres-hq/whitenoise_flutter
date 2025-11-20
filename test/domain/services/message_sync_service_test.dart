import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/services/message_sync_service.dart';
import 'package:whitenoise/domain/services/notification_content_builder_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

import '../../test_helpers.dart';

ChatMessage createTestMessage({
  required String id,
  required String pubkey,
  required String content,
  required DateTime createdAt,
  bool isDeleted = false,
  List<MediaFile> mediaAttachments = const [],
  int kind = 9,
}) {
  return ChatMessage(
    id: id,
    pubkey: pubkey,
    content: content,
    createdAt: createdAt,
    tags: [],
    isReply: false,
    isDeleted: isDeleted,
    contentTokens: [],
    reactions: const ReactionSummary(byEmoji: [], userReactions: []),
    mediaAttachments: mediaAttachments,
    kind: kind,
  );
}

Welcome createTestWelcome({
  required String id,
  required String mlsGroupId,
  required String groupName,
  required String welcomer,
  required BigInt createdAt,
  WelcomeState state = WelcomeState.pending,
}) {
  return Welcome(
    id: id,
    mlsGroupId: mlsGroupId,
    nostrGroupId: 'nostr-$id',
    groupName: groupName,
    groupDescription: 'Test group description',
    groupAdminPubkeys: [],
    groupRelays: [],
    welcomer: welcomer,
    memberCount: 2,
    state: state,
    createdAt: createdAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeTestLocalization();
  });

  group('MessageSyncService', () {
    const String testGroupId = 'test-group-123';
    const String testActivePubkey = 'test-pubkey-123';
    const String testCurrentUserPubkey = 'current-user-pubkey';
    final DateTime baseTestTime = DateTime(2025, 1, 15, 10, 30);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('filterNewMessages', () {
      test('returns empty list for empty currentUserPubkey', () async {
        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'Hello',
            createdAt: baseTestTime,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          '', // empty pubkey
          testGroupId,
          null,
        );

        expect(result, isEmpty);
      });

      test('returns empty list for empty groupId', () async {
        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'Hello',
            createdAt: baseTestTime,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          '', // empty groupId
          null,
        );

        expect(result, isEmpty);
      });

      test('filters out messages from current user', () async {
        final now = DateTime.now();
        final safeTime = now.subtract(const Duration(seconds: 5)); // Outside buffer window
        final syncTime = safeTime.subtract(const Duration(minutes: 5));

        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: testCurrentUserPubkey, // from current user
            content: 'My message',
            createdAt: safeTime,
          ),
          createTestMessage(
            id: 'msg2',
            pubkey: 'other-user',
            content: 'Other message',
            createdAt: safeTime,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          syncTime,
        );

        expect(result.length, 1);
        expect(result.first.id, 'msg2');
      });

      test('filters out deleted messages', () async {
        final now = DateTime.now();
        final safeTime = now.subtract(const Duration(seconds: 5)); // Outside buffer window
        final syncTime = safeTime.subtract(const Duration(minutes: 5));

        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'Normal message',
            createdAt: safeTime,
          ),
          createTestMessage(
            id: 'msg2',
            pubkey: 'other-user',
            content: 'Deleted message',
            createdAt: safeTime,
            isDeleted: true, // deleted
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          syncTime,
        );

        expect(result.length, 1);
        expect(result.first.id, 'msg1');
      });

      test('filters messages based on sync time', () async {
        final now = DateTime.now();
        final syncTime = now.subtract(const Duration(minutes: 10));
        final safeTime = now.subtract(const Duration(seconds: 5));

        final messages = [
          createTestMessage(
            id: 'old-msg',
            pubkey: 'other-user',
            content: 'Old message',
            createdAt: syncTime.subtract(const Duration(minutes: 5)), // before sync
          ),
          createTestMessage(
            id: 'new-msg',
            pubkey: 'other-user',
            content: 'New message',
            createdAt: safeTime, // after sync, before buffer
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          syncTime,
        );

        expect(result.length, 1);
        expect(result.first.id, 'new-msg');
      });

      test('respects buffer window to avoid race conditions', () async {
        final now = DateTime.now();
        final tooRecent = now.subtract(const Duration(milliseconds: 500)); // within 1s buffer

        final messages = [
          createTestMessage(
            id: 'too-recent',
            pubkey: 'other-user',
            content: 'Too recent',
            createdAt: tooRecent,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          now.subtract(const Duration(minutes: 5)),
        );

        expect(result, isEmpty); // Should be filtered out due to buffer
      });

      test('sorts messages by creation time', () async {
        final now = DateTime.now();
        final syncTime = now.subtract(const Duration(minutes: 15));
        final baseTime = now.subtract(const Duration(seconds: 15)); // Outside buffer window

        final messages = [
          createTestMessage(
            id: 'msg2',
            pubkey: 'other-user',
            content: 'Second',
            createdAt: baseTime.subtract(const Duration(seconds: 5)),
          ),
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'First',
            createdAt: baseTime.subtract(const Duration(seconds: 10)),
          ),
          createTestMessage(
            id: 'msg3',
            pubkey: 'other-user',
            content: 'Third',
            createdAt: baseTime,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          syncTime,
        );

        expect(result.length, 3);
        expect(result[0].id, 'msg1'); // Should be in chronological order
        expect(result[1].id, 'msg2');
        expect(result[2].id, 'msg3');
      });

      test('uses default lookback window when no sync time provided', () async {
        final now = DateTime.now();
        final oldMessage = createTestMessage(
          id: 'old-msg',
          pubkey: 'other-user',
          content: 'Very old',
          createdAt: now.subtract(const Duration(hours: 2)), // older than 1 hour default
        );
        final recentMessage = createTestMessage(
          id: 'recent-msg',
          pubkey: 'other-user',
          content: 'Recent',
          createdAt: now.subtract(const Duration(minutes: 30)), // within 1 hour
        );

        final result = await MessageSyncService.filterNewMessages(
          [oldMessage, recentMessage],
          testCurrentUserPubkey,
          testGroupId,
          null, // no sync time
        );

        expect(result.length, 1);
        expect(result.first.id, 'recent-msg');
      });
    });

    group('sync timestamp management', () {
      group('setLastMessageSyncTime and getLastMessageSyncTime', () {
        test('stores and retrieves sync time correctly', () async {
          final testTime = baseTestTime;

          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: testActivePubkey,
            groupId: testGroupId,
            time: testTime,
          );

          final retrieved = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: testActivePubkey,
            groupId: testGroupId,
          );

          expect(retrieved, equals(testTime));
        });

        test('returns null when no sync time stored', () async {
          final retrieved = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: testActivePubkey,
            groupId: 'non-existent-group',
          );

          expect(retrieved, isNull);
        });

        test('handles empty pubkey gracefully', () async {
          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: '',
            groupId: testGroupId,
            time: baseTestTime,
          );

          final retrieved = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: '',
            groupId: testGroupId,
          );

          expect(retrieved, isNull);
        });

        test('handles empty groupId gracefully', () async {
          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: testActivePubkey,
            groupId: '',
            time: baseTestTime,
          );

          final retrieved = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: testActivePubkey,
            groupId: '',
          );

          expect(retrieved, isNull);
        });

        test('different accounts have separate sync times', () async {
          const pubkey1 = 'pubkey1';
          const pubkey2 = 'pubkey2';
          final time1 = baseTestTime;
          final time2 = baseTestTime.add(const Duration(hours: 1));

          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: pubkey1,
            groupId: testGroupId,
            time: time1,
          );

          await MessageSyncService.setLastMessageSyncTime(
            activePubkey: pubkey2,
            groupId: testGroupId,
            time: time2,
          );

          final retrieved1 = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: pubkey1,
            groupId: testGroupId,
          );

          final retrieved2 = await MessageSyncService.getLastMessageSyncTime(
            activePubkey: pubkey2,
            groupId: testGroupId,
          );

          expect(retrieved1, equals(time1));
          expect(retrieved2, equals(time2));
        });
      });

      group('setLastInviteSyncTime and getLastInviteSyncTime', () {
        test('stores and retrieves invite sync time correctly', () async {
          final testTime = baseTestTime;

          await MessageSyncService.setLastInviteSyncTime(
            activePubkey: testActivePubkey,
            time: testTime,
          );

          final retrieved = await MessageSyncService.getLastInviteSyncTime(
            activePubkey: testActivePubkey,
          );

          expect(retrieved, equals(testTime));
        });

        test('returns null when no invite sync time stored', () async {
          final retrieved = await MessageSyncService.getLastInviteSyncTime(
            activePubkey: 'non-existent-pubkey',
          );

          expect(retrieved, isNull);
        });

        test('handles empty pubkey gracefully', () async {
          await MessageSyncService.setLastInviteSyncTime(
            activePubkey: '',
            time: baseTestTime,
          );

          final retrieved = await MessageSyncService.getLastInviteSyncTime(
            activePubkey: '',
          );

          expect(retrieved, isNull);
        });

        test('different accounts have separate invite sync times', () async {
          const pubkey1 = 'pubkey1';
          const pubkey2 = 'pubkey2';
          final time1 = baseTestTime;
          final time2 = baseTestTime.add(const Duration(hours: 1));

          await MessageSyncService.setLastInviteSyncTime(
            activePubkey: pubkey1,
            time: time1,
          );

          await MessageSyncService.setLastInviteSyncTime(
            activePubkey: pubkey2,
            time: time2,
          );

          final retrieved1 = await MessageSyncService.getLastInviteSyncTime(
            activePubkey: pubkey1,
          );

          final retrieved2 = await MessageSyncService.getLastInviteSyncTime(
            activePubkey: pubkey2,
          );

          expect(retrieved1, equals(time1));
          expect(retrieved2, equals(time2));
        });
      });
    });

    group('filterNewInvites', () {
      test('returns empty list for empty currentUserPubkey', () async {
        final welcomes = [
          createTestWelcome(
            id: 'welcome1',
            mlsGroupId: 'group1',
            groupName: 'Test Group',
            welcomer: 'welcomer1',
            createdAt: BigInt.from(baseTestTime.millisecondsSinceEpoch ~/ 1000),
          ),
        ];

        final result = await MessageSyncService.filterNewInvites(
          welcomes: welcomes,
          currentUserPubkey: '', // empty
        );

        expect(result, isEmpty);
      });

      test('filters invites based on sync time', () async {
        final syncTime = baseTestTime;
        final welcomes = [
          createTestWelcome(
            id: 'old-welcome',
            mlsGroupId: 'group1',
            groupName: 'Old Group',
            welcomer: 'welcomer1',
            createdAt: BigInt.from(
              syncTime.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
          createTestWelcome(
            id: 'new-welcome',
            mlsGroupId: 'group2',
            groupName: 'New Group',
            welcomer: 'welcomer2',
            createdAt: BigInt.from(
              syncTime.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
        ];

        final result = await MessageSyncService.filterNewInvites(
          welcomes: welcomes,
          currentUserPubkey: testCurrentUserPubkey,
          lastSyncTime: syncTime,
        );

        expect(result.length, 1);
        expect(result.first.id, 'new-welcome');
      });

      test('uses default lookback window when no sync time provided', () async {
        final now = DateTime.now();
        final welcomes = [
          createTestWelcome(
            id: 'old-welcome',
            mlsGroupId: 'group1',
            groupName: 'Old Group',
            welcomer: 'welcomer1',
            createdAt: BigInt.from(
              now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
          createTestWelcome(
            id: 'recent-welcome',
            mlsGroupId: 'group2',
            groupName: 'Recent Group',
            welcomer: 'welcomer2',
            createdAt: BigInt.from(
              now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
        ];

        final result = await MessageSyncService.filterNewInvites(
          welcomes: welcomes,
          currentUserPubkey: testCurrentUserPubkey,
        );

        expect(result.length, 1);
        expect(result.first.id, 'recent-welcome');
      });

      test('sorts welcomes by creation time', () async {
        final syncTime = baseTestTime;
        final welcomes = [
          createTestWelcome(
            id: 'welcome2',
            mlsGroupId: 'group2',
            groupName: 'Second',
            welcomer: 'welcomer2',
            createdAt: BigInt.from(
              syncTime.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
          createTestWelcome(
            id: 'welcome1',
            mlsGroupId: 'group1',
            groupName: 'First',
            welcomer: 'welcomer1',
            createdAt: BigInt.from(
              syncTime.add(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
            ),
          ),
        ];

        final result = await MessageSyncService.filterNewInvites(
          welcomes: welcomes,
          currentUserPubkey: testCurrentUserPubkey,
          lastSyncTime: syncTime,
        );

        expect(result.length, 2);
        expect(result[0].id, 'welcome1'); // Should be in chronological order
        expect(result[1].id, 'welcome2');
      });
    });
    group('binary search helpers', () {
      test('_binarySearchAfter finds correct insertion point', () async {
        final now = DateTime.now();
        final baseTime = now.subtract(const Duration(seconds: 15)); // Outside buffer window
        final searchTime = baseTime.subtract(const Duration(seconds: 8)); // Between msg1 and msg2

        // Test the binary search by using it indirectly through filterNewMessages
        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'First',
            createdAt: baseTime.subtract(const Duration(seconds: 10)),
          ),
          createTestMessage(
            id: 'msg2',
            pubkey: 'other-user',
            content: 'Second',
            createdAt: baseTime.subtract(const Duration(seconds: 5)),
          ),
          createTestMessage(
            id: 'msg3',
            pubkey: 'other-user',
            content: 'Third',
            createdAt: baseTime,
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          searchTime,
        );

        expect(result.length, 2);
        expect(result[0].id, 'msg2');
        expect(result[1].id, 'msg3');
      });

      test('_binarySearchBefore works with buffer window', () async {
        final now = DateTime.now();
        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'Safe',
            createdAt: now.subtract(const Duration(seconds: 5)),
          ),
          createTestMessage(
            id: 'msg2',
            pubkey: 'other-user',
            content: 'Too recent',
            createdAt: now.subtract(const Duration(milliseconds: 500)),
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          now.subtract(const Duration(minutes: 5)),
        );

        expect(result.length, 1);
        expect(result.first.id, 'msg1'); // msg2 should be filtered out by buffer
      });
    });

    group('edge cases and error handling', () {
      test('handles empty message list', () async {
        final result = await MessageSyncService.filterNewMessages(
          [],
          testCurrentUserPubkey,
          testGroupId,
          baseTestTime,
        );

        expect(result, isEmpty);
      });

      test('handles empty welcomes list', () async {
        final result = await MessageSyncService.filterNewInvites(
          welcomes: [],
          currentUserPubkey: testCurrentUserPubkey,
          lastSyncTime: baseTestTime,
        );

        expect(result, isEmpty);
      });

      test('handles null sync times gracefully', () async {
        final messages = [
          createTestMessage(
            id: 'msg1',
            pubkey: 'other-user',
            content: 'Test',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];

        final result = await MessageSyncService.filterNewMessages(
          messages,
          testCurrentUserPubkey,
          testGroupId,
          null, // null sync time
        );

        expect(result.length, 1);
      });
    });

    group('notifyNewMessages', () {
      late List<Map<String, dynamic>> shownNotifications;

      Future<bool> mockIsChatDisplayed(String groupId) async => false;

      Future<GroupInformation> mockGetGroupInformation({
        required String accountPubkey,
        required String groupId,
      }) async {
        return GroupInformation(
          mlsGroupId: groupId,
          groupType: GroupType.directMessage,
          createdAt: baseTestTime,
          updatedAt: baseTestTime,
        );
      }

      Future<Group> mockGetGroup({
        required String accountPubkey,
        required String groupId,
      }) async {
        return Group(
          mlsGroupId: groupId,
          nostrGroupId: 'nostr-$groupId',
          name: 'Test Group',
          description: 'Test description',
          adminPubkeys: [],
          epoch: BigInt.from(1),
          state: GroupState.active,
        );
      }

      Future<List<String>> mockGetGroupMembers({
        required String pubkey,
        required String groupId,
      }) async {
        return [pubkey, 'other-user'];
      }

      Future<FlutterMetadata> mockGetUserMetadata({
        required String pubkey,
        bool blockingDataSync = false,
      }) async {
        // Return different names based on pubkey
        if (pubkey == 'other-user') {
          return const FlutterMetadata(
            name: 'Test DM User',
            displayName: 'Test DM User',
            custom: {},
          );
        }
        return const FlutterMetadata(
          name: 'Sender',
          displayName: 'Sender',
          custom: {},
        );
      }

      Future<NotificationContentBuilderService> mockNotificationBuilderFactory({
        required String groupId,
        required String accountPubkey,
        required bool isDM,
        required bool showReceiverAccountName,
      }) async {
        return NotificationContentBuilderService.forGroup(
          groupId: groupId,
          accountPubkey: accountPubkey,
          isDM: isDM,
          showReceiverAccountName: showReceiverAccountName,
          getGroupFn: mockGetGroup,
          getGroupMembersFn: mockGetGroupMembers,
          getUserMetadataFn: mockGetUserMetadata,
        );
      }

      Future<void> mockShowNotification({
        required int id,
        required String title,
        required String body,
        String? groupKey,
        String? payload,
      }) async {
        shownNotifications.add({
          'id': id,
          'title': title,
          'body': body,
          'groupKey': groupKey,
          'payload': payload,
        });
      }

      Future<int> mockGetNotificationId({required String key}) async {
        return key.hashCode.abs();
      }

      setUp(() {
        shownNotifications = [];
      });

      test('returns early when groupId is empty', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: '',
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          showNotificationFn: mockShowNotification,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications, isEmpty);
      });

      test('returns early when accountPubkey is empty', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: '',
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          showNotificationFn: mockShowNotification,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications, isEmpty);
      });

      test('skips notifications when chat is displayed', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: (groupId) async => true,
          showNotificationFn: mockShowNotification,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications, isEmpty);
      });

      test('shows notifications when chat is not displayed', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications.length, 1);
      });

      test('shows notification with correct title for DM', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications.first['title'], 'Test DM User');
      });

      test('shows notification with correct body for DM text message', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello world',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications.first['body'], 'Hello world');
      });

      test('shows notification with groupKey matching groupId', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'Hello',
              createdAt: baseTestTime,
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications.first['groupKey'], testGroupId);
      });

      test('shows multiple notifications for multiple messages', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'First',
              createdAt: baseTestTime,
            ),
            createTestMessage(
              id: 'msg2',
              pubkey: 'other-user',
              content: 'Second',
              createdAt: baseTestTime.add(const Duration(seconds: 1)),
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications.length, 2);
      });

      test('uses unique notification ID for each message', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'First',
              createdAt: baseTestTime,
            ),
            createTestMessage(
              id: 'msg2',
              pubkey: 'other-user',
              content: 'Second',
              createdAt: baseTestTime.add(const Duration(seconds: 1)),
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        final id1 = shownNotifications[0]['id'] as int;
        final id2 = shownNotifications[1]['id'] as int;
        expect(id1, isNot(equals(id2)));
      });

      test('continues showing notifications after one fails', () async {
        int callCount = 0;
        Future<void> failFirstNotification({
          required int id,
          required String title,
          required String body,
          String? groupKey,
          String? payload,
        }) async {
          callCount++;
          if (callCount == 1) {
            throw Exception('First notification failed');
          }
          shownNotifications.add({
            'id': id,
            'title': title,
            'body': body,
            'groupKey': groupKey,
            'payload': payload,
          });
        }

        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [
            createTestMessage(
              id: 'msg1',
              pubkey: 'other-user',
              content: 'First',
              createdAt: baseTestTime,
            ),
            createTestMessage(
              id: 'msg2',
              pubkey: 'other-user',
              content: 'Second',
              createdAt: baseTestTime.add(const Duration(seconds: 1)),
            ),
          ],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: failFirstNotification,
          getNotificationIdFn: mockGetNotificationId,
        );

        expect(shownNotifications.length, 1);
      });

      test('handles empty messages list', () async {
        await MessageSyncService.notifyNewMessages(
          groupId: testGroupId,
          accountPubkey: testActivePubkey,
          newMessages: [],
          showReceiverAccountName: false,
          isChatDisplayedFn: mockIsChatDisplayed,
          getGroupInformationFn: mockGetGroupInformation,
          notificationBuilderFactoryFn: mockNotificationBuilderFactory,
          showNotificationFn: mockShowNotification,
          getNotificationIdFn: mockGetNotificationId,
          getUserMetadataFn: mockGetUserMetadata,
        );

        expect(shownNotifications, isEmpty);
      });

      group('for group chats', () {
        Future<GroupInformation> mockGetGroupChatInformation({
          required String accountPubkey,
          required String groupId,
        }) async {
          return GroupInformation(
            mlsGroupId: groupId,
            groupType: GroupType.group,
            createdAt: baseTestTime,
            updatedAt: baseTestTime,
          );
        }

        Future<Group> mockGetGroupChat({
          required String accountPubkey,
          required String groupId,
        }) async {
          return Group(
            mlsGroupId: groupId,
            nostrGroupId: 'nostr-$groupId',
            name: 'Test Group',
            description: 'Test description',
            adminPubkeys: [],
            epoch: BigInt.from(1),
            state: GroupState.active,
          );
        }

        Future<List<String>> mockGetGroupChatMembers({
          required String pubkey,
          required String groupId,
        }) async {
          return [pubkey, 'other-user'];
        }

        Future<FlutterMetadata> mockGetGroupUserMetadata({
          required String pubkey,
          bool blockingDataSync = false,
        }) async {
          // Return different names based on pubkey
          if (pubkey == 'other-user') {
            return const FlutterMetadata(
              name: 'Sender',
              displayName: 'Sender',
              custom: {},
            );
          }
          return const FlutterMetadata(
            name: 'Test User',
            displayName: 'Test User',
            custom: {},
          );
        }

        Future<NotificationContentBuilderService> mockGroupBuilderFactory({
          required String groupId,
          required String accountPubkey,
          required bool isDM,
          required bool showReceiverAccountName,
        }) async {
          return NotificationContentBuilderService.forGroup(
            groupId: groupId,
            accountPubkey: accountPubkey,
            isDM: isDM,
            showReceiverAccountName: showReceiverAccountName,
            getGroupFn: mockGetGroupChat,
            getGroupMembersFn: mockGetGroupChatMembers,
            getUserMetadataFn: mockGetGroupUserMetadata,
          );
        }

        test('shows notification with correct title', () async {
          await MessageSyncService.notifyNewMessages(
            groupId: testGroupId,
            accountPubkey: testActivePubkey,
            newMessages: [
              createTestMessage(
                id: 'msg1',
                pubkey: 'other-user',
                content: 'Hello group',
                createdAt: baseTestTime,
              ),
            ],
            showReceiverAccountName: false,
            isChatDisplayedFn: mockIsChatDisplayed,
            getGroupInformationFn: mockGetGroupChatInformation,
            notificationBuilderFactoryFn: mockGroupBuilderFactory,
            showNotificationFn: mockShowNotification,
            getNotificationIdFn: mockGetNotificationId,
            getUserMetadataFn: mockGetGroupUserMetadata,
          );

          expect(shownNotifications.first['title'], 'Test Group');
        });

        test('shows notification with sender name in body', () async {
          await MessageSyncService.notifyNewMessages(
            groupId: testGroupId,
            accountPubkey: testActivePubkey,
            newMessages: [
              createTestMessage(
                id: 'msg1',
                pubkey: 'other-user',
                content: 'Hello group',
                createdAt: baseTestTime,
              ),
            ],
            showReceiverAccountName: false,
            isChatDisplayedFn: mockIsChatDisplayed,
            getGroupInformationFn: mockGetGroupChatInformation,
            notificationBuilderFactoryFn: mockGroupBuilderFactory,
            showNotificationFn: mockShowNotification,
            getNotificationIdFn: mockGetNotificationId,
            getUserMetadataFn: mockGetGroupUserMetadata,
          );

          expect(shownNotifications.first['body'], 'Sender: Hello group');
        });
      });
    });
  });
}
