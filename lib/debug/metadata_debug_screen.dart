/// Debug utilities for investigating metadata cache issues
///
/// Add this to your app temporarily to debug the contact mix-up issue
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';

class MetadataDebugScreen extends ConsumerWidget {
  const MetadataDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheState = ref.watch(metadataCacheProvider);
    final contactsState = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metadata Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cache Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Statistics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Total Cached: ${cacheState.cache.length}'),
                    Text('Pending Fetches: ${cacheState.pendingFetches.length}'),
                    Text('Has Error: ${cacheState.error != null}'),
                    if (cacheState.error != null)
                      Text('Error: ${cacheState.error}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cache Contents
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Contents',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ...cacheState.cache.entries.map((entry) {
                      final contact = entry.value.contactModel;
                      final isExpired = entry.value.isExpired;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isExpired ? Colors.red : Colors.green,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${contact.displayNameOrName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Cache Key: ${entry.key}'),
                            Text('Contact Key: ${contact.publicKey}'),
                            Text('Expired: $isExpired'),
                            Text('Cached: ${entry.value.cachedAt}'),
                            if (entry.key != contact.publicKey.toLowerCase())
                              const Text('⚠️ KEY MISMATCH!', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contacts List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Contacts (${contactsState.contactModels?.length ?? 0})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (contactsState.contactModels != null) ...[
                      ...contactsState.contactModels!.asMap().entries.map((entry) {
                        final index = entry.key;
                        final contact = entry.value;

                        // Check for potential duplicates
                        final duplicates =
                            contactsState.contactModels!
                                .where(
                                  (c) =>
                                      c.displayNameOrName == contact.displayNameOrName &&
                                      c.publicKey != contact.publicKey,
                                )
                                .toList();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: duplicates.isNotEmpty ? Colors.red : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$index: ${contact.displayNameOrName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Key: ${contact.publicKey}'),
                              if (contact.nip05 != null) Text('NIP05: ${contact.nip05}'),
                              if (duplicates.isNotEmpty)
                                Text(
                                  '🚨 ${duplicates.length} others with same name!',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Actions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ref.read(metadataCacheProvider.notifier).clearCache();
                          },
                          child: const Text('Clear Cache'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(metadataCacheProvider.notifier).cleanExpiredEntries();
                          },
                          child: const Text('Clean Expired'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        // Force reload contacts
                        final activeAccount =
                            await ref.read(activeAccountProvider.notifier).getActiveAccountData();
                        if (activeAccount != null) {
                          await ref
                              .read(contactsProvider.notifier)
                              .loadContacts(activeAccount.pubkey);
                        }
                      },
                      child: const Text('Reload Contacts'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show debug screen
void showMetadataDebugScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const MetadataDebugScreen(),
    ),
  );
}
