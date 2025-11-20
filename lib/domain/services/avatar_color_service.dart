import 'dart:convert';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/domain/models/avatar_color_tokens.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

class AvatarColorService {
  static const String _storageKey = 'avatar_colors_map';
  static final _logger = Logger('AvatarColorService');

  static String toCacheKey(String pubkey) {
    final trimmed = pubkey.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _logger.warning('Empty pubkey provided to toCacheKey');
      return 'empty_key';
    }

    if (trimmed.startsWith('npub1')) {
      return trimmed;
    }

    final npub = PubkeyFormatter(pubkey: trimmed).toNpub();
    if (npub == null) {
      _logger.warning('Failed to convert pubkey to npub, using hex fallback');
      return trimmed;
    }

    return npub;
  }

  Future<Map<String, Map<String, dynamic>>> _loadColorTokensMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return {};

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as Map<String, dynamic>));
    } catch (e) {
      _logger.severe('Error loading color tokens map: $e');
      return {};
    }
  }

  Future<void> _saveColorTokensMap(Map<String, Map<String, dynamic>> tokensMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(tokensMap);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      _logger.severe('Error saving color tokens map: $e');
    }
  }

  Future<Map<String, AvatarColorToken>> loadAllColorTokens() async {
    try {
      final tokensMap = await _loadColorTokensMap();
      return tokensMap.map((key, value) => MapEntry(key, AvatarColorToken.fromJson(value)));
    } catch (e) {
      _logger.severe('Error loading all color tokens: $e');
      return {};
    }
  }

  AvatarColorToken _generateRandomColorToken(String pubkey) {
    final identifier = toCacheKey(pubkey);
    final hash = identifier.hashCode.abs();
    return AvatarColorTokens.all[hash % AvatarColorTokens.all.length];
  }

  AvatarColorToken generateRandomColorTokenPublic() {
    final random = math.Random();
    return AvatarColorTokens.all[random.nextInt(AvatarColorTokens.all.length)];
  }

  Future<void> saveColorTokenDirectly(String pubkey, AvatarColorToken colorToken) async {
    try {
      final identifier = toCacheKey(pubkey);
      final tokensMap = await _loadColorTokensMap();
      tokensMap[identifier] = colorToken.toJson();
      await _saveColorTokensMap(tokensMap);
      _logger.info('Saved color token directly for pubkey: $pubkey');
    } catch (e) {
      _logger.severe('Error saving color token directly: $e');
    }
  }

  Future<AvatarColorToken> getOrGenerateColorToken(String pubkey) async {
    try {
      final identifier = toCacheKey(pubkey);
      final tokensMap = await _loadColorTokensMap();

      final tokenJson = tokensMap[identifier];
      if (tokenJson != null) {
        return AvatarColorToken.fromJson(tokenJson);
      }

      final newToken = _generateRandomColorToken(pubkey);
      tokensMap[identifier] = newToken.toJson();
      await _saveColorTokensMap(tokensMap);
      _logger.info('Generated new color token for pubkey: $pubkey');

      return newToken;
    } catch (e) {
      _logger.severe('Error getting/generating color token for pubkey: $e');
      return AvatarColorTokens.blue;
    }
  }

  Future<Map<String, AvatarColorToken>> generateColorTokensForPubkeys(
    List<String> pubkeys,
  ) async {
    final Map<String, AvatarColorToken> tokenMap = {};

    try {
      final tokensMap = await _loadColorTokensMap();
      bool hasNewTokens = false;

      for (final pubkey in pubkeys) {
        final identifier = toCacheKey(pubkey);
        final existingTokenJson = tokensMap[identifier];

        if (existingTokenJson != null) {
          tokenMap[pubkey] = AvatarColorToken.fromJson(existingTokenJson);
        } else {
          final newToken = _generateRandomColorToken(pubkey);
          tokensMap[identifier] = newToken.toJson();
          tokenMap[pubkey] = newToken;
          hasNewTokens = true;
        }
      }

      if (hasNewTokens) {
        await _saveColorTokensMap(tokensMap);
      }

      _logger.info('Generated/loaded color tokens for ${pubkeys.length} pubkeys');
    } catch (e) {
      _logger.severe('Error batch generating color tokens: $e');
    }

    return tokenMap;
  }

  Future<void> clearAllColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _logger.info('Cleared all avatar colors');
    } catch (e) {
      _logger.severe('Error clearing avatar colors: $e');
    }
  }
}
