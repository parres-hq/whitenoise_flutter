import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
import 'package:whitenoise/domain/models/avatar_color_tokens.dart';
import 'package:whitenoise/domain/services/avatar_color_service.dart';

void main() {
  group('AvatarColorProvider Tests', () {
    late ProviderContainer container;
    late AvatarColorNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(avatarColorProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('build', () {
      test('initializes with empty state', () {
        final state = container.read(avatarColorProvider);
        expect(state, isEmpty);
      });

      test('loads saved color tokens from SharedPreferences', () async {
        final testPubkey = 'npub184zv6mef94t7gzagy0tc4utgdt9kgaesdl4qazykw899kvavjz2sy8mhfh';
        final testToken = AvatarColorTokens.blue;
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);

        final tokenJson = testToken.toJson();
        SharedPreferences.setMockInitialValues({
          'avatar_colors_map': '{"$cacheKey": ${jsonEncode(tokenJson)}}',
        });

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        newContainer.read(avatarColorProvider.notifier);

        await Future.delayed(const Duration(milliseconds: 200));

        final state = newContainer.read(avatarColorProvider);
        expect(state.containsKey(cacheKey), isTrue);
        expect(state[cacheKey], testToken);
      });

      test('handles error when loading saved color tokens fails', () async {
        SharedPreferences.setMockInitialValues({
          'avatar_colors_map': 'invalid json{',
        });

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        newContainer.read(avatarColorProvider.notifier);

        await Future.delayed(const Duration(milliseconds: 200));

        final state = newContainer.read(avatarColorProvider);
        expect(state, isEmpty);
      });

      test('does not update state when loaded color tokens map is empty', () async {
        SharedPreferences.setMockInitialValues({});

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        newContainer.read(avatarColorProvider.notifier);

        await Future.delayed(const Duration(milliseconds: 200));

        final state = newContainer.read(avatarColorProvider);
        expect(state, isEmpty);
      });
    });

    group('getColorToken', () {
      test('returns cached color token if available', () async {
        final testPubkey = 'npub1test123456789';
        final testToken = AvatarColorTokens.blue;
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);

        // Manually set state with cached token
        notifier.state = {cacheKey: testToken};

        final token = await notifier.getColorToken(testPubkey);
        expect(token, testToken);
      });

      test('generates and caches new color token if not in cache', () async {
        final testPubkey = 'npub1test123456789';

        expect(container.read(avatarColorProvider), isEmpty);

        final token = await notifier.getColorToken(testPubkey);

        expect(token, isA<AvatarColorToken>());

        final cacheKey = AvatarColorService.toCacheKey(testPubkey);
        expect(container.read(avatarColorProvider).containsKey(cacheKey), isTrue);
        expect(container.read(avatarColorProvider)[cacheKey], token);
      });

      test('saves generated color token to SharedPreferences', () async {
        final testPubkey = 'npub1test123456789';

        await notifier.getColorToken(testPubkey);

        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('avatar_colors_map');
        expect(savedData, isNotNull);
        expect(savedData, isNotEmpty);
      });

      test('handles hex pubkey format', () async {
        final hexPubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';

        final token = await notifier.getColorToken(hexPubkey);

        expect(token, isA<AvatarColorToken>());

        final cacheKey = AvatarColorService.toCacheKey(hexPubkey);
        expect(container.read(avatarColorProvider).containsKey(cacheKey), isTrue);
      });

      test('returns same color token for same pubkey on subsequent calls', () async {
        final testPubkey = 'npub1test123456789';

        final token1 = await notifier.getColorToken(testPubkey);
        final token2 = await notifier.getColorToken(testPubkey);

        expect(token1, token2);
      });
    });

    group('preloadColorTokens', () {
      test('loads color tokens for multiple pubkeys', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
          'npub1test555555555',
        ];

        await notifier.preloadColorTokens(pubkeys);

        final state = container.read(avatarColorProvider);

        for (final pubkey in pubkeys) {
          final cacheKey = AvatarColorService.toCacheKey(pubkey);
          expect(state.containsKey(cacheKey), isTrue);
          expect(state[cacheKey], isA<AvatarColorToken>());
        }
      });

      test('skips already cached pubkeys', () async {
        final cachedPubkey = 'npub1cached123456';
        final newPubkey = 'npub1new123456789';
        final cachedToken = AvatarColorTokens.blue;
        final cacheKey = AvatarColorService.toCacheKey(cachedPubkey);

        notifier.state = {cacheKey: cachedToken};

        await notifier.preloadColorTokens([cachedPubkey, newPubkey]);

        final state = container.read(avatarColorProvider);

        expect(state[cacheKey], cachedToken);

        final newCacheKey = AvatarColorService.toCacheKey(newPubkey);
        expect(state.containsKey(newCacheKey), isTrue);
      });

      test('returns early when all pubkeys are already cached', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
        ];

        await notifier.preloadColorTokens(pubkeys);
        final initialState = container.read(avatarColorProvider);
        final initialSize = initialState.length;

        await notifier.preloadColorTokens(pubkeys);
        final finalState = container.read(avatarColorProvider);

        expect(finalState.length, equals(initialSize));
      });

      test('handles empty pubkey list', () async {
        await notifier.preloadColorTokens([]);

        final state = container.read(avatarColorProvider);
        expect(state, isEmpty);
      });

      test('saves all generated color tokens to SharedPreferences', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
        ];

        await notifier.preloadColorTokens(pubkeys);

        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('avatar_colors_map');
        expect(savedData, isNotNull);

        for (final pubkey in pubkeys) {
          final cacheKey = AvatarColorService.toCacheKey(pubkey);
          expect(savedData!.contains(cacheKey), isTrue);
        }
      });

      test('notifies listeners when color tokens are preloaded', () async {
        var notificationCount = 0;
        final listener = container.listen(
          avatarColorProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.preloadColorTokens(['npub1test123456789']);

        expect(notificationCount, equals(1));
        listener.close();
      });

      test('handles errors gracefully during preload', () async {
        await notifier.preloadColorTokens(['invalid_pubkey_that_might_cause_error']);

        final finalState = container.read(avatarColorProvider);
        expect(finalState, isA<Map<String, AvatarColorToken>>());
      });
    });

    group('generateRandomColorToken', () {
      test('generates a random color token', () {
        final token = notifier.generateRandomColorToken();
        expect(token, isA<AvatarColorToken>());
        expect(AvatarColorTokens.all, contains(token));
      });

      test('generates tokens from the predefined palette', () {
        final tokens = <AvatarColorToken>{};
        for (int i = 0; i < 20; i++) {
          tokens.add(notifier.generateRandomColorToken());
        }
        // Should have generated multiple different tokens
        expect(tokens.length, greaterThan(1));
        // All tokens should be from the predefined set
        for (final token in tokens) {
          expect(AvatarColorTokens.all, contains(token));
        }
      });
    });

    group('setColorTokenDirectly', () {
      test('sets color token directly for a pubkey', () async {
        final testPubkey = 'npub1test123456789';
        final testToken = AvatarColorTokens.amber;
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);

        await notifier.setColorTokenDirectly(testPubkey, testToken);

        expect(container.read(avatarColorProvider).containsKey(cacheKey), isTrue);
        expect(container.read(avatarColorProvider)[cacheKey], testToken);
      });

      test('saves color token to SharedPreferences', () async {
        final testPubkey = 'npub1test123456789';
        final testToken = AvatarColorTokens.violet;

        await notifier.setColorTokenDirectly(testPubkey, testToken);

        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('avatar_colors_map');
        expect(savedData, isNotNull);
        expect(savedData, isNotEmpty);
      });
    });

    group('clearAll', () {
      test('clears all color tokens from state', () async {
        final testPubkey = 'npub1test123456789';
        await notifier.getColorToken(testPubkey);

        expect(container.read(avatarColorProvider), isNotEmpty);

        await notifier.clearAll();

        expect(container.read(avatarColorProvider), isEmpty);
      });

      test('clears color tokens from SharedPreferences', () async {
        final testPubkey = 'npub1test123456789';
        await notifier.getColorToken(testPubkey);

        var prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('avatar_colors_map'), isNotNull);

        await notifier.clearAll();
        prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('avatar_colors_map'), isNull);
      });

      test('notifies listeners when cleared', () async {
        var notificationCount = 0;
        final listener = container.listen(
          avatarColorProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.getColorToken('npub1test123456789');
        notificationCount = 0;

        await notifier.clearAll();

        expect(notificationCount, equals(1));
        listener.close();
      });
    });

    group('AvatarColorToken theme support', () {
      test('returns correct light mode colors', () {
        final token = AvatarColorTokens.blue;
        expect(token.getSurfaceColor(Brightness.light), equals(const Color(0xFFEFF6FF)));
        expect(token.getForegroundColor(Brightness.light), equals(const Color(0xFF1E3A8A)));
        expect(token.getBorderColor(Brightness.light), equals(const Color(0xFFBFDBFE)));
      });

      test('returns correct dark mode colors', () {
        final token = AvatarColorTokens.blue;
        expect(token.getSurfaceColor(Brightness.dark), equals(const Color(0xFF172554)));
        expect(token.getForegroundColor(Brightness.dark), equals(const Color(0xFFEFF6FF)));
        expect(token.getBorderColor(Brightness.dark), equals(const Color(0xFFBFDBFE)));
      });

      test('all 12 tokens have defined light and dark colors', () {
        for (final token in AvatarColorTokens.all) {
          expect(token.getSurfaceColor(Brightness.light), isNotNull);
          expect(token.getSurfaceColor(Brightness.dark), isNotNull);
          expect(token.getForegroundColor(Brightness.light), isNotNull);
          expect(token.getForegroundColor(Brightness.dark), isNotNull);
          expect(token.getBorderColor(Brightness.light), isNotNull);
          expect(token.getBorderColor(Brightness.dark), isNotNull);
        }
      });
    });

    group('AvatarColorToken serialization', () {
      test('serializes to JSON and back', () {
        final token = AvatarColorTokens.emerald;
        final json = token.toJson();
        final deserialized = AvatarColorToken.fromJson(json);

        expect(deserialized, token);
      });

      test('all tokens serialize and deserialize correctly', () {
        for (final token in AvatarColorTokens.all) {
          final json = token.toJson();
          final deserialized = AvatarColorToken.fromJson(json);
          expect(deserialized, token);
          expect(deserialized.name, token.name);
        }
      });
    });

    group('AvatarColorService.toCacheKey', () {
      test('generates consistent cache key for npub format', () {
        final pubkey = 'npub1test123456789abcdef';
        final cacheKey1 = AvatarColorService.toCacheKey(pubkey);
        final cacheKey2 = AvatarColorService.toCacheKey(pubkey);

        expect(cacheKey1, cacheKey2);
        expect(cacheKey1, equals('npub1test123456789abcdef'));
      });

      test('generates cache key from hex pubkey', () {
        final hexPubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
        final cacheKey = AvatarColorService.toCacheKey(hexPubkey);

        expect(cacheKey, isNotEmpty);
        expect(cacheKey.length, equals(64)); // Full npub length
      });

      test('generates cache key consistently for same input', () {
        final npubPubkey = 'npub180cvv07tjdrqgzl0j7j4au0y72qcxg8aewunz3ewyv56jth72fwqer0t3s';

        final cacheKey1 = AvatarColorService.toCacheKey(npubPubkey);
        final cacheKey2 = AvatarColorService.toCacheKey(npubPubkey);

        expect(cacheKey1, cacheKey2);
        expect(cacheKey1, equals('npub180cvv07tjdrqgzl0j7j4au0y72qcxg8aewunz3ewyv56jth72fwqer0t3s'));
      });
    });

    group('integration tests', () {
      test('full workflow: generate, cache, retrieve, clear', () async {
        final testPubkey = 'npub1test123456789';

        final token1 = await notifier.getColorToken(testPubkey);
        expect(token1, isA<AvatarColorToken>());

        final token2 = await notifier.getColorToken(testPubkey);
        expect(token2, token1);

        await notifier.clearAll();
        expect(container.read(avatarColorProvider), isEmpty);

        final token3 = await notifier.getColorToken(testPubkey);
        expect(token3, isA<AvatarColorToken>());
      });

      test('persistence across provider instances', () async {
        final testPubkey = 'npub1test123456789';

        final token1 = await notifier.getColorToken(testPubkey);

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        await Future.delayed(const Duration(milliseconds: 100));

        final newNotifier = newContainer.read(avatarColorProvider.notifier);
        final token2 = await newNotifier.getColorToken(testPubkey);

        expect(token2, token1);
      });

      test('handles multiple concurrent getColorToken calls', () async {
        final pubkeys = List.generate(10, (i) => 'npub1test${i}abcdefghijk');

        final futures = pubkeys.map((pk) => notifier.getColorToken(pk)).toList();
        final tokens = await Future.wait(futures);

        expect(tokens.length, equals(10));
        for (final token in tokens) {
          expect(token, isA<AvatarColorToken>());
        }

        final state = container.read(avatarColorProvider);
        expect(state.length, equals(10));
      });

      test('theme-aware color retrieval works correctly', () async {
        final testPubkey = 'npub1test123456789';
        final token = await notifier.getColorToken(testPubkey);

        // Light mode colors should be different from dark mode colors
        final lightColor = token.getSurfaceColor(Brightness.light);
        final darkColor = token.getSurfaceColor(Brightness.dark);

        expect(lightColor, isNotNull);
        expect(darkColor, isNotNull);
        // Different tokens may have same colors in light/dark, so just verify they exist
        expect(lightColor, isA<Color>());
        expect(darkColor, isA<Color>());
      });
    });
  });
}

// Helper function for JSON encoding
String jsonEncode(dynamic object) {
  if (object is Map) {
    final entries = <String>[];
    object.forEach((key, value) {
      entries.add('"$key":${jsonEncode(value)}');
    });
    return '{${entries.join(',')}}';
  } else if (object is int) {
    return object.toString();
  } else if (object is String) {
    return '"$object"';
  }
  return 'null';
}
