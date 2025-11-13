import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_messages_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' show User;
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
  });
}
