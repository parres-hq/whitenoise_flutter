import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';

import '../../shared/mocks/flutter_secure_storage_mock_helper.dart';

void main() {
  group('DraftMessageService', () {
    late FlutterSecureStorage storage;
    const testAccountId = 'test_account_123';

    setUp(() {
      final mockSetup = FlutterSecureStorageMockHelper.createInMemoryMock();
      storage = mockSetup.mock;
    });

    group('saveDraft', () {
      group('when message has content', () {
        test('writes message to storage', () async {
          await DraftMessageService().saveDraft(
            accountId: testAccountId,
            chatId: 'my_chat_id',
            message: 'Hello world message',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_${testAccountId}_my_chat_id');
          expect(storedValue, equals('Hello world message'));
        });
      });

      group('when message is empty or whitespace', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_my_chat_id',
            value: 'Existing draft message',
          );
        });

        test('deletes from storage with empty string', () async {
          await DraftMessageService().saveDraft(
            accountId: testAccountId,
            chatId: 'my_chat_id',
            message: '',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_${testAccountId}_my_chat_id');
          expect(storedValue, isNull);
        });

        test('deletes from storage with whitespace only', () async {
          await DraftMessageService().saveDraft(
            accountId: testAccountId,
            chatId: 'my_chat_id',
            message: '   \t\n  ',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_${testAccountId}_my_chat_id');
          expect(storedValue, isNull);
        });
      });

      group('when draft already exists', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_my_super_chat_id',
            value: 'Original draft content',
          );
        });

        test('overwrites existing draft', () async {
          await DraftMessageService().saveDraft(
            accountId: testAccountId,
            chatId: 'my_super_chat_id',
            message: 'Updated draft content',
            storage: storage,
          );

          final storedValue = await storage.read(key: 'draft_message_${testAccountId}_my_super_chat_id');
          expect(storedValue, equals('Updated draft content'));
        });
      });
    });

    group('loadDraft', () {
      group('when draft exists in storage', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_other_chat_id',
            value: 'Stored draft content',
          );
        });

        test('returns the stored message', () async {
          final result = await DraftMessageService().loadDraft(
            accountId: testAccountId,
            chatId: 'other_chat_id',
            storage: storage,
          );

          expect(result, equals('Stored draft content'));
        });
      });

      group('when draft does not exist', () {
        test('returns null', () async {
          final result = await DraftMessageService().loadDraft(
            accountId: testAccountId,
            chatId: 'nonexistent_chat_id',
            storage: storage,
          );

          expect(result, isNull);
        });
      });

      group('when draft contains special characters', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_emojis_chat_id',
            value: 'Message with émojis 🚀 and spëcial chars: @#\$%^&*()',
          );
        });

        test('returns the message correctly', () async {
          final result = await DraftMessageService().loadDraft(
            accountId: testAccountId,
            chatId: 'emojis_chat_id',
            storage: storage,
          );

          expect(result, equals('Message with émojis 🚀 and spëcial chars: @#\$%^&*()'));
        });
      });

      group('when draft belongs to different account', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_shared_chat_id',
            value: 'Account 1 draft',
          );
          await storage.write(
            key: 'draft_message_other_account_456_shared_chat_id',
            value: 'Account 2 draft',
          );
        });

        test('returns only the draft for the specified account', () async {
          final result = await DraftMessageService().loadDraft(
            accountId: testAccountId,
            chatId: 'shared_chat_id',
            storage: storage,
          );

          expect(result, equals('Account 1 draft'));
        });

        test('does not return draft from other account', () async {
          final result = await DraftMessageService().loadDraft(
            accountId: 'other_account_456',
            chatId: 'shared_chat_id',
            storage: storage,
          );

          expect(result, equals('Account 2 draft'));
        });
      });
    });

    group('clearDraft', () {
      group('when multiple drafts exist', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_first_chat_id',
            value: 'First chat draft',
          );
          await storage.write(
            key: 'draft_message_${testAccountId}_second_chat_id',
            value: 'Second chat draft',
          );
        });

        test('removes only the specified draft', () async {
          await DraftMessageService().clearDraft(
            accountId: testAccountId,
            chatId: 'first_chat_id',
            storage: storage,
          );

          final value1 = await storage.read(key: 'draft_message_${testAccountId}_first_chat_id');
          expect(value1, isNull);
        });

        test('leaves other drafts unchanged', () async {
          await DraftMessageService().clearDraft(
            accountId: testAccountId,
            chatId: 'first_chat_id',
            storage: storage,
          );

          final value2 = await storage.read(key: 'draft_message_${testAccountId}_second_chat_id');
          expect(value2, equals('Second chat draft'));
        });
      });

      group('when draft does not exist', () {
        test('completes without error', () async {
          await DraftMessageService().clearDraft(
            accountId: testAccountId,
            chatId: 'missing_chat_id',
            storage: storage,
          );

          final value = await storage.read(key: 'draft_message_${testAccountId}_missing_chat_id');
          expect(value, isNull);
        });
      });

      group('when drafts from different accounts exist', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_shared_chat_id',
            value: 'Account 1 draft',
          );
          await storage.write(
            key: 'draft_message_other_account_456_shared_chat_id',
            value: 'Account 2 draft',
          );
        });

        test('removes only the draft for the specified account', () async {
          await DraftMessageService().clearDraft(
            accountId: testAccountId,
            chatId: 'shared_chat_id',
            storage: storage,
          );

          final value1 = await storage.read(key: 'draft_message_${testAccountId}_shared_chat_id');
          expect(value1, isNull);

          final value2 = await storage.read(key: 'draft_message_other_account_456_shared_chat_id');
          expect(value2, equals('Account 2 draft'));
        });
      });
    });

    group('clearDraftsForAccount', () {
      group('when drafts from multiple accounts exist', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_chat_one_id',
            value: 'Account 1 draft one',
          );
          await storage.write(
            key: 'draft_message_${testAccountId}_chat_two_id',
            value: 'Account 1 draft two',
          );
          await storage.write(
            key: 'draft_message_other_account_456_chat_one_id',
            value: 'Account 2 draft one',
          );
          await storage.write(key: 'user_preferences', value: 'Important user data');
        });

        test('removes only drafts for the specified account', () async {
          await DraftMessageService().clearDraftsForAccount(
            accountId: testAccountId,
            storage: storage,
          );

          final draft1 = await storage.read(key: 'draft_message_${testAccountId}_chat_one_id');
          expect(draft1, isNull);

          final draft2 = await storage.read(key: 'draft_message_${testAccountId}_chat_two_id');
          expect(draft2, isNull);
        });

        test('preserves drafts from other accounts', () async {
          await DraftMessageService().clearDraftsForAccount(
            accountId: testAccountId,
            storage: storage,
          );

          final otherAccountDraft = await storage.read(
            key: 'draft_message_other_account_456_chat_one_id',
          );
          expect(otherAccountDraft, equals('Account 2 draft one'));
        });

        test('preserves non-draft data', () async {
          await DraftMessageService().clearDraftsForAccount(
            accountId: testAccountId,
            storage: storage,
          );

          final otherData = await storage.read(key: 'user_preferences');
          expect(otherData, equals('Important user data'));
        });
      });

      group('when storage is empty', () {
        test('completes without error', () async {
          await DraftMessageService().clearDraftsForAccount(
            accountId: testAccountId,
            storage: storage,
          );

          final allData = await storage.readAll();
          expect(allData, isEmpty);
        });
      });

      group('when account has no drafts', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_other_account_456_chat_one_id',
            value: 'Other account draft',
          );
        });

        test('completes without error and preserves other data', () async {
          await DraftMessageService().clearDraftsForAccount(
            accountId: testAccountId,
            storage: storage,
          );

          final otherAccountDraft = await storage.read(
            key: 'draft_message_other_account_456_chat_one_id',
          );
          expect(otherAccountDraft, equals('Other account draft'));
        });
      });
    });

    group('clearAllDrafts', () {
      group('when drafts and other data exist', () {
        setUp(() async {
          await storage.write(
            key: 'draft_message_${testAccountId}_chat_one_id',
            value: 'Draft message one',
          );
          await storage.write(
            key: 'draft_message_other_account_456_chat_two_id',
            value: 'Draft message two',
          );
          await storage.write(key: 'user_preferences', value: 'Important user data');
        });

        test('removes all draft keys from all accounts', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final draft1 = await storage.read(key: 'draft_message_${testAccountId}_chat_one_id');
          expect(draft1, isNull);

          final draft2 = await storage.read(key: 'draft_message_other_account_456_chat_two_id');
          expect(draft2, isNull);
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
          await storage.write(
            key: 'draft_message_${testAccountId}_valid_chat_id',
            value: 'valid draft key',
          );
          await storage.write(key: 'draft_message_', value: 'empty suffix key');
        });

        test('preserves keys without exact prefix', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final preserved = await storage.read(key: 'draft_message');
          expect(preserved, equals('no underscore key'));
        });

        test('removes keys with exact prefix', () async {
          await DraftMessageService().clearAllDrafts(storage: storage);

          final cleared = await storage.read(key: 'draft_message_${testAccountId}_valid_chat_id');
          expect(cleared, isNull);
        });
      });
    });
  });
}
