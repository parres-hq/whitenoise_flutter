import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/avatar_color_tokens.dart';
import 'package:whitenoise/domain/services/avatar_color_service.dart';

final avatarColorProvider = NotifierProvider<AvatarColorNotifier, Map<String, AvatarColorToken>>(
  AvatarColorNotifier.new,
);

class AvatarColorNotifier extends Notifier<Map<String, AvatarColorToken>> {
  final _logger = Logger('AvatarColorProvider');
  final _avatarColorService = AvatarColorService();

  @override
  Map<String, AvatarColorToken> build() {
    _loadSavedColorTokens();
    return {};
  }

  Future<void> _loadSavedColorTokens() async {
    try {
      final tokenMap = await _avatarColorService.loadAllColorTokens();
      if (tokenMap.isNotEmpty) {
        state = tokenMap;
        _logger.info('Loaded ${tokenMap.length} saved color tokens into cache');
      }
    } catch (e) {
      _logger.warning('Failed to load saved color tokens: $e');
    }
  }

  Future<AvatarColorToken> getColorToken(String pubkey) async {
    final cacheKey = AvatarColorService.toCacheKey(pubkey);

    if (state.containsKey(cacheKey)) {
      return state[cacheKey]!;
    }

    final token = await _avatarColorService.getOrGenerateColorToken(pubkey);
    state = {...state, cacheKey: token};

    return token;
  }

  Future<void> preloadColorTokens(List<String> pubkeys) async {
    try {
      _logger.info('Preloading color tokens for ${pubkeys.length} pubkeys');

      final uncachedPubkeys =
          pubkeys.where((pk) {
            final cacheKey = AvatarColorService.toCacheKey(pk);
            return !state.containsKey(cacheKey);
          }).toList();

      if (uncachedPubkeys.isEmpty) {
        _logger.info('All pubkeys already cached');
        return;
      }

      final tokenMap = await _avatarColorService.generateColorTokensForPubkeys(uncachedPubkeys);
      final cacheKeyTokenMap = <String, AvatarColorToken>{};
      for (final entry in tokenMap.entries) {
        final cacheKey = AvatarColorService.toCacheKey(entry.key);
        cacheKeyTokenMap[cacheKey] = entry.value;
      }

      state = {...state, ...cacheKeyTokenMap};

      _logger.info('Preloaded ${cacheKeyTokenMap.length} color tokens');
    } catch (e) {
      _logger.severe('Error preloading color tokens: $e');
    }
  }

  AvatarColorToken generateRandomColorToken() {
    return _avatarColorService.generateRandomColorTokenPublic();
  }

  Future<void> setColorTokenDirectly(String pubkey, AvatarColorToken colorToken) async {
    final cacheKey = AvatarColorService.toCacheKey(pubkey);

    await _avatarColorService.saveColorTokenDirectly(pubkey, colorToken);

    state = {...state, cacheKey: colorToken};
    _logger.info('Set color token directly for $cacheKey');
  }

  Future<void> clearAll() async {
    await _avatarColorService.clearAllColors();
    state = {};
    _logger.info('Cleared all avatar color tokens');
  }
}
