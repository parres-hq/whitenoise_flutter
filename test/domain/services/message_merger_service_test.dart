import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/domain/services/message_merger_service.dart';

void main() {
  group('MessageMergerService', () {
    group('merge', () {
      group('without messages in sending status', () {
        test('returns messages stored in db', () {
          final stateMessages = [
            _createMessage(
              id: '1',
              content: 'sent message',
              createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
            ),
          ];
          final dbMessages = [
            _createMessage(
              id: '2',
              content: 'message stored in db',
              createdAt: DateTime.now(),
            ),
          ];

          final result = MessageMergerService.merge(
            stateMessages: stateMessages,
            dbMessages: dbMessages,
          );

          expect(result, hasLength(1));
          expect(result.first.id, equals('2'));
          expect(result.first.content, equals('message stored in db'));
          expect(result.first.status, equals(MessageStatus.sent));
        });
      });

      group('with messages in sending status', () {
        group('without new messages', () {
          test('preserves recent sending messages', () {
            final stateMessages = [
              _createMessage(
                id: '1',
                content: 'sending message',
                status: MessageStatus.sending,
                createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
              ),
            ];
            final dbMessages = <MessageModel>[];

            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(1));
            expect(result.first.id, equals('1'));
            expect(result.first.status, equals(MessageStatus.sending));
          });
        });

        group('with recent messages with different content', () {
          test(
            'returns the sending message with different content and the db repeated message',
            () {
              final now = DateTime.now();
              final stateMessages = [
                _createMessage(
                  id: '1',
                  content: 'repeated message',
                  status: MessageStatus.sending,
                  createdAt: now.subtract(const Duration(seconds: 30)),
                ),
                _createMessage(
                  id: '3',
                  content: 'different message',
                  status: MessageStatus.sending,
                  createdAt: now,
                ),
              ];
              final dbMessages = [
                _createMessage(
                  id: '2',
                  content: 'repeated message',
                  createdAt: now.subtract(const Duration(seconds: 15)),
                ),
              ];

              final result = MessageMergerService.merge(
                stateMessages: stateMessages,
                dbMessages: dbMessages,
              );

              expect(result, hasLength(2));
              expect(result.first.id, equals('2'));
              expect(result.first.content, equals('repeated message'));
              expect(result.first.status, equals(MessageStatus.sent));
              expect(result.last.id, equals('3'));
              expect(result.last.content, equals('different message'));
              expect(result.last.status, equals(MessageStatus.sending));
            },
          );
        });

        group('with multiple recent messages with different content', () {
          test('returns all sending messages and the db stored messages', () {
            final now = DateTime.now();
            final recentTime1 = now.subtract(const Duration(seconds: 30));
            final recentTime2 = now.subtract(const Duration(seconds: 45));

            final stateMessages = [
              _createMessage(
                id: '1',
                content: 'first sending message',
                status: MessageStatus.sending,
                createdAt: recentTime1,
              ),
              _createMessage(
                id: '2',
                content: 'second sending message',
                status: MessageStatus.sending,
                createdAt: recentTime2,
              ),
            ];
            final dbMessages = [
              _createMessage(
                id: '3',
                content: 'I am a message stored in db',
                createdAt: now,
              ),
            ];

            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(3));
            expect(result.map((m) => m.id), containsAll(['1', '2', '3']));
          });
        });

        group('with old sending messages with different content', () {
          test('returns only the db stored and sent message', () {
            final now = DateTime.now();
            final oldTime = now.subtract(const Duration(minutes: 2));

            final stateMessages = [
              _createMessage(
                id: '1',
                content: 'old sending message',
                status: MessageStatus.sending,
                createdAt: oldTime,
              ),
            ];
            final dbMessages = [
              _createMessage(
                id: '2',
                content: 'I am a message stored in db',
                createdAt: now,
              ),
            ];
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );
            expect(result, hasLength(1));
            expect(result.first.id, equals('2'));
            expect(result.first.content, equals('I am a message stored in db'));
            expect(result.first.status, equals(MessageStatus.sent));
          });
        });

        group('with recent messages with same content', () {
          test('returns only the sent message', () {
            final now = DateTime.now();
            final recentTime = now.subtract(const Duration(seconds: 30));

            final stateMessages = [
              _createMessage(
                id: '1',
                content: 'same message',
                status: MessageStatus.sending,
                createdAt: recentTime,
              ),
            ];
            final dbMessages = [
              _createMessage(
                id: '2',
                content: 'same message',
                createdAt: now,
              ),
            ];

            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(1));
            expect(result.first.id, equals('2'));
            expect(result.first.content, equals('same message'));
            expect(result.first.status, equals(MessageStatus.sent));
          });
        });
      });
    });
  });
}

MessageModel _createMessage({
  required String id,
  String content = 'test content',
  MessageStatus status = MessageStatus.sent,
  DateTime? createdAt,
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    status: status,
    createdAt: createdAt ?? DateTime.now(),
    sender: User(
      id: 'test_id',
      publicKey: 'test_pubkey',
      displayName: 'Test User',
      nip05: '',
    ),
    isMe: false,
    reactions: [],
  );
}
