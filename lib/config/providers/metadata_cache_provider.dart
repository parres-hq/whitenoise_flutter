// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

/// Cached metadata entry with expiry information
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

  // Track metadata signatures to detect Rust-level duplicates
  final Map<String, String> _metadataSignatureToFirstKey = {};

  @override
  MetadataCacheState build() => const MetadataCacheState();

  /// Normalize a public key string to consistent format (removes extra spaces, converts to lowercase)
  String _normalizePublicKey(String publicKey) {
    return publicKey.trim().toLowerCase();
  }

  /// Convert hex to npub safely with caching
  Future<String> _safeHexToNpub(String hexPubkey) async {
    try {
      // Try direct conversion first
      return await npubFromHexPubkey(hexPubkey: hexPubkey);
    } catch (e) {
      _logger.warning('Failed to convert hex to npub for $hexPubkey: $e');
      // Return the original hex if conversion fails
      return hexPubkey;
    }
  }

  /// Convert npub to hex safely
  Future<String> _safeNpubToHex(String npub) async {
    try {
      return await hexPubkeyFromNpub(npub: npub);
    } catch (e) {
      _logger.warning('Failed to convert npub to hex for $npub: $e');
      // Return the original npub if conversion fails
      return npub;
    }
  }

  /// Create a unique signature for metadata to detect duplicates
  String _createMetadataSignature(MetadataData? metadata) {
    if (metadata == null) return 'NULL_METADATA';

    // Create a signature based on key fields
    return '${metadata.name ?? ""}|${metadata.displayName ?? ""}|${metadata.picture ?? ""}|${metadata.nip05 ?? ""}';
  }

  /// Check for and handle duplicate metadata from Rust layer
  bool _detectAndHandleRustDuplicate(String fetchKey, MetadataData? metadata) {
    final signature = _createMetadataSignature(metadata);

    // Skip duplicate check for null metadata - those should always be "Unknown User"
    if (metadata == null) {
      return false;
    }

    // Check if we've seen this exact metadata signature for a different key
    final firstKeyWithSignature = _metadataSignatureToFirstKey[signature];

    if (firstKeyWithSignature != null && firstKeyWithSignature != fetchKey) {
      _logger.warning('⚠️ RUST DUPLICATE DETECTED: Same metadata signature for different keys:');
      _logger.warning('   📝 Signature: $signature');
      _logger.warning('   🔑 First key: $firstKeyWithSignature');
      _logger.warning('   🔑 Current key: $fetchKey');
      _logger.warning(
        '   🚨 This indicates a bug in the Rust fetchMetadata function - applying mitigation',
      );

      // This is a duplicate from Rust - return true to force "Unknown User"
      return true;
    }

    // Track this signature for future duplicate detection
    _metadataSignatureToFirstKey[signature] = fetchKey;
    return false;
  }

  /// Get standardized npub from any public key format
  Future<String> _getStandardizedNpub(String publicKey) async {
    final normalized = _normalizePublicKey(publicKey);

    if (normalized.startsWith('npub1')) {
      return normalized;
    } else if (normalized.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(normalized)) {
      // It's a hex key
      return await _safeHexToNpub(normalized);
    } else {
      _logger.warning('Unrecognized public key format: $normalized');
      return normalized;
    }
  }

  /// Fetch metadata for a public key with proper error handling and no object disposal issues
  Future<ContactModel> _fetchMetadataForKey(String publicKey) async {
    try {
      _logger.info('🔍 MetadataCache: Fetching metadata for: $publicKey');

      // Convert to standard format for fetching
      String fetchKey = publicKey;
      if (publicKey.startsWith('npub1')) {
        fetchKey = await _safeNpubToHex(publicKey);
        _logger.info(
          '🔄 MetadataCache: Converted npub to hex for fetching: $publicKey -> $fetchKey',
        );
      }

      // Create fresh PublicKey object for metadata fetching
      final contactPk = await publicKeyFromString(publicKeyString: fetchKey);
      _logger.info('✅ MetadataCache: Created PublicKey object for: $fetchKey');

      final metadata = await fetchMetadata(pubkey: contactPk);
      _logger.info(
        '📥 MetadataCache: Raw fetchMetadata result for $fetchKey: ${metadata == null ? "NULL" : "NON-NULL"}',
      );

      // RUST DUPLICATE DETECTION: Check if this metadata is duplicated from another key
      final isRustDuplicate = _detectAndHandleRustDuplicate(fetchKey, metadata);

      // CRITICAL DEBUG: Log exact metadata response for investigation
      if (metadata != null) {
        _logger.info('🔬 MetadataCache: ✅ METADATA FOUND for $fetchKey:');
        _logger.info('   - name: "${metadata.name}"');
        _logger.info('   - displayName: "${metadata.displayName}"');
        _logger.info('   - picture: "${metadata.picture}"');
        _logger.info('   - about: "${metadata.about}"');
        _logger.info('   - website: "${metadata.website}"');
        _logger.info('   - nip05: "${metadata.nip05}"');
        _logger.info('   - lud16: "${metadata.lud16}"');

        if (isRustDuplicate) {
          _logger.warning(
            '🛡️ MITIGATION: Forcing "Unknown User" for duplicate metadata from Rust',
          );
        }
      } else {
        _logger.info('🚨 MetadataCache: ❌ NULL METADATA for $fetchKey - NO KIND:0 EVENT FOUND');
      }

      // Get the standardized npub for consistent identification
      final standardNpub = await _getStandardizedNpub(publicKey);
      _logger.info('🎯 MetadataCache: Standardized key: $publicKey -> $standardNpub');

      // If Rust returned duplicate metadata, treat it as null to force "Unknown User"
      final effectiveMetadata = isRustDuplicate ? null : metadata;

      final contactModel = ContactModel.fromMetadata(
        publicKey: standardNpub,
        metadata: effectiveMetadata,
      );

      // VALIDATION: Log warning if null metadata doesn't result in "Unknown User"
      if (effectiveMetadata == null && contactModel.name != 'Unknown User') {
        _logger.warning(
          '⚠️ METADATA VALIDATION: NULL effective metadata but contact name is "${contactModel.name}" instead of "Unknown User" for $fetchKey',
        );
        _logger.warning(
          '⚠️ This may indicate metadata contamination - but continuing with mitigation in place',
        );
        // Continue with the contactModel as-is since our mitigation should have handled this
      }

      _logger.info(
        '✅ MetadataCache: Created ContactModel for $standardNpub: ${contactModel.displayNameOrName} (key: ${contactModel.publicKey})',
      );
      return contactModel;
    } catch (e, st) {
      _logger.warning('❌ MetadataCache: Failed to fetch metadata for $publicKey: $e\n$st');

      // Create fallback contact model with standardized npub
      try {
        final standardNpub = await _getStandardizedNpub(publicKey);
        _logger.info('⚠️ MetadataCache: Creating fallback contact for $standardNpub');
        return ContactModel(
          name: 'Unknown User',
          publicKey: standardNpub,
        );
      } catch (fallbackError) {
        _logger.severe('💥 MetadataCache: Even fallback failed for $publicKey: $fallbackError');
        return ContactModel(
          name: 'Unknown User',
          publicKey: _normalizePublicKey(publicKey),
        );
      }
    }
  }

  /// Get contact model from cache or fetch if needed
  Future<ContactModel> getContactModel(String publicKey) async {
    _logger.info('🎯 MetadataCache: getContactModel called with: $publicKey');

    final normalizedKey = _normalizePublicKey(publicKey);
    _logger.info('🔧 MetadataCache: Normalized key: $publicKey -> $normalizedKey');

    final standardNpub = await _getStandardizedNpub(normalizedKey);
    _logger.info('📝 MetadataCache: Standardized npub: $normalizedKey -> $standardNpub');

    // Check cache first
    final cached = state.cache[standardNpub];
    if (cached != null && !cached.isExpired) {
      _logger.info(
        '💚 MetadataCache: Using cached metadata for $standardNpub -> ${cached.contactModel.displayNameOrName}',
      );
      return cached.contactModel;
    }

    // Check if we're already fetching this key
    final pendingFetch = state.pendingFetches[standardNpub];
    if (pendingFetch != null) {
      _logger.info('⏳ MetadataCache: Using pending fetch for $standardNpub');
      return await pendingFetch;
    }

    // Start new fetch
    _logger.info('🚀 MetadataCache: Starting new metadata fetch for $standardNpub');
    final futureContactModel = _fetchMetadataForKey(normalizedKey);

    // Track pending fetch
    final newPendingFetches = Map<String, Future<ContactModel>>.from(state.pendingFetches);
    newPendingFetches[standardNpub] = futureContactModel;

    state = state.copyWith(pendingFetches: newPendingFetches);

    try {
      final contactModel = await futureContactModel;
      _logger.info(
        '🎉 MetadataCache: Fetch completed for $standardNpub -> ${contactModel.displayNameOrName} (key: ${contactModel.publicKey})',
      );

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

      _logger.info('💾 MetadataCache: Cached result for $standardNpub');
      return contactModel;
    } catch (e) {
      _logger.warning('❌ MetadataCache: Fetch failed for $standardNpub: $e');

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

  /// Get multiple contact models efficiently (batch operation)
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

    // Only check direct match - no fuzzy matching that could cause collisions
    final cached = state.cache[normalizedKey];
    if (cached != null && !cached.isExpired) {
      return true;
    }

    // Check if we have it under npub format if input was hex
    if (normalizedKey.length == 64 && RegExp(r'^[0-9a-f]+$').hasMatch(normalizedKey)) {
      // Search for npub version in cache keys
      for (final cacheKey in state.cache.keys) {
        if (cacheKey.startsWith('npub1')) {
          // Do not try to convert - just check if this could be the same user
          // For now, just return false to force a proper lookup
        }
      }
    }

    return false;
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

  /// Update cache with new metadata (useful when metadata is updated)
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

  /// DEBUG: Print cache contents for debugging duplicate metadata issues
  void debugPrintCacheContents() {
    _logger.info('🔍 DEBUG: Cache Contents (${state.cache.length} entries):');

    final nameToKeys = <String, List<String>>{};

    for (final entry in state.cache.entries) {
      final key = entry.key;
      final cached = entry.value;
      final contact = cached.contactModel;
      final displayName = contact.displayNameOrName;

      _logger.info('🔍 Cache Entry: $key -> $displayName (expired: ${cached.isExpired})');

      // Track names to keys for duplicate detection
      nameToKeys.putIfAbsent(displayName, () => []).add(key);
    }

    // Check for duplicates in cache
    for (final entry in nameToKeys.entries) {
      if (entry.value.length > 1 && entry.key != 'Unknown User') {
        _logger.severe('🔍 CACHE DUPLICATE: Name "${entry.key}" cached under keys: ${entry.value}');
      }
    }

    _logger.info('🔍 Pending fetches: ${state.pendingFetches.keys.toList()}');
  }

  /// DEBUG: Get all cached contact models with their keys
  List<MapEntry<String, ContactModel>> getAllCachedContacts() {
    return state.cache.entries
        .where((entry) => !entry.value.isExpired)
        .map((entry) => MapEntry(entry.key, entry.value.contactModel))
        .toList();
  }
}

// Riverpod provider
final metadataCacheProvider = NotifierProvider<MetadataCacheNotifier, MetadataCacheState>(
  MetadataCacheNotifier.new,
);
