// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

/// Cached metadata with basic expiration
class CachedMetadata {
  final ContactModel contactModel;
  final DateTime cachedAt;
  final Duration cacheExpiry;

  const CachedMetadata({
    required this.contactModel,
    required this.cachedAt,
    this.cacheExpiry = const Duration(hours: 1),
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(cacheExpiry));
}

/// State for the metadata cache
class MetadataCacheState {
  final Map<String, CachedMetadata> cache;
  final Map<String, Future<ContactModel>> pendingFetches;
  final bool isLoading;
  final String? error;

  const MetadataCacheState({
    this.cache = const {},
    this.pendingFetches = const {},
    this.isLoading = false,
    this.error,
  });

  MetadataCacheState copyWith({
    Map<String, CachedMetadata>? cache,
    Map<String, Future<ContactModel>>? pendingFetches,
    bool? isLoading,
    String? error,
  }) {
    return MetadataCacheState(
      cache: cache ?? this.cache,
      pendingFetches: pendingFetches ?? this.pendingFetches,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for metadata cache management
class MetadataCacheNotifier extends Notifier<MetadataCacheState> {
  final _logger = Logger('MetadataCacheNotifier');

  @override
  MetadataCacheState build() => const MetadataCacheState();

  /// Normalize a public key string to consistent format
  String _normalizePublicKey(String publicKey) {
    return publicKey.trim().toLowerCase();
  }

  /// Convert hex to npub safely
  Future<String> _safeHexToNpub(String hexPubkey) async {
    try {
      return await npubFromHexPubkey(hexPubkey: hexPubkey);
    } catch (e) {
      _logger.warning('Failed to convert hex to npub for $hexPubkey: $e');
      return hexPubkey;
    }
  }

  /// Convert npub to hex safely
  Future<String> _safeNpubToHex(String npub) async {
    try {
      return await hexPubkeyFromNpub(npub: npub);
    } catch (e) {
      _logger.warning('Failed to convert npub to hex for $npub: $e');
      return npub;
    }
  }

  /// Get standardized npub format for consistent caching
  Future<String> _getStandardizedNpub(String publicKey) async {
    final normalized = _normalizePublicKey(publicKey);

    if (normalized.startsWith('npub1')) {
      return normalized;
    } else if (normalized.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(normalized)) {
      return await _safeHexToNpub(normalized);
    } else {
      _logger.warning('Unrecognized public key format: $normalized');
      return normalized;
    }
  }

  /// Fetch metadata for a public key
  Future<ContactModel> _fetchMetadataForKey(String publicKey) async {
    try {
      _logger.info('Fetching metadata for: $publicKey');

      // Convert to hex for fetching if needed
      String fetchKey = publicKey;
      if (publicKey.startsWith('npub1')) {
        fetchKey = await _safeNpubToHex(publicKey);
      }

      // Create PublicKey object and fetch metadata
      final contactPk = await publicKeyFromString(publicKeyString: fetchKey);
      final metadata = await fetchMetadata(pubkey: contactPk);

      // Get standardized npub for consistent identification
      final standardNpub = await _getStandardizedNpub(publicKey);

      // Create contact model
      final contactModel = ContactModel.fromMetadata(
        publicKey: standardNpub,
        metadata: metadata,
      );

      _logger.info('Fetched metadata for $standardNpub: ${contactModel.displayNameOrName}');
      return contactModel;
    } catch (e, st) {
      _logger.warning('Failed to fetch metadata for $publicKey: $e\n$st');

      // Create fallback contact model
      try {
        final standardNpub = await _getStandardizedNpub(publicKey);
        return ContactModel(
          name: 'Unknown User',
          publicKey: standardNpub,
        );
      } catch (fallbackError) {
        _logger.severe('Fallback failed for $publicKey: $fallbackError');
        return ContactModel(
          name: 'Unknown User',
          publicKey: _normalizePublicKey(publicKey),
        );
      }
    }
  }

  /// Get contact model from cache or fetch if needed
  Future<ContactModel> getContactModel(String publicKey) async {
    final normalizedKey = _normalizePublicKey(publicKey);
    final standardNpub = await _getStandardizedNpub(normalizedKey);

    // Check cache first
    final cached = state.cache[standardNpub];
    if (cached != null && !cached.isExpired) {
      return cached.contactModel;
    }

    // Check if we're already fetching this key
    final pendingFetch = state.pendingFetches[standardNpub];
    if (pendingFetch != null) {
      return await pendingFetch;
    }

    // Start new fetch
    final futureContactModel = _fetchMetadataForKey(normalizedKey);

    // Track pending fetch
    final newPendingFetches = Map<String, Future<ContactModel>>.from(state.pendingFetches);
    newPendingFetches[standardNpub] = futureContactModel;

    state = state.copyWith(pendingFetches: newPendingFetches);

    try {
      final contactModel = await futureContactModel;

      // Cache the result
      final newCache = Map<String, CachedMetadata>.from(state.cache);
      newCache[standardNpub] = CachedMetadata(
        contactModel: contactModel,
        cachedAt: DateTime.now(),
      );

      // Remove from pending fetches
      final updatedPendingFetches = Map<String, Future<ContactModel>>.from(state.pendingFetches);
      updatedPendingFetches.remove(standardNpub);

      state = state.copyWith(
        cache: newCache,
        pendingFetches: updatedPendingFetches,
      );

      return contactModel;
    } catch (e) {
      _logger.warning('Fetch failed for $standardNpub: $e');

      // Remove from pending fetches on error
      final updatedPendingFetches = Map<String, Future<ContactModel>>.from(state.pendingFetches);
      updatedPendingFetches.remove(standardNpub);

      state = state.copyWith(
        pendingFetches: updatedPendingFetches,
        error: 'Failed to fetch metadata for $standardNpub: $e',
      );

      rethrow;
    }
  }

  /// Bulk populate cache from queryContacts results
  Future<void> bulkPopulateFromQueryResults(
    Map<PublicKey, MetadataData?> queryResults,
  ) async {
    _logger.info('Bulk populating cache from ${queryResults.length} query results');

    final newCache = Map<String, CachedMetadata>.from(state.cache);
    int populated = 0;
    int skipped = 0;

    for (final entry in queryResults.entries) {
      try {
        final publicKey = entry.key;
        final metadata = entry.value;

        // Convert PublicKey to standardized npub format
        final npub = await npubFromPublicKey(publicKey: publicKey);
        final standardNpub = _normalizePublicKey(npub);

        // Check if we already have fresh cache data
        final existing = newCache[standardNpub];
        if (existing != null && !existing.isExpired) {
          skipped++;
          continue;
        }

        // Create contact model
        final contactModel = ContactModel.fromMetadata(
          publicKey: standardNpub,
          metadata: metadata,
        );

        // Cache the result
        newCache[standardNpub] = CachedMetadata(
          contactModel: contactModel,
          cachedAt: DateTime.now(),
        );

        populated++;
      } catch (e) {
        _logger.warning('Failed to bulk cache entry: $e');
      }
    }

    // Update cache state
    state = state.copyWith(cache: newCache);

    _logger.info('Bulk population complete - populated: $populated, skipped: $skipped');
  }

  /// Get multiple contact models efficiently
  Future<List<ContactModel>> getContactModels(List<String> publicKeys) async {
    final results = <ContactModel>[];

    for (final publicKey in publicKeys) {
      try {
        final contactModel = await getContactModel(publicKey);
        results.add(contactModel);
      } catch (e) {
        _logger.warning('Failed to get contact model for $publicKey: $e');
        // Add fallback model to maintain list integrity
        results.add(
          ContactModel(
            name: 'Unknown User',
            publicKey: _normalizePublicKey(publicKey),
          ),
        );
      }
    }

    return results;
  }

  /// Check if a contact is cached and not expired
  bool isContactCached(String publicKey) {
    final normalizedKey = _normalizePublicKey(publicKey);
    final cached = state.cache[normalizedKey];
    return cached != null && !cached.isExpired;
  }

  /// Clear expired entries from cache
  void cleanExpiredEntries() {
    final newCache = <String, CachedMetadata>{};

    for (final entry in state.cache.entries) {
      if (!entry.value.isExpired) {
        newCache[entry.key] = entry.value;
      }
    }

    if (newCache.length != state.cache.length) {
      _logger.info('Cleaned ${state.cache.length - newCache.length} expired cache entries');
      state = state.copyWith(cache: newCache);
    }
  }

  /// Clear all cached metadata
  void clearCache() {
    _logger.info('Clearing all metadata cache');
    state = state.copyWith(cache: {});
  }

  /// Update cache with new metadata
  void updateCachedMetadata(String publicKey, ContactModel contactModel) {
    final normalizedKey = _normalizePublicKey(publicKey);

    final newCache = Map<String, CachedMetadata>.from(state.cache);
    newCache[normalizedKey] = CachedMetadata(
      contactModel: contactModel,
      cachedAt: DateTime.now(),
    );

    state = state.copyWith(cache: newCache);
    _logger.info('Updated cached metadata for $normalizedKey');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final total = state.cache.length;
    final expired = state.cache.values.where((entry) => entry.isExpired).length;
    final pending = state.pendingFetches.length;

    return {
      'totalCached': total,
      'expiredEntries': expired,
      'validEntries': total - expired,
      'pendingFetches': pending,
    };
  }
}

// Riverpod provider
final metadataCacheProvider = NotifierProvider<MetadataCacheNotifier, MetadataCacheState>(
  MetadataCacheNotifier.new,
);
