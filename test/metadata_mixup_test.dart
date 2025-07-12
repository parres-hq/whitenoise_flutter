/// Test to reproduce and fix the specific metadata mixup issue
///
/// Issue: npub1zzmxvr9sw49lhzfx236aweurt8h5tmzjw7x3gfsazlgd8j64ql0sexw5wy (SoapMiner metadata)
///        being associated with npub1zymqqmvktw8lkr5dp6zzw5xk3fkdqcynj4l3f080k3amy28ses6setzznv
library;

import 'dart:developer' as dev;

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

void main() {
  group('Metadata Mixup Investigation', () {
    // The specific npubs from the user's report
    const String soapMinerNpub = 'npub1zzmxvr9sw49lhzfx236aweurt8h5tmzjw7x3gfsazlgd8j64ql0sexw5wy';
    const String wrongNpub = 'npub1zymqqmvktw8lkr5dp6zzw5xk3fkdqcynj4l3f080k3amy28ses6setzznv';

    late MetadataCacheNotifier cacheNotifier;

    setUp(() {
      cacheNotifier = MetadataCacheNotifier();
    });

    test('Investigate npub to hex conversion consistency', () async {
      // Test if there's any issue with npub-to-hex conversions

      try {
        final soapMinerHex = await hexPubkeyFromNpub(npub: soapMinerNpub);
        final wrongHex = await hexPubkeyFromNpub(npub: wrongNpub);

        dev.log('🔬 SoapMiner npub: $soapMinerNpub');
        dev.log('🔬 SoapMiner hex:  $soapMinerHex');
        dev.log('🔬 Wrong npub:     $wrongNpub');
        dev.log('🔬 Wrong hex:      $wrongHex');

        // Verify they're different
        expect(soapMinerHex, isNot(equals(wrongHex)));
        expect(soapMinerNpub, isNot(equals(wrongNpub)));

        // Verify round-trip conversion
        final soapMinerNpubRoundTrip = await npubFromHexPubkey(hexPubkey: soapMinerHex);
        final wrongNpubRoundTrip = await npubFromHexPubkey(hexPubkey: wrongHex);

        dev.log('🔄 SoapMiner round-trip: $soapMinerNpubRoundTrip');
        dev.log('🔄 Wrong round-trip:     $wrongNpubRoundTrip');

        expect(soapMinerNpubRoundTrip, equals(soapMinerNpub));
        expect(wrongNpubRoundTrip, equals(wrongNpub));
      } catch (e) {
        dev.log('❌ Conversion test failed: $e');
        fail('Failed to convert npubs: $e');
      }
    });

    test('Test individual metadata fetching for both npubs', () async {
      dev.log('🚀 Testing individual metadata fetching...');

      try {
        // Fetch metadata for both npubs individually
        final soapMinerContact = await cacheNotifier.getContactModel(soapMinerNpub);
        dev.log(
          '🔬 SoapMiner result: ${soapMinerContact.displayNameOrName} (key: ${soapMinerContact.publicKey})',
        );

        final wrongContact = await cacheNotifier.getContactModel(wrongNpub);
        dev.log(
          '🔬 Wrong result: ${wrongContact.displayNameOrName} (key: ${wrongContact.publicKey})',
        );

        // Verify the contacts have different metadata if they should
        if (soapMinerContact.displayNameOrName == wrongContact.displayNameOrName &&
            soapMinerContact.displayNameOrName != 'Unknown User') {
          dev.log(
            '🚨 METADATA MIXUP DETECTED: Both npubs have same name: ${soapMinerContact.displayNameOrName}',
          );

          // This is the bug - let's diagnose it
          expect(soapMinerContact.publicKey, equals(soapMinerNpub.toLowerCase()));
          expect(wrongContact.publicKey, equals(wrongNpub.toLowerCase()));

          // Check cache state
          cacheNotifier.debugPrintCacheContents();

          fail(
            'Metadata mixup detected: both different npubs have same name "${soapMinerContact.displayNameOrName}"',
          );
        } else {
          dev.log('✅ No metadata mixup detected in this test');
        }
      } catch (e) {
        dev.log('❌ Individual metadata test failed: $e');
        fail('Failed to fetch individual metadata: $e');
      }
    });

    test('Test cache collision detection with similar keys', () async {
      dev.log('🚀 Testing cache collision detection...');

      try {
        // Test basic string operations that might cause issues
        final soapMinerLower = soapMinerNpub.trim().toLowerCase();
        final wrongLower = wrongNpub.trim().toLowerCase();

        final soapMinerHashCode = soapMinerLower.hashCode;
        final wrongHashCode = wrongLower.hashCode;

        dev.log('🔢 SoapMiner normalized: $soapMinerLower');
        dev.log('🔢 SoapMiner hashCode: $soapMinerHashCode');
        dev.log('🔢 Wrong normalized: $wrongLower');
        dev.log('🔢 Wrong hashCode: $wrongHashCode');

        if (soapMinerHashCode == wrongHashCode) {
          dev.log('🚨 HASHCODE COLLISION: Different npubs have same Dart hashCode!');
          fail('HashCode collision detected: $soapMinerHashCode for both different keys');
        } else {
          dev.log('✅ No basic hashCode collision detected');
        }

        // Test if the strings are similar enough to potentially cause issues
        final similarity = _calculateStringSimilarity(soapMinerNpub, wrongNpub);
        dev.log('🔍 String similarity: ${(similarity * 100).toStringAsFixed(1)}%');

        if (similarity > 0.8) {
          dev.log('⚠️ Very similar npubs - this might cause confusion in logs');
        }
      } catch (e) {
        dev.log('❌ Collision detection test failed: $e');
        fail('Failed collision detection test: $e');
      }
    });

    test('Test Rust metadata fetching directly', () async {
      dev.log('🚀 Testing direct Rust metadata fetching...');

      try {
        // Convert to hex for direct Rust API calls
        final soapMinerHex = await hexPubkeyFromNpub(npub: soapMinerNpub);
        final wrongHex = await hexPubkeyFromNpub(npub: wrongNpub);

        // Create PublicKey objects and fetch metadata directly from Rust
        final soapMinerPk = await publicKeyFromString(publicKeyString: soapMinerHex);
        final wrongPk = await publicKeyFromString(publicKeyString: wrongHex);

        final soapMinerMetadata = await fetchMetadata(pubkey: soapMinerPk);
        final wrongMetadata = await fetchMetadata(pubkey: wrongPk);

        dev.log('🔬 SoapMiner Rust metadata: ${soapMinerMetadata?.name ?? "NULL"}');
        dev.log('🔬 Wrong Rust metadata: ${wrongMetadata?.name ?? "NULL"}');

        // Check if Rust is returning the same metadata for different keys
        if (soapMinerMetadata != null && wrongMetadata != null) {
          if (soapMinerMetadata.name == wrongMetadata.name &&
              soapMinerMetadata.displayName == wrongMetadata.displayName &&
              soapMinerMetadata.picture == wrongMetadata.picture) {
            dev.log(
              '🚨 RUST DUPLICATE BUG DETECTED: Same metadata for different keys from Rust layer!',
            );
            dev.log('  Name: ${soapMinerMetadata.name}');
            dev.log('  DisplayName: ${soapMinerMetadata.displayName}');
            dev.log('  Picture: ${soapMinerMetadata.picture}');

            // This confirms the bug is in the Rust layer
            fail('Rust layer returning identical metadata for different keys');
          } else {
            dev.log('✅ Rust layer returning different metadata for different keys');
          }
        } else {
          dev.log('ℹ️ One or both npubs have NULL metadata from Rust');
          if (soapMinerMetadata == null) dev.log('  SoapMiner: NULL');
          if (wrongMetadata == null) dev.log('  Wrong: NULL');
        }
      } catch (e) {
        dev.log('❌ Direct Rust test failed: $e');
        fail('Failed direct Rust metadata test: $e');
      }
    });

    test('Test metadata signature detection', () async {
      dev.log('🚀 Testing metadata signature detection...');

      try {
        // Test if our duplicate detection would catch this issue
        final soapMinerContact = await cacheNotifier.getContactModel(soapMinerNpub);
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay
        final wrongContact = await cacheNotifier.getContactModel(wrongNpub);

        if (soapMinerContact.displayNameOrName == wrongContact.displayNameOrName &&
            soapMinerContact.displayNameOrName != 'Unknown User') {
          dev.log('🔍 Detected potential duplicate: ${soapMinerContact.displayNameOrName}');

          // Print all cache entries to see the state
          cacheNotifier.debugPrintCacheContents();

          // This should have been caught by our duplicate detection
          dev.log('⚠️ Duplicate detection may have failed or this is a new issue');
        }
      } catch (e) {
        dev.log('❌ Signature detection test failed: $e');
        fail('Failed signature detection test: $e');
      }
    });
  });
}

/// Helper function to calculate string similarity (simple)
double _calculateStringSimilarity(String a, String b) {
  if (a == b) return 1.0;

  final longer = a.length > b.length ? a : b;
  final shorter = a.length > b.length ? b : a;

  if (longer.isEmpty) return 1.0;

  final editDistance = _calculateLevenshteinDistance(longer, shorter);
  return (longer.length - editDistance) / longer.length;
}

/// Helper function to calculate Levenshtein distance
int _calculateLevenshteinDistance(String a, String b) {
  final List<List<int>> matrix = List.generate(
    a.length + 1,
    (i) => List.generate(b.length + 1, (j) => 0),
  );

  for (int i = 0; i <= a.length; i++) {
    matrix[i][0] = i;
  }

  for (int j = 0; j <= b.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost, // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[a.length][b.length];
}
