/// Example usage of MetadataCacheProvider throughout the app
///
/// This file shows different ways to integrate the metadata cache provider
/// to ensure consistent metadata handling and avoid the issues with mixed
/// user metadata that were occurring.
library;

// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';

/// Example 1: Widget that displays contact metadata safely
class SafeContactDisplay extends ConsumerWidget {
  final String publicKey;

  const SafeContactDisplay({
    required this.publicKey,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ContactModel>(
      future: ref.read(metadataCacheProvider.notifier).getContactModel(publicKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return const Text('Error loading contact');
        }

        final contact = snapshot.data;
        if (contact == null) {
          return const Text('Unknown User');
        }

        return Column(
          children: [
            Text(contact.displayName),
            Text(contact.publicKey),
            if (contact.nip05 != null) Text(contact.nip05!),
          ],
        );
      },
    );
  }
}

/// Example 2: Service class for metadata operations
class MetadataService {
  final WidgetRef ref;

  MetadataService(this.ref);

  /// Get a contact model safely with caching
  Future<ContactModel> getContact(String publicKey) async {
    final cache = ref.read(metadataCacheProvider.notifier);
    return await cache.getContactModel(publicKey);
  }

  /// Check if metadata is cached before expensive operations
  bool isContactCached(String publicKey) {
    final cache = ref.read(metadataCacheProvider.notifier);
    return cache.isContactCached(publicKey);
  }

  /// Get multiple contacts efficiently
  Future<List<ContactModel>> getMultipleContacts(List<String> publicKeys) async {
    final cache = ref.read(metadataCacheProvider.notifier);
    return await cache.getContactModels(publicKeys);
  }

  /// Update metadata when user profile changes
  void updateContactMetadata(String publicKey, ContactModel newContact) {
    final cache = ref.read(metadataCacheProvider.notifier);
    cache.updateCachedMetadata(publicKey, newContact);
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    final cache = ref.read(metadataCacheProvider.notifier);
    return cache.getCacheStats();
  }

  /// Clean up expired entries (call periodically)
  void cleanupCache() {
    final cache = ref.read(metadataCacheProvider.notifier);
    cache.cleanExpiredEntries();
  }
}

/// Example 3: Usage in a StatefulWidget
class ContactListExample extends ConsumerStatefulWidget {
  final List<String> contactKeys;

  const ContactListExample({
    required this.contactKeys,
    super.key,
  });

  @override
  ConsumerState<ContactListExample> createState() => _ContactListExampleState();
}

class _ContactListExampleState extends ConsumerState<ContactListExample> {
  List<ContactModel>? contacts;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final cache = ref.read(metadataCacheProvider.notifier);
      final loadedContacts = await cache.getContactModels(widget.contactKeys);

      if (mounted) {
        setState(() {
          contacts = loadedContacts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts == null || contacts!.isEmpty) {
      return const Center(child: Text('No contacts'));
    }

    return ListView.builder(
      itemCount: contacts!.length,
      itemBuilder: (context, index) {
        final contact = contacts![index];
        return ListTile(
          title: Text(contact.displayName),
          subtitle: Text(contact.publicKey),
          leading: CircleAvatar(
            backgroundImage: contact.imagePath != null ? NetworkImage(contact.imagePath!) : null,
            child: contact.imagePath == null ? Text(contact.avatarLetter) : null,
          ),
          onTap: () {
            // Handle contact tap
          },
        );
      },
    );
  }
}

/// Example 4: Debug widget to monitor cache state
class MetadataCacheDebugWidget extends ConsumerWidget {
  const MetadataCacheDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheState = ref.watch(metadataCacheProvider);
    final cache = ref.read(metadataCacheProvider.notifier);
    final stats = cache.getCacheStats();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metadata Cache Debug',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Total Cached: ${stats['totalCached']}'),
            Text('Valid Entries: ${stats['validEntries']}'),
            Text('Expired Entries: ${stats['expiredEntries']}'),
            Text('Pending Fetches: ${stats['pendingFetches']}'),
            Text('Is Loading: ${cacheState.isLoading}'),
            if (cacheState.error != null)
              Text('Error: ${cacheState.error}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => cache.cleanExpiredEntries(),
                  child: const Text('Clean Cache'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => cache.clearCache(),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 5: Best practices for preventing metadata mix-ups

class MetadataBestPractices {
  /// ✅ DO: Always use standardized public key strings
  static Future<ContactModel> getContactSafely(WidgetRef ref, String publicKey) async {
    final cache = ref.read(metadataCacheProvider.notifier);
    return await cache.getContactModel(publicKey.trim().toLowerCase());
  }

  /// ✅ DO: Check cache before making expensive operations
  static Future<void> performExpensiveOperationIfNeeded(WidgetRef ref, String publicKey) async {
    final cache = ref.read(metadataCacheProvider.notifier);

    if (!cache.isContactCached(publicKey)) {
      // Only do expensive operation if not cached
      await expensiveNetworkCall();
    }
  }

  /// ✅ DO: Update cache when metadata changes
  static Future<void> updateUserProfile(WidgetRef ref, String publicKey) async {
    // ... update profile on server ...

    // Then update local cache
    final newContact = ContactModel(
      displayName: 'Updated Name',
      publicKey: publicKey,
    );

    final cache = ref.read(metadataCacheProvider.notifier);
    cache.updateCachedMetadata(publicKey, newContact);
  }

  /// ❌ DON'T: Create contact models manually without cache
  static ContactModel createContactBadly(String publicKey) {
    // This bypasses cache and can lead to inconsistencies
    return ContactModel(
      displayName: 'Unknown User',
      publicKey: publicKey,
    );
  }

  /// ❌ DON'T: Use PublicKey.hashCode as identifier
  static String getContactIdBadly(dynamic publicKey) {
    // This can lead to collisions and inconsistent IDs
    return publicKey.hashCode.toString();
  }

  static Future<void> expensiveNetworkCall() async {
    // Simulate expensive operation
    await Future.delayed(const Duration(seconds: 2));
  }
}
