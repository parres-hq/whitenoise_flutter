import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class DisplayedChatService {
  static final _logger = Logger('DisplayedChatService');
  static const String _displayedChatKey = 'displayed_chat_group_id';

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> registerDisplayedChat(
    String groupId, {
    FlutterSecureStorage? storage,
  }) async {
    if (groupId.isEmpty) {
      _logger.warning('Attempted to register empty groupId');
      return;
    }
    final secureStorage = storage ?? _defaultStorage;
    try {
      await secureStorage.write(key: _displayedChatKey, value: groupId);
      _logger.info('Registered displayed chat: $groupId');
    } catch (e) {
      _logger.warning('Failed to register displayed chat: $e');
    }
  }

  static Future<void> unregisterDisplayedChat(
    String groupId, {
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final currentDisplayed = await secureStorage.read(key: _displayedChatKey);
      if (currentDisplayed == groupId) {
        await secureStorage.delete(key: _displayedChatKey);
        _logger.info('Unregistered displayed chat: $groupId');
      }
    } catch (e) {
      _logger.warning('Failed to unregister displayed chat: $e');
    }
  }

  static Future<bool> isChatDisplayed(
    String groupId, {
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      final displayedGroupId = await secureStorage.read(key: _displayedChatKey);
      final isDisplayed = displayedGroupId == groupId;
      if (isDisplayed) {
        _logger.fine('Chat $groupId is displayed, skipping notification');
      }
      return isDisplayed;
    } catch (e) {
      _logger.warning('Failed to check if chat is displayed: $e');
      return false;
    }
  }

  static Future<String?> getDisplayedChat({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      return await secureStorage.read(key: _displayedChatKey);
    } catch (e) {
      _logger.warning('Failed to get displayed chat: $e');
      return null;
    }
  }

  static Future<void> clearDisplayedChat({FlutterSecureStorage? storage}) async {
    final secureStorage = storage ?? _defaultStorage;
    try {
      await secureStorage.delete(key: _displayedChatKey);
      _logger.fine('Cleared displayed chat');
    } catch (e) {
      _logger.warning('Failed to clear displayed chat: $e');
    }
  }
}
