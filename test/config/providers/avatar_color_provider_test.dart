import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
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

      test('loads saved colors from SharedPreferences', () async {
        final testPubkey = 'npub184zv6mef94t7gzagy0tc4utgdt9kgaesdl4qazykw899kvavjz2sy8mhfh';
        final testColor = const Color(0xFFE57373);
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);
        
        SharedPreferences.setMockInitialValues({
          'avatar_colors_map': '{"$cacheKey": ${testColor.toARGB32()}}',
        });

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        newContainer.read(avatarColorProvider.notifier);
        
        await Future.delayed(const Duration(milliseconds: 200));

        final state = newContainer.read(avatarColorProvider);
        expect(state.containsKey(cacheKey), isTrue);
        expect(state[cacheKey], testColor);
      });

      test('handles error when loading saved colors fails', () async {
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

      test('does not update state when loaded colors map is empty', () async {
        SharedPreferences.setMockInitialValues({});

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        newContainer.read(avatarColorProvider.notifier);
        
        await Future.delayed(const Duration(milliseconds: 200));

        final state = newContainer.read(avatarColorProvider);
        expect(state, isEmpty);
      });
    });

    group('getColor', () {
      test('returns cached color if available', () async {
        final testPubkey = 'npub1test123456789';
        final testColor = const Color(0xFFE57373);
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);

        // Manually set state with cached color
        notifier.state = {cacheKey: testColor};

        final color = await notifier.getColor(testPubkey);
        expect(color, testColor);
      });

      test('generates and caches new color if not in cache', () async {
        final testPubkey = 'npub1test123456789';
        
        expect(container.read(avatarColorProvider), isEmpty);

        final color = await notifier.getColor(testPubkey);
        
        expect(color, isA<Color>());
        
        final cacheKey = AvatarColorService.toCacheKey(testPubkey);
        expect(container.read(avatarColorProvider).containsKey(cacheKey), isTrue);
        expect(container.read(avatarColorProvider)[cacheKey], color);
      });

      test('saves generated color to SharedPreferences', () async {
        final testPubkey = 'npub1test123456789';
        
        await notifier.getColor(testPubkey);
        
        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('avatar_colors_map');
        expect(savedData, isNotNull);
        expect(savedData, isNotEmpty);
      });

      test('handles hex pubkey format', () async {
        final hexPubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
        
        final color = await notifier.getColor(hexPubkey);
        
        expect(color, isA<Color>());
        
        final cacheKey = AvatarColorService.toCacheKey(hexPubkey);
        expect(container.read(avatarColorProvider).containsKey(cacheKey), isTrue);
      });

      test('returns same color for same pubkey on subsequent calls', () async {
        final testPubkey = 'npub1test123456789';
        
        final color1 = await notifier.getColor(testPubkey);
        final color2 = await notifier.getColor(testPubkey);
        
        expect(color1, color2);
      });
    });

    group('preloadColors', () {
      test('loads colors for multiple pubkeys', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
          'npub1test555555555',
        ];

        await notifier.preloadColors(pubkeys);

        final state = container.read(avatarColorProvider);
        
        for (final pubkey in pubkeys) {
          final cacheKey = AvatarColorService.toCacheKey(pubkey);
          expect(state.containsKey(cacheKey), isTrue);
          expect(state[cacheKey], isA<Color>());
        }
      });

      test('skips already cached pubkeys', () async {
        final cachedPubkey = 'npub1cached123456';
        final newPubkey = 'npub1new123456789';
        final cachedColor = const Color(0xFFE57373);
        final cacheKey = AvatarColorService.toCacheKey(cachedPubkey);

        notifier.state = {cacheKey: cachedColor};

        await notifier.preloadColors([cachedPubkey, newPubkey]);

        final state = container.read(avatarColorProvider);
        
        expect(state[cacheKey], cachedColor);
        
        final newCacheKey = AvatarColorService.toCacheKey(newPubkey);
        expect(state.containsKey(newCacheKey), isTrue);
      });

      test('returns early when all pubkeys are already cached', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
        ];

        await notifier.preloadColors(pubkeys);
        final initialState = container.read(avatarColorProvider);
        final initialSize = initialState.length;

        await notifier.preloadColors(pubkeys);
        final finalState = container.read(avatarColorProvider);
        
        expect(finalState.length, equals(initialSize));
      });

      test('handles empty pubkey list', () async {
        await notifier.preloadColors([]);
        
        final state = container.read(avatarColorProvider);
        expect(state, isEmpty);
      });

      test('saves all generated colors to SharedPreferences', () async {
        final pubkeys = [
          'npub1test123456789',
          'npub1test987654321',
        ];

        await notifier.preloadColors(pubkeys);

        final prefs = await SharedPreferences.getInstance();
        final savedData = prefs.getString('avatar_colors_map');
        expect(savedData, isNotNull);
        
        for (final pubkey in pubkeys) {
          final cacheKey = AvatarColorService.toCacheKey(pubkey);
          expect(savedData!.contains(cacheKey), isTrue);
        }
      });

      test('notifies listeners when colors are preloaded', () async {
        var notificationCount = 0;
        final listener = container.listen(
          avatarColorProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.preloadColors(['npub1test123456789']);

        expect(notificationCount, equals(1));
        listener.close();
      });

      test('handles errors gracefully during preload', () async {
        await notifier.preloadColors(['invalid_pubkey_that_might_cause_error']);
        
        final finalState = container.read(avatarColorProvider);
        expect(finalState, isA<Map<String, Color>>());
      });
    });

    group('clearAll', () {
      test('clears all colors from state', () async {
        final testPubkey = 'npub1test123456789';
        await notifier.getColor(testPubkey);
        
        expect(container.read(avatarColorProvider), isNotEmpty);

        await notifier.clearAll();

        expect(container.read(avatarColorProvider), isEmpty);
      });

      test('clears colors from SharedPreferences', () async {
        final testPubkey = 'npub1test123456789';
        await notifier.getColor(testPubkey);
        
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

        await notifier.getColor('npub1test123456789');
        notificationCount = 0;

        await notifier.clearAll();

        expect(notificationCount, equals(1));
        listener.close();
      });
    });

    group('AvatarColorService.toCacheKey', () {
      test('generates consistent cache key for npub format', () {
        final pubkey = 'npub1test123456789abcdef';
        final cacheKey1 = AvatarColorService.toCacheKey(pubkey);
        final cacheKey2 = AvatarColorService.toCacheKey(pubkey);
        
        expect(cacheKey1, cacheKey2);
        expect(cacheKey1, equals('npub1test123'));
      });

      test('generates cache key from hex pubkey', () {
        final hexPubkey = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
        final cacheKey = AvatarColorService.toCacheKey(hexPubkey);
        
        expect(cacheKey, isNotEmpty);
        expect(cacheKey.length, equals(12));
      });

      test('generates cache key consistently for same input', () {
        final npubPubkey = 'npub180cvv07tjdrqgzl0j7j4au0y72qcxg8aewunz3ewyv56jth72fwqer0t3s';
        
        final cacheKey1 = AvatarColorService.toCacheKey(npubPubkey);
        final cacheKey2 = AvatarColorService.toCacheKey(npubPubkey);
        
        expect(cacheKey1, cacheKey2);
        expect(cacheKey1, equals('npub180cvv07'));
      });
    });

    group('integration tests', () {
      test('full workflow: generate, cache, retrieve, clear', () async {
        final testPubkey = 'npub1test123456789';
        
        final color1 = await notifier.getColor(testPubkey);
        expect(color1, isA<Color>());
        
        final color2 = await notifier.getColor(testPubkey);
        expect(color2, color1);
        
        await notifier.clearAll();
        expect(container.read(avatarColorProvider), isEmpty);
        
        final color3 = await notifier.getColor(testPubkey);
        expect(color3, isA<Color>());
      });

      test('persistence across provider instances', () async {
        final testPubkey = 'npub1test123456789';
        
        final color1 = await notifier.getColor(testPubkey);
        
        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        final newNotifier = newContainer.read(avatarColorProvider.notifier);
        final color2 = await newNotifier.getColor(testPubkey);
        
        expect(color2, color1);
      });

      test('handles multiple concurrent getColor calls', () async {
        final pubkeys = List.generate(10, (i) => 'npub1test${i}abcdefghijk');
        
        final futures = pubkeys.map((pk) => notifier.getColor(pk)).toList();
        final colors = await Future.wait(futures);
        
        expect(colors.length, equals(10));
        for (final color in colors) {
          expect(color, isA<Color>());
        }
        
        final state = container.read(avatarColorProvider);
        expect(state.length, equals(10));
      });
    });
  });
}
