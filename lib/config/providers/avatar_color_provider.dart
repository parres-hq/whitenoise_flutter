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
    return {};
  }

  /// Get color for a pubkey from cache or generate new one
  Future<Color> getColor(String pubkey) async {
    final cacheKey = AvatarColorService.toCacheKey(pubkey);
    
    // Check cache first
    if (state.containsKey(cacheKey)) {
      return state[cacheKey]!;
    }

    // Get or generate from service
    final color = await _service.getOrGenerateColor(pubkey);

    // Update cache
    state = {...state, cacheKey: color};

    return color;
  }

  /// Preload colors for multiple pubkeys
  /// This is efficient for batch operations like loading follows
  Future<void> preloadColors(List<String> pubkeys) async {
    try {
      _logger.info('Preloading colors for ${pubkeys.length} pubkeys');

      // Filter out pubkeys that are already cached
      final uncachedPubkeys = pubkeys.where((pk) {
        final cacheKey = AvatarColorService.toCacheKey(pk);
        return !state.containsKey(cacheKey);
      }).toList();

      if (uncachedPubkeys.isEmpty) {
        _logger.info('All pubkeys already cached');
        return;
      }

      // Batch generate/load colors
      final colorMap = await _service.generateColorsForPubkeys(uncachedPubkeys);

      // Convert to cache keys before updating state
      final cacheKeyColorMap = <String, Color>{};
      for (final entry in colorMap.entries) {
        final cacheKey = AvatarColorService.toCacheKey(entry.key);
        cacheKeyColorMap[cacheKey] = entry.value;
      }

      // Update state with new colors
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
