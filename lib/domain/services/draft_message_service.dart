import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DraftMessageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _draftPrefix = 'draft_message_';

  static Future<void> saveDraft({
    required String chatId,
    required String message,
  }) async {
    try {
      final key = '$_draftPrefix$chatId';
      if (message.trim().isEmpty) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: message);
      }
    } catch (e) {
      print('Error saving draft message: $e');
    }
  }

  static Future<String?> loadDraft({required String chatId}) async {
    try {
      final key = '$_draftPrefix$chatId';
      return await _storage.read(key: key);
    } catch (e) {
      print('Error loading draft message: $e');
      return null;
    }
  }

  static Future<void> clearDraft({required String chatId}) async {
    try {
      final key = '$_draftPrefix$chatId';
      await _storage.delete(key: key);
    } catch (e) {
      print('Error clearing draft message: $e');
    }
  }

  static Future<void> clearAllDrafts() async {
    try {
      final allKeys = await _storage.readAll();
      final draftKeys = allKeys.keys.where((key) => key.startsWith(_draftPrefix));

      for (final key in draftKeys) {
        await _storage.delete(key: key);
      }
    } catch (e) {
      print('Error clearing all draft messages: $e');
    }
  }
}
