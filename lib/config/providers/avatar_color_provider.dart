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
    // Check cache first
    if (state.containsKey(pubkey)) {
      return state[pubkey]!;
    }

    // Get or generate from service
    final color = await _service.getOrGenerateColor(pubkey);

    // Update cache
    state = {...state, pubkey: color};

    return color;
  }

  /// Preload colors for multiple pubkeys
  /// This is efficient for batch operations like loading follows
  Future<void> preloadColors(List<String> pubkeys) async {
    try {
      _logger.info('Preloading colors for ${pubkeys.length} pubkeys');

      // Filter out pubkeys that are already cached
      final uncachedPubkeys = pubkeys.where((pk) => !state.containsKey(pk)).toList();

      if (uncachedPubkeys.isEmpty) {
        _logger.info('All pubkeys already cached');
        return;
      }

      // Batch generate/load colors
      final colorMap = await _service.generateColorsForPubkeys(uncachedPubkeys);

      // Update state with new colors
      state = {...state, ...colorMap};

      _logger.info('Preloaded ${colorMap.length} colors');
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
