import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class DraftMessageService {
  static final Logger _logger = Logger('DraftMessageService');
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage();
  static const String _draftPrefix = 'draft_message_';

  Future<void> saveDraft({
    required String accountId,
    required String chatId,
    required String message,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix${accountId}_$chatId';
      if (message.trim().isEmpty) {
        await secureStorage.delete(key: key);
        _logger.fine('Draft cleared (accountId=$accountId, chatId=$chatId)');
      } else {
        await secureStorage.write(key: key, value: message);
        _logger.fine(
          'Draft saved (accountId=$accountId, chatId=$chatId, length=${message.length})',
        );
      }
    } catch (e) {
      return;
    }
  }

  Future<String?> loadDraft({
    required String accountId,
    required String chatId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix${accountId}_$chatId';
      return await secureStorage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDraft({
    required String accountId,
    required String chatId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix${accountId}_$chatId';
      await secureStorage.delete(key: key);
    } catch (e) {
      return;
    }
  }

  Future<void> clearDraftsForAccount({
    required String accountId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final allKeys = await secureStorage.readAll();
      final prefix = '$_draftPrefix${accountId}_';
      final draftKeys = allKeys.keys.where((key) => key.startsWith(prefix));
      for (final key in draftKeys) {
        await secureStorage.delete(key: key);
      }
      _logger.fine('Cleared drafts for accountId=$accountId');
    } catch (e) {
      return;
    }
  }

  Future<void> clearAllDrafts({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final allKeys = await secureStorage.readAll();
      final draftKeys = allKeys.keys.where((key) => key.startsWith(_draftPrefix));

      for (final key in draftKeys) {
        await secureStorage.delete(key: key);
      }
    } catch (e) {
      return;
    }
  }
}
