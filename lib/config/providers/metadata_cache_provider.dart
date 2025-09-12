// ignore_for_file: avoid_redundant_argument_values
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

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
      return PubkeyFormatter(pubkey: hexPubkey).toNpub() ?? '';
    } catch (e) {
      _logger.warning('Failed to convert hex to npub for $hexPubkey: $e');
      return hexPubkey;
    }
  }

  /// Convert npub to hex safely
  Future<String> _safeNpubToHex(String npub) async {
    try {
      return PubkeyFormatter(pubkey: npub).toHex() ?? '';
    } catch (e) {
      _logger.warning('Failed to convert npub to hex for $npub: $e');
      return npub;
    }
  }

  /// Get standardized npub format for consistent caching
  Future<String> _getStandardizedNpub(String publicKey) async {
    final normalized = _normalizePublicKey(publicKey);

    if (normalized.isValidNpubPublicKey) {
      return normalized;
    } else if (normalized.isValidHexPublicKey) {
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
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        throw StateError('No active account found');
      }

      final metadata = await wn_users_api.userMetadata(pubkey: fetchKey);

      // Get standardized npub for consistent identification
      final standardNpub = await _getStandardizedNpub(publicKey);

      // Create contact model
      final contactModel = ContactModel.fromMetadata(
        pubkey: standardNpub,
        metadata: metadata,
      );

      _logger.info('Fetched metadata for $standardNpub: ${contactModel.displayName}');
      return contactModel;
    } catch (e, st) {
      _logger.warning('Failed to fetch metadata for $publicKey: $e\n$st');

      // Create fallback contact model
      try {
        final standardNpub = await _getStandardizedNpub(publicKey);
        return ContactModel(
          displayName: 'Unknown User',
          publicKey: standardNpub,
        );
      } catch (fallbackError) {
        _logger.severe('Fallback failed for $publicKey: $fallbackError');
        return ContactModel(
          displayName: 'Unknown User',
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
}

// Riverpod provider
final metadataCacheProvider = NotifierProvider<MetadataCacheNotifier, MetadataCacheState>(
  MetadataCacheNotifier.new,
);
