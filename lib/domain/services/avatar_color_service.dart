import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

/// Service for managing avatar colors with SharedPreferences persistence
class AvatarColorService {
  static const String _storageKey = 'avatar_colors_map';
  static final _logger = Logger('AvatarColorService');

  /// Predefined set of avatar foreground colors from design system
  static final List<Color> _avatarColors = [
    const Color(0xFF1e3a8a), // Blue Foreground
    const Color(0xFF164e63), // Cyan Foreground
    const Color(0xFF064e3b), // Emerald Foreground
    const Color(0xFF701a75), // Fuchsia Foreground
    const Color(0xFF312e81), // Indigo Foreground
    const Color(0xFF365314), // Lime Foreground
    const Color(0xFF7c2d12), // Orange Foreground
    const Color(0xFF881337), // Rose Foreground
    const Color(0xFF0c4a6e), // Sky Foreground
    const Color(0xFF134e4a), // Teal Foreground
    const Color(0xFF4c1d95), // Violet Foreground
    const Color(0xFF78350f), // Amber Foreground
  ];

  /// Generate a consistent cache key from pubkey (first 12 chars of npub)
  /// Handles both hex and npub format inputs
  /// Returns a shortened identifier, not a valid pubkey
  static String toCacheKey(String pubkey) {
    final trimmed = pubkey.trim();
    if (trimmed.isEmpty) {
      _logger.warning('Empty pubkey provided to toCacheKey');
      return 'empty_key';
    }

    if (trimmed.startsWith('npub1')) {
      return trimmed.length >= 12 ? trimmed.substring(0, 12) : trimmed;
    }

    final npub = PubkeyFormatter(pubkey: trimmed).toNpub();
    if (npub == null) {
      _logger.warning('Failed to convert pubkey to npub, using hex fallback');
      return trimmed.length >= 12 ? trimmed.substring(0, 12) : trimmed;
    }

    return npub.length >= 12 ? npub.substring(0, 12) : npub;
  }

  /// Load all colors from SharedPreferences
  Future<Map<String, int>> _loadColorsMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return {};

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      _logger.severe('Error loading colors map: $e');
      return {};
    }
  }

  /// Save all colors to SharedPreferences
  Future<void> _saveColorsMap(Map<String, int> colorsMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(colorsMap);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      _logger.severe('Error saving colors map: $e');
    }
  }

  /// Load all saved colors from SharedPreferences
  /// Returns a map of cache key -> Color for the provider's memory cache
  Future<Map<String, Color>> loadAllColors() async {
    try {
      final colorsMap = await _loadColorsMap();
      return colorsMap.map((key, value) => MapEntry(key, Color(value)));
    } catch (e) {
      _logger.severe('Error loading all colors: $e');
      return {};
    }
  }

  /// Generate a random color from the predefined palette
  Color _generateRandomColor() {
    final random = Random();
    return _avatarColors[random.nextInt(_avatarColors.length)];
  }

  /// Public method to generate a random color without saving
  /// Used for ephemeral previews
  Color generateRandomColorPublic() {
    return _generateRandomColor();
  }

  /// Save a color directly for a pubkey
  /// Used to persist ephemeral preview colors
  Future<void> saveColorDirectly(String pubkey, Color color) async {
    try {
      final identifier = toCacheKey(pubkey);
      final colorsMap = await _loadColorsMap();
      colorsMap[identifier] = color.toARGB32();
      await _saveColorsMap(colorsMap);
      _logger.info('Saved color directly for pubkey: $pubkey');
    } catch (e) {
      _logger.severe('Error saving color directly: $e');
    }
  }

  /// Get color for a pubkey, generating and saving if not exists
  Future<Color> getOrGenerateColor(String pubkey) async {
    try {
      final identifier = toCacheKey(pubkey);
      final colorsMap = await _loadColorsMap();

      final colorValue = colorsMap[identifier];
      if (colorValue != null) {
        return Color(colorValue);
      }

      final newColor = _generateRandomColor();
      colorsMap[identifier] = newColor.toARGB32();
      await _saveColorsMap(colorsMap);
      _logger.info('Generated new color for pubkey: $pubkey');

      return newColor;
    } catch (e) {
      _logger.severe('Error getting/generating color for pubkey: $e');
      return _avatarColors[0];
    }
  }

  /// Batch generate and save colors for multiple pubkeys
  /// Returns a map of pubkey -> color
  Future<Map<String, Color>> generateColorsForPubkeys(
    List<String> pubkeys,
  ) async {
    final Map<String, Color> colorMap = {};

    try {
      final colorsMap = await _loadColorsMap();
      bool hasNewColors = false;

      for (final pubkey in pubkeys) {
        final identifier = toCacheKey(pubkey);
        final existingColorValue = colorsMap[identifier];

        if (existingColorValue != null) {
          colorMap[pubkey] = Color(existingColorValue);
        } else {
          final newColor = _generateRandomColor();
          colorsMap[identifier] = newColor.toARGB32();
          colorMap[pubkey] = newColor;
          hasNewColors = true;
        }
      }

      if (hasNewColors) {
        await _saveColorsMap(colorsMap);
      }

      _logger.info('Generated/loaded colors for ${pubkeys.length} pubkeys');
    } catch (e) {
      _logger.severe('Error batch generating colors: $e');
    }

    return colorMap;
  }

  /// Clear all avatar colors
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
