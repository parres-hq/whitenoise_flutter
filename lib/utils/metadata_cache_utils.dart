/// Utilities for metadata cache management and debugging
///
/// This file provides helpful utilities for managing the metadata cache,
/// debugging issues, and ensuring proper migration from the old system.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class MetadataCacheUtils {
  static final _logger = Logger('MetadataCacheUtils');

  /// Debug function to log cache statistics
  static void logCacheStats(WidgetRef ref) {
    final cache = ref.read(metadataCacheProvider.notifier);
    final stats = cache.getCacheStats();

    _logger.info('=== Metadata Cache Statistics ===');
    _logger.info('Total Cached Entries: ${stats['totalCached']}');
    _logger.info('Valid Entries: ${stats['validEntries']}');
    _logger.info('Expired Entries: ${stats['expiredEntries']}');
    _logger.info('Pending Fetches: ${stats['pendingFetches']}');
    _logger.info('================================');
  }

  /// Validate that all contacts have consistent npub format
  static Future<List<String>> validateContactConsistency(
    WidgetRef ref,
    List<String> publicKeys,
  ) async {
    final issues = <String>[];
    final cache = ref.read(metadataCacheProvider.notifier);

    for (final publicKey in publicKeys) {
      try {
        final contact = await cache.getContactModel(publicKey);

        // Check for common issues
        if (contact.publicKey != contact.publicKey.toLowerCase()) {
          issues.add('Inconsistent casing for $publicKey');
        }

        if (contact.publicKey.contains(' ')) {
          issues.add('Whitespace in public key for $publicKey');
        }

        if (!contact.publicKey.startsWith('npub1') &&
            !(contact.publicKey.length == 64 && !contact.publicKey.contains('npub'))) {
          issues.add('Invalid public key format for $publicKey');
        }
      } catch (e) {
        issues.add('Failed to fetch contact for $publicKey: $e');
      }
    }

    return issues;
  }

  /// Compare old vs new metadata handling to ensure consistency
  static Future<Map<String, dynamic>> compareMetadataResults(
    WidgetRef ref,
    List<String> publicKeys,
  ) async {
    final cache = ref.read(metadataCacheProvider.notifier);
    final results = <String, dynamic>{};

    for (final publicKey in publicKeys) {
      try {
        // Get from cache
        final cachedContact = await cache.getContactModel(publicKey);

        results[publicKey] = {
          'cached_display_name': cachedContact.displayName,
          'cached_public_key': cachedContact.publicKey,
          'cached_at': DateTime.now().toIso8601String(),
        };

        _logger.info('Contact $publicKey: ${cachedContact.displayName}');
      } catch (e) {
        results[publicKey] = {'error': e.toString()};
      }
    }

    return results;
  }

  /// Mass update cache with provided contact models (useful for migration)
  static Future<void> bulkUpdateCache(
    WidgetRef ref,
    Map<String, ContactModel> contacts,
  ) async {
    final cache = ref.read(metadataCacheProvider.notifier);

    _logger.info('Starting bulk cache update with ${contacts.length} contacts');

    for (final entry in contacts.entries) {
      try {
        cache.updateCachedMetadata(entry.key, entry.value);
      } catch (e) {
        _logger.warning('Failed to update cache for ${entry.key}: $e');
      }
    }

    _logger.info('Bulk cache update completed');
  }

  /// Clean up and optimize the cache
  static void optimizeCache(WidgetRef ref) {
    final cache = ref.read(metadataCacheProvider.notifier);

    // Clean expired entries
    cache.cleanExpiredEntries();

    _logger.info('Cache optimized - expired entries removed');
  }

  /// Export cache contents for debugging or backup
  static Map<String, Map<String, dynamic>> exportCacheContents(WidgetRef ref) {
    final cacheState = ref.read(metadataCacheProvider);
    final exported = <String, Map<String, dynamic>>{};

    for (final entry in cacheState.cache.entries) {
      exported[entry.key] = {
        'display_name': entry.value.contactModel.displayName,
        'public_key': entry.value.contactModel.publicKey,
        'cached_at': entry.value.cachedAt.toIso8601String(),
        'is_expired': entry.value.isExpired,
        'nip05': entry.value.contactModel.nip05,
        'about': entry.value.contactModel.about,
        'image_path': entry.value.contactModel.imagePath,
      };
    }

    return exported;
  }

  /// Validate public key format and normalize it
  static String? validateAndNormalizePublicKey(String publicKey) {
    final trimmed = publicKey.trim().toLowerCase();

    // Use the extension to validate the public key
    if (trimmed.isValidPublicKey) {
      return trimmed;
    }

    return null; // Invalid format
  }

  /// Check for potential metadata conflicts
  static Future<List<String>> detectMetadataConflicts(WidgetRef ref) async {
    final cacheState = ref.read(metadataCacheProvider);
    final conflicts = <String>[];
    final nameToKeys = <String, List<String>>{};

    // Group by name to find duplicates
    for (final entry in cacheState.cache.entries) {
      final displayName = entry.value.contactModel.displayName;
      if (displayName != 'Unknown User') {
        nameToKeys.putIfAbsent(displayName, () => []).add(entry.key);
      }
    }

    // Find names with multiple keys
    nameToKeys.forEach((name, keys) {
      if (keys.length > 1) {
        conflicts.add('Name "$name" maps to multiple keys: ${keys.join(", ")}');
      }
    });

    return conflicts;
  }

  /// Test the cache performance with a set of public keys
  static Future<Map<String, Duration>> benchmarkCachePerformance(
    WidgetRef ref,
    List<String> publicKeys,
  ) async {
    final cache = ref.read(metadataCacheProvider.notifier);
    final results = <String, Duration>{};

    for (final publicKey in publicKeys) {
      final stopwatch = Stopwatch()..start();

      try {
        await cache.getContactModel(publicKey);
        stopwatch.stop();
        results[publicKey] = stopwatch.elapsed;
      } catch (e) {
        stopwatch.stop();
        results[publicKey] = stopwatch.elapsed;
        _logger.warning('Benchmark failed for $publicKey: $e');
      }
    }

    return results;
  }

  /// Clear cache and start fresh (useful for testing)
  static void resetCache(WidgetRef ref) {
    final cache = ref.read(metadataCacheProvider.notifier);
    cache.clearCache();
    _logger.info('Metadata cache has been reset');
  }

  /// Get cache health report
  static Map<String, dynamic> getCacheHealthReport(WidgetRef ref) {
    final cache = ref.read(metadataCacheProvider.notifier);
    final cacheState = ref.read(metadataCacheProvider);
    final stats = cache.getCacheStats();

    final totalEntries = stats['totalCached'] as int;
    final validEntries = stats['validEntries'] as int;
    final expiredEntries = stats['expiredEntries'] as int;
    final pendingFetches = stats['pendingFetches'] as int;

    final healthScore = totalEntries > 0 ? (validEntries / totalEntries * 100).round() : 100;

    return {
      'health_score': healthScore,
      'total_entries': totalEntries,
      'valid_entries': validEntries,
      'expired_entries': expiredEntries,
      'pending_fetches': pendingFetches,
      'cache_efficiency': totalEntries > 0 ? '$validEntries/$totalEntries' : 'N/A',
      'has_errors': cacheState.error != null,
      'error_message': cacheState.error,
      'recommendations': _generateRecommendations(stats),
    };
  }

  static List<String> _generateRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];
    final totalEntries = stats['totalCached'] as int;
    final expiredEntries = stats['expiredEntries'] as int;
    final pendingFetches = stats['pendingFetches'] as int;

    if (expiredEntries > 0) {
      recommendations.add('Clean expired entries to improve performance');
    }

    if (pendingFetches > 10) {
      recommendations.add('High number of pending fetches - consider reducing concurrent requests');
    }

    if (totalEntries > 1000) {
      recommendations.add('Large cache size - consider implementing LRU eviction');
    }

    if (totalEntries == 0) {
      recommendations.add('Cache is empty - metadata will be fetched on demand');
    }

    return recommendations;
  }
}
