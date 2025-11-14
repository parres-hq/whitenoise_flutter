import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_messages_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' show User;
import 'package:whitenoise/domain/services/last_read_service.dart';
import 'package:whitenoise/domain/services/message_sender_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/src/rust/api/messages.dart' show MessageWithTokens;

import '../../shared/mocks/mock_active_pubkey_notifier.dart';
import '../../shared/mocks/mock_auth_notifier.dart';

class MockMessageSenderService implements MessageSenderService {
  MessageWithTokens? messageToReturn;
  Exception? errorToThrow;
  int sendCallCount = 0;

  MockMessageSenderService({
    this.messageToReturn,
    this.errorToThrow,
  });

  @override
  Future<MessageWithTokens> sendMessage({
    required String pubkey,
    required String groupId,
    required String content,
    required List<MediaFile> mediaFiles,
  }) async {
    sendCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return messageToReturn!;
  }

  @override
  Future<MessageWithTokens> sendReply({
    required String pubkey,
    required String groupId,
    required String replyToMessageId,
    required String content,
    required List<MediaFile> mediaFiles,
  }) async {
    sendCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return messageToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGroupMessagesNotifier extends GroupMessagesNotifier {
  List<MessageModel> messagesToReturn;
  final Exception? errorToThrow;
  int fetchCallCount = 0;

  MockGroupMessagesNotifier({
    required this.messagesToReturn,
    this.errorToThrow,
  });

  @override
  Future<List<MessageModel>> fetchMessages() async {
    fetchCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return List<MessageModel>.from(messagesToReturn);
  }
}

MessageModel createTestMessage({
  required String id,
  required String content,
  required String senderPubkey,
  required DateTime createdAt,
  String? groupId,
  MessageStatus status = MessageStatus.sent,
  MessageModel? replyTo,
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    createdAt: createdAt,
    sender: User(
      id: senderPubkey,
      publicKey: senderPubkey,
      displayName: 'Test User',
      nip05: '',
    ),
    isMe: false,
    groupId: groupId,
    status: status,
    replyTo: replyTo,
  );
}

MessageWithTokens createTestMessageWithTokens({
  required String id,
  required String pubkey,
  int kind = 443,
  DateTime? createdAt,
  String? content,
}) {
  return MessageWithTokens(
    id: id,
    pubkey: pubkey,
    kind: kind,
    createdAt: createdAt ?? DateTime.now(),
    content: content,
    tokens: [],
  );
}

MediaFile createTestMediaFile({
  required String id,
  required String groupId,
  required String pubkey,
  String filePath = '/path/to/test.jpg',
}) {
  return MediaFile(
    id: id,
    mlsGroupId: groupId,
    accountPubkey: pubkey,
    filePath: filePath,
    encryptedFileHash: 'hash123',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://example.com/media',
    nostrKey: 'key123',
    createdAt: DateTime.now(),
  );
}

void main() {
  group('ChatProvider Tests', () {
    group('loadMessagesForGroup', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      late ProviderContainer container;
      const testGroupId = 'test-group-123';
      const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
      final dbMessages = [
        createTestMessage(
          id: 'msg-1',
          content: 'Hello',
          senderPubkey: testPubkey,
          createdAt: DateTime(2025, 1, 1, 10),
          groupId: testGroupId,
        ),
        createTestMessage(
          id: 'msg-2',
          content: 'World',
          senderPubkey: testPubkey,
          createdAt: DateTime(2025, 1, 1, 10, 1),
          groupId: testGroupId,
        ),
      ];

      group('when not authenticated', () {
        late MockGroupMessagesNotifier mockGroupMessagesNotifier;

        setUp(() {
          mockGroupMessagesNotifier = MockGroupMessagesNotifier(
            messagesToReturn: dbMessages,
          );

          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: false),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(testPubkey),
              ),
              groupMessagesProvider.overrideWith(
                () => mockGroupMessagesNotifier,
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('does not fetch messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          expect(mockGroupMessagesNotifier.fetchCallCount, 0);
        });

        test('does not set loading state to true', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.isGroupLoading(testGroupId), false);
        });

        test('does not update group messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is null', () {
        late MockGroupMessagesNotifier mockGroupMessagesNotifier;

        setUp(() {
          mockGroupMessagesNotifier = MockGroupMessagesNotifier(
            messagesToReturn: dbMessages,
          );

          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(null),
              ),
              groupMessagesProvider.overrideWith(
                () => mockGroupMessagesNotifier,
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('does not fetch messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          expect(mockGroupMessagesNotifier.fetchCallCount, 0);
        });

        test('does not set loading state to true', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.isGroupLoading(testGroupId), false);
        });

        test('does not update group messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is empty', () {
        late MockGroupMessagesNotifier mockGroupMessagesNotifier;

        setUp(() {
          mockGroupMessagesNotifier = MockGroupMessagesNotifier(
            messagesToReturn: dbMessages,
          );

          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(''),
              ),
              groupMessagesProvider.overrideWith(
                () => mockGroupMessagesNotifier,
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('does not fetch messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          expect(mockGroupMessagesNotifier.fetchCallCount, 0);
        });

        test('does not set loading state to true', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.isGroupLoading(testGroupId), false);
        });

        test('does not update group messages', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.loadMessagesForGroup(testGroupId);

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('with valid authentication', () {
        group('without messages in state', () {
          late MockGroupMessagesNotifier mockGroupMessagesNotifier;
          final testMessages = [
            createTestMessage(
              id: 'msg-1',
              content: 'Hello',
              senderPubkey: testPubkey,
              createdAt: DateTime(2025, 1, 1, 10),
              groupId: testGroupId,
            ),
            createTestMessage(
              id: 'msg-2',
              content: 'World',
              senderPubkey: testPubkey,
              createdAt: DateTime(2025, 1, 1, 10, 1),
              groupId: testGroupId,
            ),
          ];

          setUp(() {
            mockGroupMessagesNotifier = MockGroupMessagesNotifier(
              messagesToReturn: testMessages,
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                groupMessagesProvider.overrideWith(
                  () => mockGroupMessagesNotifier,
                ),
              ],
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('starts and ends loading', () async {
            final notifier = container.read(chatProvider.notifier);

            final loadMessagesForGroupFuture = notifier.loadMessagesForGroup(testGroupId);
            expect(container.read(chatProvider).isGroupLoading(testGroupId), true);
            await loadMessagesForGroupFuture;
            final state = container.read(chatProvider);
            expect(state.isGroupLoading(testGroupId), false);
          });

          test('fetches messages', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            expect(mockGroupMessagesNotifier.fetchCallCount, 1);
          });

          test('adds messages to state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages, isNotEmpty);
            expect(messages.length, 2);
            expect(messages[0].id, 'msg-1');
            expect(messages[1].id, 'msg-2');
          });
        });

        group('with messages in state', () {
          late MockGroupMessagesNotifier mockGroupMessagesNotifier;
          final existingMessage = createTestMessage(
            id: 'msg-A',
            content: 'Existing',
            senderPubkey: testPubkey,
            createdAt: DateTime(2025, 1, 1, 9, 1),
            groupId: testGroupId,
          );

          final newMessages = [
            createTestMessage(
              id: 'msg-B',
              content: 'Hello',
              senderPubkey: testPubkey,
              createdAt: DateTime(2025, 1, 1, 10),
              groupId: testGroupId,
            ),
            createTestMessage(
              id: 'msg-C',
              content: 'World',
              senderPubkey: testPubkey,
              createdAt: DateTime(2025, 1, 1, 10, 1),
              groupId: testGroupId,
            ),
          ];

          setUp(() {
            mockGroupMessagesNotifier = MockGroupMessagesNotifier(
              messagesToReturn: [existingMessage, ...newMessages],
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                groupMessagesProvider.overrideWith(
                  () => mockGroupMessagesNotifier,
                ),
              ],
            );

            final notifier = container.read(chatProvider.notifier);
            container.read(chatProvider.notifier).state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [existingMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('adds new messages to state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 3);
            expect(messages[0].id, 'msg-A');
            expect(messages[1].id, 'msg-B');
            expect(messages[2].id, 'msg-C');
          });
        });

        group('with sending messages in state', () {
          late MockGroupMessagesNotifier mockGroupMessagesNotifier;
          final oldSendingMessage = createTestMessage(
            id: 'msg-0',
            content: 'Old sending...',
            senderPubkey: testPubkey,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            groupId: testGroupId,
            status: MessageStatus.sending,
          );
          final recentSendingMessage = createTestMessage(
            id: 'msg-1',
            content: 'Sending...',
            senderPubkey: testPubkey,
            createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
            groupId: testGroupId,
            status: MessageStatus.sending,
          );

          final otherRecentSendingMessage = createTestMessage(
            id: 'msg-2',
            content: 'Sending other...',
            senderPubkey: testPubkey,
            createdAt: DateTime.now().subtract(const Duration(seconds: 20)),
            groupId: testGroupId,
            status: MessageStatus.sending,
          );

          final sentMessage = createTestMessage(
            id: 'msg-1',
            content: 'Content saved in db',
            senderPubkey: testPubkey,
            createdAt: DateTime.now().subtract(const Duration(seconds: 15)),
            groupId: testGroupId,
          );

          final dbMessages = [sentMessage];

          setUp(() {
            mockGroupMessagesNotifier = MockGroupMessagesNotifier(
              messagesToReturn: dbMessages,
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                groupMessagesProvider.overrideWith(
                  () => mockGroupMessagesNotifier,
                ),
              ],
            );

            // Add sending messages to state
            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [oldSendingMessage, recentSendingMessage, otherRecentSendingMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('removes duplicates', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 3);
            expect(messages[0].id, 'msg-1');
            expect(messages[1].id, 'msg-0');
            expect(messages[2].id, 'msg-2');
          });

          test('keeps db content for duplicates', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            final duplicatedMessage = messages.firstWhere(
              (m) => m.id == 'msg-1',
            );
            expect(duplicatedMessage.content, 'Content saved in db');
          });

          test('marks old sending messages as failed', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            final failedMessage = messages.firstWhere(
              (m) => m.id == 'msg-0',
            );
            expect(failedMessage.status, MessageStatus.failed);
          });

          test('merges correctly with db messages', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 3);
            expect(messages[0].id, 'msg-1');
            expect(messages[1].id, 'msg-0');
            expect(messages[2].id, 'msg-2');
          });
        });

        group('when fetchmessages returns empty list', () {
          late MockGroupMessagesNotifier mockGroupMessagesNotifier;

          setUp(() {
            mockGroupMessagesNotifier = MockGroupMessagesNotifier(
              messagesToReturn: [],
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                groupMessagesProvider.overrideWith(
                  () => mockGroupMessagesNotifier,
                ),
              ],
            );

            // Add sent message to state
            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [
                  createTestMessage(
                    id: 'msg-2',
                    content: 'World',
                    senderPubkey: testPubkey,
                    createdAt: DateTime(2025, 1, 1, 10, 1),
                    groupId: testGroupId,
                  ),
                ],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('clear sent message from state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages, isEmpty);
          });

          test('starts and stops loading', () async {
            final notifier = container.read(chatProvider.notifier);
            final loadMessagesForGroupFuture = notifier.loadMessagesForGroup(testGroupId);
            expect(container.read(chatProvider).isGroupLoading(testGroupId), true);
            await loadMessagesForGroupFuture;

            final state = container.read(chatProvider);
            expect(state.isGroupLoading(testGroupId), false);
          });
        });

        group('when fetch messages throws error', () {
          late MockGroupMessagesNotifier mockGroupMessagesNotifier;
          final sentMessage = createTestMessage(
            id: 'msg-2',
            content: 'World',
            senderPubkey: testPubkey,
            createdAt: DateTime(2025, 1, 1, 10, 1),
            groupId: testGroupId,
          );

          setUp(() {
            mockGroupMessagesNotifier = MockGroupMessagesNotifier(
              messagesToReturn: [],
              errorToThrow: Exception('Database error'),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                groupMessagesProvider.overrideWith(
                  () => mockGroupMessagesNotifier,
                ),
              ],
            );

            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [sentMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('starts and stops loading', () async {
            final notifier = container.read(chatProvider.notifier);
            final loadMessagesForGroupFuture = notifier.loadMessagesForGroup(testGroupId);
            expect(container.read(chatProvider).isGroupLoading(testGroupId), true);
            await loadMessagesForGroupFuture;

            final state = container.read(chatProvider);
            expect(state.isGroupLoading(testGroupId), false);
          });

          test('does not update group messages', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.loadMessagesForGroup(testGroupId);

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 1);
          });
        });
      });
    });

    group('sendMessage', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      late ProviderContainer container;
      const testGroupId = 'test-group-123';
      const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
      const testMessage = 'Hello World';

      group('when not authenticated', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: false),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(testPubkey),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is null', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(null),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is empty', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(''),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendMessage(
            groupId: testGroupId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('with valid authentication', () {
        group('when state is empty', () {
          late MockMessageSenderService mockMessageSenderService;

          setUp(() {
            mockMessageSenderService = MockMessageSenderService(
              messageToReturn: createTestMessageWithTokens(
                id: 'msg-new',
                pubkey: testPubkey,
                content: testMessage,
              ),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                chatProvider.overrideWith(
                  () => ChatNotifier(messageSenderService: mockMessageSenderService),
                ),
              ],
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('adds optimistic message to state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendMessage(
              groupId: testGroupId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 1);
            expect(messages[0].id, 'msg-new');
          });
        });

        group('when state has existing messages', () {
          late MockMessageSenderService mockMessageSenderService;
          final existingMessage = createTestMessage(
            id: 'msg-1',
            content: 'Existing message',
            senderPubkey: testPubkey,
            createdAt: DateTime(2025, 1, 1, 10),
            groupId: testGroupId,
          );

          setUp(() {
            mockMessageSenderService = MockMessageSenderService(
              messageToReturn: createTestMessageWithTokens(
                id: 'msg-new',
                pubkey: testPubkey,
                content: testMessage,
              ),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                chatProvider.overrideWith(
                  () => ChatNotifier(messageSenderService: mockMessageSenderService),
                ),
              ],
            );

            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [existingMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('adds optimistic message to state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendMessage(
              groupId: testGroupId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 2);
          });

          test('keeps existing messages', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendMessage(
              groupId: testGroupId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[0].id, 'msg-1');
          });

          test('appends new message at end', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendMessage(
              groupId: testGroupId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[1].id, 'msg-new');
          });
        });

        group('with media files', () {
          late MockMessageSenderService mockMessageSenderService;
          late MediaFile testMediaFile;

          setUp(() {
            testMediaFile = createTestMediaFile(
              id: 'media-1',
              groupId: testGroupId,
              pubkey: testPubkey,
            );

            mockMessageSenderService = MockMessageSenderService(
              messageToReturn: createTestMessageWithTokens(
                id: 'msg-with-media',
                pubkey: testPubkey,
                content: testMessage,
              ),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                chatProvider.overrideWith(
                  () => ChatNotifier(messageSenderService: mockMessageSenderService),
                ),
              ],
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('optimistic message includes media files', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendMessage(
              groupId: testGroupId,
              message: testMessage,
              mediaFiles: [testMediaFile],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[0].mediaAttachments.length, 1);
            expect(messages[0].mediaAttachments[0].id, 'media-1');
          });
        });
      });
    });

    group('sendReplyMessage', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      late ProviderContainer container;
      const testGroupId = 'test-group-123';
      const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
      const testMessage = 'Reply message';
      const replyToMessageId = 'msg-original';

      group('when not authenticated', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: false),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(testPubkey),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is null', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(null),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('when active pubkey is empty', () {
        setUp(() {
          container = ProviderContainer(
            overrides: [
              authProvider.overrideWith(
                () => MockAuthNotifier(isAuthenticated: true),
              ),
              activePubkeyProvider.overrideWith(
                () => MockActivePubkeyNotifier(''),
              ),
            ],
          );
        });

        tearDown(() {
          container.dispose();
        });

        test('returns null', () async {
          final notifier = container.read(chatProvider.notifier);
          final result = await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          expect(result, isNull);
        });

        test('does not set sending state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.isSendingToGroup(testGroupId), false);
        });

        test('does not add message to state', () async {
          final notifier = container.read(chatProvider.notifier);
          await notifier.sendReplyMessage(
            groupId: testGroupId,
            replyToMessageId: replyToMessageId,
            message: testMessage,
            mediaFiles: [],
          );

          final state = container.read(chatProvider);
          expect(state.getMessagesForGroup(testGroupId), isEmpty);
        });
      });

      group('with valid authentication', () {
        group('with original message in state', () {
          late MockMessageSenderService mockMessageSenderService;
          final originalMessage = createTestMessage(
            id: replyToMessageId,
            content: 'Original message',
            senderPubkey: testPubkey,
            createdAt: DateTime(2025, 1, 1, 10),
            groupId: testGroupId,
          );

          setUp(() {
            mockMessageSenderService = MockMessageSenderService(
              messageToReturn: createTestMessageWithTokens(
                id: 'msg-reply',
                pubkey: testPubkey,
                content: testMessage,
              ),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                chatProvider.overrideWith(
                  () => ChatNotifier(messageSenderService: mockMessageSenderService),
                ),
              ],
            );

            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [originalMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('adds optimistic reply message to state', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendReplyMessage(
              groupId: testGroupId,
              replyToMessageId: replyToMessageId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages.length, 2);
          });

          test('keeps original message', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendReplyMessage(
              groupId: testGroupId,
              replyToMessageId: replyToMessageId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[0].id, replyToMessageId);
          });

          test('appends reply message at end', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendReplyMessage(
              groupId: testGroupId,
              replyToMessageId: replyToMessageId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[1].id, 'msg-reply');
          });

          test('reply message references original', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendReplyMessage(
              groupId: testGroupId,
              replyToMessageId: replyToMessageId,
              message: testMessage,
              mediaFiles: [],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[1].replyTo?.id, replyToMessageId);
          });
        });

        group('with media files', () {
          late MockMessageSenderService mockMessageSenderService;
          late MediaFile testMediaFile;
          final originalMessage = createTestMessage(
            id: replyToMessageId,
            content: 'Original message',
            senderPubkey: testPubkey,
            createdAt: DateTime(2025, 1, 1, 10),
            groupId: testGroupId,
          );

          setUp(() {
            testMediaFile = createTestMediaFile(
              id: 'media-1',
              groupId: testGroupId,
              pubkey: testPubkey,
            );

            mockMessageSenderService = MockMessageSenderService(
              messageToReturn: createTestMessageWithTokens(
                id: 'msg-reply-with-media',
                pubkey: testPubkey,
                content: testMessage,
              ),
            );

            container = ProviderContainer(
              overrides: [
                authProvider.overrideWith(
                  () => MockAuthNotifier(isAuthenticated: true),
                ),
                activePubkeyProvider.overrideWith(
                  () => MockActivePubkeyNotifier(testPubkey),
                ),
                chatProvider.overrideWith(
                  () => ChatNotifier(messageSenderService: mockMessageSenderService),
                ),
              ],
            );

            final notifier = container.read(chatProvider.notifier);
            notifier.state = notifier.state.copyWith(
              groupMessages: {
                testGroupId: [originalMessage],
              },
            );
          });

          tearDown(() {
            container.dispose();
          });

          test('optimistic reply message includes media files', () async {
            final notifier = container.read(chatProvider.notifier);
            await notifier.sendReplyMessage(
              groupId: testGroupId,
              replyToMessageId: replyToMessageId,
              message: testMessage,
              mediaFiles: [testMediaFile],
            );

            final state = container.read(chatProvider);
            final messages = state.getMessagesForGroup(testGroupId);
            expect(messages[1].mediaAttachments.length, 1);
            expect(messages[1].mediaAttachments[0].id, 'media-1');
          });
        });
      });
    });

    group('refreshUnreadCount', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      late ProviderContainer container;
      late SharedPreferences prefs;
      const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';

      setUpAll(() async {
        // Initialize SharedPreferences ONCE for all tests
        // This is important because LastReadService caches the Future<SharedPreferences>
        // Reset the mock to ensure clean state
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });

      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
        container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(isAuthenticated: true)),
            activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testPubkey)),
          ],
        );
      });

      tearDown(() async {
        container.dispose();
        // Clear all last_read keys after each test
        final keys = prefs.getKeys().where((k) => k.startsWith('last_read_')).toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      });

      group('when lastRead is null', () {
        test('counts all messages from others', () async {
          final notifier = container.read(chatProvider.notifier);
          const groupId = 'group-unread-1';
          final now = DateTime(2025, 1, 1, 12);

          final other1 = createTestMessage(
            id: 'm1',
            content: 'Hello',
            senderPubkey: 'other_pubkey',
            createdAt: now.subtract(const Duration(minutes: 5)),
            groupId: groupId,
          );
          final other2 = createTestMessage(
            id: 'm2',
            content: 'World',
            senderPubkey: 'other_pubkey',
            createdAt: now.subtract(const Duration(minutes: 1)),
            groupId: groupId,
          );
          final myMsg = MessageModel(
            id: 'm3',
            content: 'My message',
            type: MessageType.text,
            createdAt: now,
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [other1, other2, myMsg],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 2);
        });

        test('excludes self messages', () async {
          final notifier = container.read(chatProvider.notifier);
          const groupId = 'group-unread-2';
          final now = DateTime(2025, 1, 2, 9);

          final selfMsg1 = MessageModel(
            id: 's1',
            content: 'My message 1',
            type: MessageType.text,
            createdAt: now.subtract(const Duration(minutes: 2)),
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );
          final otherMsg = createTestMessage(
            id: 'o1',
            content: 'Other message',
            senderPubkey: 'other_pubkey',
            createdAt: now.subtract(const Duration(minutes: 1)),
            groupId: groupId,
          );
          final selfMsg2 = MessageModel(
            id: 's2',
            content: 'My message 2',
            type: MessageType.text,
            createdAt: now,
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [selfMsg1, otherMsg, selfMsg2],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 1);
        });

        test('returns 0 for empty message list', () async {
          final notifier = container.read(chatProvider.notifier);
          const groupId = 'group-empty';

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);
        });

        test('returns 0 when all messages are from self', () async {
          final notifier = container.read(chatProvider.notifier);
          const groupId = 'group-self-only';
          final now = DateTime(2025, 1, 3, 10);

          final selfMsg1 = MessageModel(
            id: 's1',
            content: 'My message 1',
            type: MessageType.text,
            createdAt: now.subtract(const Duration(minutes: 1)),
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );
          final selfMsg2 = MessageModel(
            id: 's2',
            content: 'My message 2',
            type: MessageType.text,
            createdAt: now,
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [selfMsg1, selfMsg2],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);
        });
      });

      group('when lastRead is set', () {
        test('counts only messages after lastRead timestamp', () async {
          const groupId = 'group-with-lastread';
          final lastReadTime = DateTime(2025, 1, 4, 12);

          // Set lastRead BEFORE reading the provider to ensure it's available
          await LastReadService.setLastRead(
            groupId: groupId,
            activePubkey: testPubkey,
            timestamp: lastReadTime,
          );

          final notifier = container.read(chatProvider.notifier);

          final beforeLastRead = createTestMessage(
            id: 'm1',
            content: 'Before',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.subtract(const Duration(minutes: 5)),
            groupId: groupId,
          );
          final atLastRead = createTestMessage(
            id: 'm2',
            content: 'At',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime,
            groupId: groupId,
          );
          final afterLastRead1 = createTestMessage(
            id: 'm3',
            content: 'After 1',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.add(const Duration(minutes: 1)),
            groupId: groupId,
          );
          final afterLastRead2 = createTestMessage(
            id: 'm4',
            content: 'After 2',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.add(const Duration(minutes: 2)),
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [beforeLastRead, atLastRead, afterLastRead1, afterLastRead2],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 2);
        });

        test('excludes messages at exact lastRead timestamp', () async {
          const groupId = 'group-boundary';
          final lastReadTime = DateTime(2025, 1, 5, 10, 30);

          await LastReadService.setLastRead(
            groupId: groupId,
            activePubkey: testPubkey,
            timestamp: lastReadTime,
          );

          final notifier = container.read(chatProvider.notifier);

          final atExactTime = createTestMessage(
            id: 'm1',
            content: 'Exact',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime,
            groupId: groupId,
          );
          final afterTime = createTestMessage(
            id: 'm2',
            content: 'After',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.add(const Duration(milliseconds: 1)),
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [atExactTime, afterTime],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 1);
        });

        test('excludes self messages after lastRead', () async {
          const groupId = 'group-self-after';
          final lastReadTime = DateTime(2025, 1, 6, 14);

          await LastReadService.setLastRead(
            groupId: groupId,
            activePubkey: testPubkey,
            timestamp: lastReadTime,
          );

          final notifier = container.read(chatProvider.notifier);

          final otherMsg = createTestMessage(
            id: 'o1',
            content: 'Other',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.add(const Duration(minutes: 1)),
            groupId: groupId,
          );
          final selfMsg = MessageModel(
            id: 's1',
            content: 'Self',
            type: MessageType.text,
            createdAt: lastReadTime.add(const Duration(minutes: 2)),
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [otherMsg, selfMsg],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 1);
        });

        test('returns 0 when all messages are before lastRead', () async {
          const groupId = 'group-all-before';
          final lastReadTime = DateTime(2025, 1, 7, 16);

          await LastReadService.setLastRead(
            groupId: groupId,
            activePubkey: testPubkey,
            timestamp: lastReadTime,
          );

          final notifier = container.read(chatProvider.notifier);

          final oldMsg1 = createTestMessage(
            id: 'm1',
            content: 'Old 1',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.subtract(const Duration(minutes: 10)),
            groupId: groupId,
          );
          final oldMsg2 = createTestMessage(
            id: 'm2',
            content: 'Old 2',
            senderPubkey: 'other_pubkey',
            createdAt: lastReadTime.subtract(const Duration(minutes: 5)),
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [oldMsg1, oldMsg2],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);
        });
      });

      group('edge cases', () {
        test('returns early when activePubkey is empty', () async {
          final emptyPubkeyContainer = ProviderContainer(
            overrides: [
              authProvider.overrideWith(() => MockAuthNotifier(isAuthenticated: true)),
              activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier('')),
            ],
          );

          final notifier = emptyPubkeyContainer.read(chatProvider.notifier);
          const groupId = 'group-empty-pubkey';

          final msg = createTestMessage(
            id: 'm1',
            content: 'Message',
            senderPubkey: 'other_pubkey',
            createdAt: DateTime.now(),
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [msg],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = emptyPubkeyContainer.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);

          emptyPubkeyContainer.dispose();
        });

        test('returns early when activePubkey is null', () async {
          final nullPubkeyContainer = ProviderContainer(
            overrides: [
              authProvider.overrideWith(() => MockAuthNotifier(isAuthenticated: true)),
              activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(null)),
            ],
          );

          final notifier = nullPubkeyContainer.read(chatProvider.notifier);
          const groupId = 'group-null-pubkey';

          final msg = createTestMessage(
            id: 'm1',
            content: 'Message',
            senderPubkey: 'other_pubkey',
            createdAt: DateTime.now(),
            groupId: groupId,
          );

          notifier.state = notifier.state.copyWith(
            groupMessages: {
              groupId: [msg],
            },
          );

          await notifier.refreshUnreadCount(groupId);
          final count = nullPubkeyContainer.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);

          nullPubkeyContainer.dispose();
        });

        test('handles group not in state', () async {
          final notifier = container.read(chatProvider.notifier);
          const groupId = 'non-existent-group';

          await notifier.refreshUnreadCount(groupId);
          final count = container.read(chatProvider).getUnreadCountForGroup(groupId);
          expect(count, 0);
        });
      });
    });

    group('refreshAllUnreadCounts', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      late ProviderContainer container;
      late SharedPreferences prefs;
      const testPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';

      setUpAll(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
      });

      setUp(() {
        TestWidgetsFlutterBinding.ensureInitialized();
        container = ProviderContainer(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(isAuthenticated: true)),
            activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testPubkey)),
          ],
        );
      });

      tearDown(() async {
        container.dispose();
        final keys = prefs.getKeys().where((k) => k.startsWith('last_read_')).toList();
        for (final key in keys) {
          await prefs.remove(key);
        }
      });

      test('refreshes unread counts for all groups', () async {
        final notifier = container.read(chatProvider.notifier);
        const g1 = 'group-1';
        const g2 = 'group-2';
        const g3 = 'group-3';
        final now = DateTime(2025, 1, 8, 12);

        final group1Messages = [
          createTestMessage(
            id: 'g1-1',
            content: 'Message 1',
            senderPubkey: 'other_pubkey',
            createdAt: now.subtract(const Duration(minutes: 10)),
            groupId: g1,
          ),
          createTestMessage(
            id: 'g1-2',
            content: 'Message 2',
            senderPubkey: 'other_pubkey',
            createdAt: now.add(const Duration(minutes: 2)),
            groupId: g1,
          ),
        ];

        final group2Messages = [
          createTestMessage(
            id: 'g2-1',
            content: 'Message 1',
            senderPubkey: 'other_pubkey',
            createdAt: now.subtract(const Duration(minutes: 3)),
            groupId: g2,
          ),
          MessageModel(
            id: 'g2-self',
            content: 'Self message',
            type: MessageType.text,
            createdAt: now.add(const Duration(minutes: 5)),
            sender: User(id: testPubkey, publicKey: testPubkey, displayName: 'Me', nip05: ''),
            isMe: true,
            groupId: g2,
          ),
        ];

        final group3Messages = [
          createTestMessage(
            id: 'g3-1',
            content: 'Message 1',
            senderPubkey: 'other_pubkey',
            createdAt: now,
            groupId: g3,
          ),
          createTestMessage(
            id: 'g3-2',
            content: 'Message 2',
            senderPubkey: 'other_pubkey',
            createdAt: now.add(const Duration(minutes: 1)),
            groupId: g3,
          ),
          createTestMessage(
            id: 'g3-3',
            content: 'Message 3',
            senderPubkey: 'other_pubkey',
            createdAt: now.add(const Duration(minutes: 2)),
            groupId: g3,
          ),
        ];

        notifier.state = notifier.state.copyWith(
          groupMessages: {
            g1: group1Messages,
            g2: group2Messages,
            g3: group3Messages,
          },
        );

        await notifier.refreshAllUnreadCounts();
        final state = container.read(chatProvider);
        expect(state.getUnreadCountForGroup(g1), 2);
        expect(state.getUnreadCountForGroup(g2), 1);
        expect(state.getUnreadCountForGroup(g3), 3);
      });

      test('refreshes with different lastRead timestamps per group', () async {
        const g1 = 'group-1';
        const g2 = 'group-2';
        final now = DateTime(2025, 1, 9, 10);
        final g1LastRead = now.subtract(const Duration(minutes: 5));
        final g2LastRead = now.subtract(const Duration(minutes: 2));

        await LastReadService.setLastRead(
          groupId: g1,
          activePubkey: testPubkey,
          timestamp: g1LastRead,
        );
        await LastReadService.setLastRead(
          groupId: g2,
          activePubkey: testPubkey,
          timestamp: g2LastRead,
        );

        final notifier = container.read(chatProvider.notifier);

        final group1Messages = [
          createTestMessage(
            id: 'g1-1',
            content: 'Before',
            senderPubkey: 'other_pubkey',
            createdAt: g1LastRead.subtract(const Duration(minutes: 1)),
            groupId: g1,
          ),
          createTestMessage(
            id: 'g1-2',
            content: 'After',
            senderPubkey: 'other_pubkey',
            createdAt: g1LastRead.add(const Duration(minutes: 1)),
            groupId: g1,
          ),
        ];

        final group2Messages = [
          createTestMessage(
            id: 'g2-1',
            content: 'Before',
            senderPubkey: 'other_pubkey',
            createdAt: g2LastRead.subtract(const Duration(minutes: 1)),
            groupId: g2,
          ),
          createTestMessage(
            id: 'g2-2',
            content: 'After 1',
            senderPubkey: 'other_pubkey',
            createdAt: g2LastRead.add(const Duration(minutes: 1)),
            groupId: g2,
          ),
          createTestMessage(
            id: 'g2-3',
            content: 'After 2',
            senderPubkey: 'other_pubkey',
            createdAt: g2LastRead.add(const Duration(minutes: 2)),
            groupId: g2,
          ),
        ];

        notifier.state = notifier.state.copyWith(
          groupMessages: {
            g1: group1Messages,
            g2: group2Messages,
          },
        );

        await notifier.refreshAllUnreadCounts();
        final state = container.read(chatProvider);
        expect(state.getUnreadCountForGroup(g1), 1);
        expect(state.getUnreadCountForGroup(g2), 2);
      });

      test('handles empty groups list', () async {
        final notifier = container.read(chatProvider.notifier);

        notifier.state = notifier.state.copyWith(
          groupMessages: {},
        );

        await notifier.refreshAllUnreadCounts();
        final state = container.read(chatProvider);
        expect(state.unreadCounts, isEmpty);
      });

      test('handles mix of groups with and without messages', () async {
        final notifier = container.read(chatProvider.notifier);
        const g1 = 'group-with-messages';
        const g2 = 'group-empty';
        final now = DateTime(2025, 1, 10, 15);

        final group1Messages = [
          createTestMessage(
            id: 'g1-1',
            content: 'Message',
            senderPubkey: 'other_pubkey',
            createdAt: now,
            groupId: g1,
          ),
        ];

        notifier.state = notifier.state.copyWith(
          groupMessages: {
            g1: group1Messages,
            g2: [],
          },
        );

        await notifier.refreshAllUnreadCounts();
        final state = container.read(chatProvider);
        expect(state.getUnreadCountForGroup(g1), 1);
        expect(state.getUnreadCountForGroup(g2), 0);
      });
    });
  });
}
