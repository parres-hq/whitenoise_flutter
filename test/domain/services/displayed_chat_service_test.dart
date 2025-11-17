import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:whitenoise/domain/services/displayed_chat_service.dart';

import 'displayed_chat_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  group('DisplayedChatService', () {
    late MockFlutterSecureStorage mockStorage;
    const String testGroupId = 'test-group-123';
    const String otherGroupId = 'other-group-456';

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    group('registerDisplayedChat', () {
      test('registers the displayed chat', () async {
        when(
          mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
        ).thenAnswer((_) async => {});

        await DisplayedChatService.registerDisplayedChat(
          testGroupId,
          storage: mockStorage,
        );

        verify(
          mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
        ).called(1);
      });

      group('with empty groupId', () {
        test('does not register and returns early', () async {
          await DisplayedChatService.registerDisplayedChat(
            '',
            storage: mockStorage,
          );

          verifyNever(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')));
        });
      });

      group('with error', () {
        setUp(() {
          when(
            mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
          ).thenThrow(Exception('Storage error'));
        });

        test('handles error gracefully', () async {
          await DisplayedChatService.registerDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(
            mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
          ).called(1);
        });
      });
    });

    group('unregisterDisplayedChat', () {
      group('when chat is currently displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => testGroupId);
          when(mockStorage.delete(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => {});
        });

        test('unregisters the displayed chat', () async {
          await DisplayedChatService.unregisterDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
          verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('when different chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => otherGroupId);
        });

        test('does not unregister', () async {
          await DisplayedChatService.unregisterDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
          verifyNever(mockStorage.delete(key: anyNamed('key')));
        });
      });

      group('when no chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => null);
        });

        test('does not unregister', () async {
          await DisplayedChatService.unregisterDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
          verifyNever(mockStorage.delete(key: anyNamed('key')));
        });
      });

      group('with error during read', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenThrow(Exception('Storage error'));
        });

        test('handles error gracefully', () async {
          await DisplayedChatService.unregisterDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
          verifyNever(mockStorage.delete(key: anyNamed('key')));
        });
      });

      group('with error during delete', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => testGroupId);
          when(mockStorage.delete(key: 'displayed_chat_group_id'))
              .thenThrow(Exception('Storage error'));
        });

        test('handles error gracefully', () async {
          await DisplayedChatService.unregisterDisplayedChat(
            testGroupId,
            storage: mockStorage,
          );

          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
          verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
        });
      });
    });

    group('isChatDisplayed', () {
      group('when chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => testGroupId);
        });

        test('returns true', () async {
          final result = await DisplayedChatService.isChatDisplayed(
            testGroupId,
            storage: mockStorage,
          );

          expect(result, isTrue);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('when different chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => otherGroupId);
        });

        test('returns false', () async {
          final result = await DisplayedChatService.isChatDisplayed(
            testGroupId,
            storage: mockStorage,
          );

          expect(result, isFalse);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('when no chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => null);
        });

        test('returns false', () async {
          final result = await DisplayedChatService.isChatDisplayed(
            testGroupId,
            storage: mockStorage,
          );

          expect(result, isFalse);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('with error', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenThrow(Exception('Storage error'));
        });

        test('returns false and handles error gracefully', () async {
          final result = await DisplayedChatService.isChatDisplayed(
            testGroupId,
            storage: mockStorage,
          );

          expect(result, isFalse);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });
    });

    group('getDisplayedChat', () {
      group('when chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => testGroupId);
        });

        test('returns the groupId', () async {
          final result = await DisplayedChatService.getDisplayedChat(
            storage: mockStorage,
          );

          expect(result, equals(testGroupId));
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('when no chat is displayed', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenAnswer((_) async => null);
        });

        test('returns null', () async {
          final result = await DisplayedChatService.getDisplayedChat(
            storage: mockStorage,
          );

          expect(result, isNull);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });

      group('with error', () {
        setUp(() {
          when(mockStorage.read(key: 'displayed_chat_group_id'))
              .thenThrow(Exception('Storage error'));
        });

        test('returns null and handles error gracefully', () async {
          final result = await DisplayedChatService.getDisplayedChat(
            storage: mockStorage,
          );

          expect(result, isNull);
          verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        });
      });
    });

    group('clearDisplayedChat', () {
      test('clears the displayed chat', () async {
        when(mockStorage.delete(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => {});

        await DisplayedChatService.clearDisplayedChat(storage: mockStorage);

        verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
      });

      group('with error', () {
        setUp(() {
          when(mockStorage.delete(key: 'displayed_chat_group_id'))
              .thenThrow(Exception('Storage error'));
        });

        test('handles error gracefully', () async {
          await DisplayedChatService.clearDisplayedChat(storage: mockStorage);

          verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
        });
      });
    });

    group('integration tests', () {
      test('registerDisplayedChat and isChatDisplayed work together', () async {
        when(
          mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
        ).thenAnswer((_) async => {});
        when(mockStorage.read(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => testGroupId);

        await DisplayedChatService.registerDisplayedChat(
          testGroupId,
          storage: mockStorage,
        );

        final isDisplayed = await DisplayedChatService.isChatDisplayed(
          testGroupId,
          storage: mockStorage,
        );

        expect(isDisplayed, isTrue);
      });

      test('registerDisplayedChat and getDisplayedChat work together', () async {
        when(
          mockStorage.write(key: 'displayed_chat_group_id', value: testGroupId),
        ).thenAnswer((_) async => {});
        when(mockStorage.read(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => testGroupId);

        await DisplayedChatService.registerDisplayedChat(
          testGroupId,
          storage: mockStorage,
        );

        final displayedChat = await DisplayedChatService.getDisplayedChat(
          storage: mockStorage,
        );

        expect(displayedChat, equals(testGroupId));
      });

      test('clearDisplayedChat removes displayed chat', () async {
        when(mockStorage.read(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => testGroupId);
        when(mockStorage.delete(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => {});

        await DisplayedChatService.clearDisplayedChat(storage: mockStorage);

        verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
      });

      test('unregisterDisplayedChat only removes matching chat', () async {
        when(mockStorage.read(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => testGroupId);
        when(mockStorage.delete(key: 'displayed_chat_group_id'))
            .thenAnswer((_) async => {});

        // Try to unregister a different chat
        await DisplayedChatService.unregisterDisplayedChat(
          otherGroupId,
          storage: mockStorage,
        );

        verify(mockStorage.read(key: 'displayed_chat_group_id')).called(1);
        verifyNever(mockStorage.delete(key: anyNamed('key')));

        // Now unregister the correct chat
        await DisplayedChatService.unregisterDisplayedChat(
          testGroupId,
          storage: mockStorage,
        );

        verify(mockStorage.delete(key: 'displayed_chat_group_id')).called(1);
      });
    });
  });
}

