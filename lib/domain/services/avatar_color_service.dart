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

  /// Predefined set of vibrant colors for avatars
  static final List<Color> _avatarColors = [
    const Color(0xFFE57373), // Red
    const Color(0xFFF06292), // Pink
    const Color(0xFFBA68C8), // Purple
    const Color(0xFF9575CD), // Deep Purple
    const Color(0xFF7986CB), // Indigo
    const Color(0xFF64B5F6), // Blue
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFF4DD0E1), // Cyan
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFF81C784), // Green
    const Color(0xFFAED581), // Light Green
    const Color(0xFFFFD54F), // Amber
    const Color(0xFFFFB74D), // Orange
    const Color(0xFFFF8A65), // Deep Orange
    const Color(0xFFA1887F), // Brown
    const Color(0xFF90A4AE), // Blue Grey
  ];

  /// Generate a unique identifier from pubkey (first 12 chars of npub)
  String _generateIdentifier(String pubkey) {
    final npub = PubkeyFormatter(pubkey: pubkey).toNpub();
    if (npub == null) {
      _logger.warning('Failed to convert pubkey to npub, using hex fallback');
      return pubkey.substring(0, 12);
    }
    return npub.substring(0, 12);
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

  /// Generate a random color from the predefined palette
  Color _generateRandomColor() {
    final random = Random();
    return _avatarColors[random.nextInt(_avatarColors.length)];
  }

  /// Get color for a pubkey, generating and saving if not exists
  Future<Color> getOrGenerateColor(String pubkey) async {
    try {
      final identifier = _generateIdentifier(pubkey);
      final colorsMap = await _loadColorsMap();

      // Try to get existing color
      final colorValue = colorsMap[identifier];
      if (colorValue != null) {
        return Color(colorValue);
      }

      // Generate new color
      final newColor = _generateRandomColor();
      colorsMap[identifier] = newColor.toARGB32();
      await _saveColorsMap(colorsMap);
      _logger.info('Generated new color for pubkey: ${pubkey.substring(0, 8)}...');

      return newColor;
    } catch (e) {
      _logger.severe('Error getting/generating color for pubkey: $e');
      // Return a default color on error
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
        final identifier = _generateIdentifier(pubkey);

        // Check if color already exists
        final existingColorValue = colorsMap[identifier];
        if (existingColorValue != null) {
          colorMap[pubkey] = Color(existingColorValue);
        } else {
          // Generate new color
          final newColor = _generateRandomColor();
          colorsMap[identifier] = newColor.toARGB32();
          colorMap[pubkey] = newColor;
          hasNewColors = true;
        }
      }

      // Only save if we generated new colors
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
