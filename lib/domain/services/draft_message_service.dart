import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DraftMessageService {
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage();
  static const String _draftPrefix = 'draft_message_';

  Future<void> saveDraft({
    required String chatId,
    required String message,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix$chatId';
      if (message.trim().isEmpty) {
        await secureStorage.delete(key: key);
      } else {
        await secureStorage.write(key: key, value: message);
      }
    } catch (e) {
      return;
    }
  }

  Future<String?> loadDraft({
    required String chatId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix$chatId';
      return await secureStorage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDraft({
    required String chatId,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final key = '$_draftPrefix$chatId';
      await secureStorage.delete(key: key);
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
