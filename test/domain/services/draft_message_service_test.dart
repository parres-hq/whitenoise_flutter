import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';

import '../../shared/mocks/flutter_secure_storage_mock_helper.dart';

void main() {
  group('DraftMessageService', () {
    late FlutterSecureStorage storage;

    setUp(() {
      final mockSetup = FlutterSecureStorageMockHelper.createInMemoryMock();
      storage = mockSetup.mock;
    });

    group('saveDraft', () {
      group('when message has content', () {
        test('writes message to storage', () async {
          await DraftMessageService().saveDraft(
            chatId: 'my_chat_id',
            message: 'Hello world message',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_my_chat_id');
          expect(storedValue, equals('Hello world message'));
        });
      });

      group('when message is empty or whitespace', () {
        setUp(() async {
          await storage.write(key: 'draft_message_my_chat_id', value: 'Existing draft message');
        });

        test('deletes from storage with empty string', () async {
          await DraftMessageService().saveDraft(
            chatId: 'my_chat_id',
            message: '',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_my_chat_id');
          expect(storedValue, isNull);
        });

        test('deletes from storage with whitespace only', () async {
          await DraftMessageService().saveDraft(
            chatId: 'my_chat_id',
            message: '   \t\n  ',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_my_chat_id');
          expect(storedValue, isNull);
        });
      });

      group('when draft already exists', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_my_super_chat_id',
            value: 'Original draft content',
          );
        });

        test('overwrites existing draft', () async {
          await DraftMessageService().saveDraft(
            chatId: 'my_super_chat_id',
            message: 'Updated draft content',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_my_super_chat_id');
          expect(storedValue, equals('Updated draft content'));
        });
      });
    });

    group('loadDraft', () {
      group('when draft exists in storage', () {
        setUp(() async {
          await storage.write(key: 'draft_message_other_chat_id', value: 'Stored draft content');
        });

        test('returns the stored message', () async {
          final result = await DraftMessageService().loadDraft(
            chatId: 'other_chat_id',
            storage: storage,
          );

          expect(result, equals('Stored draft content'));
        });
      });

      group('when draft does not exist', () {
        test('returns null', () async {
          final result = await DraftMessageService().loadDraft(
            chatId: 'nonexistent_chat_id',
            storage: storage,
          );

          expect(result, isNull);
        });
      });

      group('when draft contains special characters', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_emojis_chat_id',
            value: 'Message with émojis 🚀 and spëcial chars: @#\$%^&*()',
          );
        });

        test('returns the message correctly', () async {
          final result = await DraftMessageService().loadDraft(
            chatId: 'emojis_chat_id',
            storage: storage,
          );

          expect(result, equals('Message with émojis 🚀 and spëcial chars: @#\$%^&*()'));
        });
      });
    });

    group('clearDraft', () {
      group('when multiple drafts exist', () {
        setUp(() async {
          await storage.write(key: 'draft_message_first_chat_id', value: 'First chat draft');
          await storage.write(key: 'draft_message_second_chat_id', value: 'Second chat draft');
        });

        test('removes only the specified draft', () async {
          await DraftMessageService().clearDraft(
            chatId: 'first_chat_id',
            storage: storage,
          );

          final value1 = await storage.read(key: 'draft_message_first_chat_id');
          expect(value1, isNull);
        });

        test('leaves other drafts unchanged', () async {
          await DraftMessageService().clearDraft(
            chatId: 'first_chat_id',
            storage: storage,
          );

          final value2 = await storage.read(key: 'draft_message_second_chat_id');
          expect(value2, equals('Second chat draft'));
        });
      });

      group('when draft does not exist', () {
        test('completes without error', () async {
          await DraftMessageService().clearDraft(
            chatId: 'missing_chat_id',
            storage: storage,
          );

          final value = await storage.read(key: 'draft_message_missing_chat_id');
          expect(value, isNull);
        });
      });
    });

    group('clearAllDrafts', () {
      group('when drafts and other data exist', () {
        setUp(() async {
          await storage.write(key: 'draft_message_chat_one_id', value: 'Draft message one');
          await storage.write(key: 'draft_message_chat_two_id', value: 'Draft message two');
          await storage.write(key: 'user_preferences', value: 'Important user data');
        });

        test('removes all draft keys', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final draft1 = await storage.read(key: 'draft_message_chat_one_id');
          expect(draft1, isNull);
        });

        test('preserves non-draft data', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final otherData = await storage.read(key: 'user_preferences');
          expect(otherData, equals('Important user data'));
        });
      });

      group('when storage is empty', () {
        test('completes without error', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final allData = await storage.readAll();
          expect(allData, isEmpty);
        });
      });

      group('when similar but invalid keys exist', () {
        setUp(() async {
          await storage.write(key: 'draft_message', value: 'no underscore key');
          await storage.write(key: 'other_draft_message_chat_id', value: 'wrong prefix key');
          await storage.write(key: 'mydraft_message_chat_id', value: 'another wrong prefix');
          await storage.write(key: 'draft_message_valid_chat_id', value: 'valid draft key');
          await storage.write(key: 'draft_message_', value: 'empty suffix key');
        });

        test('preserves keys without exact prefix', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final preserved = await storage.read(key: 'draft_message');
          expect(preserved, equals('no underscore key'));
        });

        test('removes keys with exact prefix', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final cleared = await storage.read(key: 'draft_message_valid_chat_id');
          expect(cleared, isNull);
        });
      });
    });
  });
}
