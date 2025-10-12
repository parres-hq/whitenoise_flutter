import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/avatar_color_service.dart';

/// Provider for managing avatar colors in memory
final avatarColorProvider = NotifierProvider<AvatarColorNotifier, Map<String, Color>>(AvatarColorNotifier.new);

class AvatarColorNotifier extends Notifier<Map<String, Color>> {
  final _logger = Logger('AvatarColorProvider');
  final _service = AvatarColorService();

  @override
  Map<String, Color> build() {
    _loadSavedColors();
    return {};
  }

  /// Load all saved colors from SharedPreferences into memory cache
  Future<void> _loadSavedColors() async {
    try {
      final colorsMap = await _service.loadAllColors();
      if (colorsMap.isNotEmpty) {
        state = colorsMap;
        _logger.info('Loaded ${colorsMap.length} saved colors into cache');
      }
    } catch (e) {
      _logger.warning('Failed to load saved colors: $e');
    }
  }

  /// Get color for a pubkey from cache or generate new one
  Future<Color> getColor(String pubkey) async {
    final cacheKey = AvatarColorService.toCacheKey(pubkey);
    
    if (state.containsKey(cacheKey)) {
      return state[cacheKey]!;
    }

    final color = await _service.getOrGenerateColor(pubkey);
    state = {...state, cacheKey: color};

    return color;
  }

  /// Preload colors for multiple pubkeys
  /// This is efficient for batch operations like loading follows
  Future<void> preloadColors(List<String> pubkeys) async {
    try {
      _logger.info('Preloading colors for ${pubkeys.length} pubkeys');

      final uncachedPubkeys = pubkeys.where((pk) {
        final cacheKey = AvatarColorService.toCacheKey(pk);
        return !state.containsKey(cacheKey);
      }).toList();

      if (uncachedPubkeys.isEmpty) {
        _logger.info('All pubkeys already cached');
        return;
      }

      final colorMap = await _service.generateColorsForPubkeys(uncachedPubkeys);
      final cacheKeyColorMap = <String, Color>{};
      for (final entry in colorMap.entries) {
        final cacheKey = AvatarColorService.toCacheKey(entry.key);
        cacheKeyColorMap[cacheKey] = entry.value;
      }

      state = {...state, ...cacheKeyColorMap};

      _logger.info('Preloaded ${cacheKeyColorMap.length} colors');
    } catch (e) {
      _logger.severe('Error preloading colors: $e');
    }
  }

  /// Clear all colors including SharedPreferences
  Future<void> clearAll() async {
    await _service.clearAllColors();
    state = {};
    _logger.info('Cleared all avatar colors');
  }
}
