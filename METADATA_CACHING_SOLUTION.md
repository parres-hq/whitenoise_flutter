# Metadata Caching Solution for Contact Profile Mix-ups

## Problem Description

The app was experiencing critical issues where contact profiles were displaying incorrect information:
- Same avatar and name appearing for different npub values
- "Unknown User" and default avatars not showing when there was no metadata
- Instead, users saw other users' metadata incorrectly associated with different npubs

This was happening due to:
1. **No proper metadata caching strategy** - Fetching on-demand without consistency
2. **PublicKey object reuse issues** - Leading to DroppableDisposedException errors
3. **Inconsistent npub/pubkey usage** - Some places using hashCode.toString() as temp IDs
4. **No deduplication at metadata level** - Same users appearing with different identifiers

## Solution Overview

Implemented a comprehensive **string-based metadata caching system** that ensures:
- ✅ Each npub/hex maps to exactly ONE ContactModel
- ✅ Consistent string-based keys prevent object disposal issues
- ✅ Proper fallback to "Unknown User" when metadata is unavailable
- ✅ Efficient caching with expiry and cleanup mechanisms

## Implementation Details

### 1. MetadataCacheProvider (`lib/config/providers/metadata_cache_provider.dart`)

**Core Features:**
- **String-based caching** using standardized npub format as keys
- **Automatic normalization** between hex and npub formats
- **1-hour cache expiry** with automatic cleanup
- **Pending fetch tracking** prevents duplicate concurrent requests
- **Error handling** with fallback to "Unknown User"

**Key Methods:**
```dart
// Get contact model from cache or fetch if needed
Future<ContactModel> getContactModel(String publicKey)

// Batch operation for multiple contacts
Future<List<ContactModel>> getContactModels(List<String> publicKeys)

// Check cache status before expensive operations
bool isContactCached(String publicKey)

// Update cache when metadata changes
void updateCachedMetadata(String publicKey, ContactModel contactModel)
```

### 2. Updated ContactsProvider

**Changes:**
- Now uses MetadataCacheProvider for consistent metadata handling
- Batch metadata fetching for improved performance
- Proper npub/hex key conversion and validation
- Integration with existing contacts loading system

### 3. Updated UI Components

**NewChatBottomSheet:**
- Uses metadata cache for search results
- Consistent contact model creation
- Proper support contact handling

**SearchChatBottomSheet:**
- Import added for future integration
- Ready for cache implementation

### 4. Utility Files

**Examples** (`lib/examples/metadata_cache_examples.dart`):
- Best practices for using the cache
- Widget examples showing proper integration
- Do's and Don'ts for preventing mix-ups

**Utils** (`lib/utils/metadata_cache_utils.dart`):
- Debug utilities for cache monitoring
- Performance benchmarking tools
- Cache health reporting
- Migration and validation helpers

## Key Benefits

### 🔒 **Data Integrity**
- No more user metadata mix-ups
- Each npub maps to exactly one ContactModel
- Proper isolation between different users

### ⚡ **Performance**
- 1-hour caching reduces network requests
- Batch operations for multiple contacts
- Efficient deduplication

### 🛠 **Developer Experience**
- Clear separation of concerns
- Easy debugging with cache utilities
- Comprehensive logging and monitoring

### 🐛 **Bug Prevention**
- Eliminates PublicKey disposal issues
- Consistent string-based identification
- Proper error handling and fallbacks

## Usage Examples

### Basic Contact Display
```dart
// ✅ DO: Use metadata cache
final contact = await ref.read(metadataCacheProvider.notifier)
    .getContactModel(publicKey);

// ❌ DON'T: Create manually
final contact = ContactModel.fromMetadata(
    publicKey: publicKey.hashCode.toString(), // Can cause collisions!
    metadata: metadata,
);
```

### Batch Operations
```dart
// ✅ Efficient batch loading
final contacts = await metadataCache.getContactModels(publicKeys);

// ❌ Individual fetches in loop
for (final key in publicKeys) {
    final contact = await fetchMetadata(key); // Expensive!
}
```

### Cache Management
```dart
// Check cache status
if (metadataCache.isContactCached(publicKey)) {
    // Skip expensive operation
}

// Clean up periodically
metadataCache.cleanExpiredEntries();

// Debug cache health
final stats = metadataCache.getCacheStats();
```

## Migration Guide

### For Existing Code

1. **Replace direct metadata fetching:**
   ```dart
   // OLD
   final metadata = await fetchMetadata(pubkey: contactPk);
   final contact = ContactModel.fromMetadata(publicKey: key, metadata: metadata);
   
   // NEW
   final contact = await ref.read(metadataCacheProvider.notifier)
       .getContactModel(key);
   ```

2. **Update contact lists:**
   ```dart
   // OLD
   final contacts = rawContacts.map((entry) => 
       ContactModel.fromMetadata(publicKey: entry.key.hashCode.toString(), metadata: entry.value)
   ).toList();
   
   // NEW
   final publicKeys = rawContacts.keys.map((pk) => npubFromPublicKey(pk)).toList();
   final contacts = await metadataCache.getContactModels(publicKeys);
   ```

### Testing Recommendations

1. **Use debug utilities:**
   ```dart
   MetadataCacheUtils.logCacheStats(ref);
   final issues = await MetadataCacheUtils.validateContactConsistency(ref, publicKeys);
   ```

2. **Monitor cache health:**
   ```dart
   final health = MetadataCacheUtils.getCacheHealthReport(ref);
   ```

3. **Performance testing:**
   ```dart
   final benchmarks = await MetadataCacheUtils.benchmarkCachePerformance(ref, publicKeys);
   ```

## Future Enhancements

1. **Persistence** - Save cache to disk for app restarts
2. **LRU Eviction** - Better memory management for large contact lists
3. **Background Refresh** - Proactive metadata updates
4. **Conflict Resolution** - Handle metadata changes gracefully
5. **Offline Support** - Better fallbacks when network is unavailable

## Conclusion

This metadata caching solution provides a robust foundation for consistent contact handling throughout the app. It eliminates the critical bug where users saw incorrect profile information while providing performance benefits and a better developer experience.

The string-based approach ensures that each user's metadata is properly isolated and consistently associated with their correct npub/hex identifier, preventing the mix-ups that were occurring with the previous object-based system.
