import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

void main() {
  group('PubkeyFormatter Tests', () {
    const testNpubPubkey = 'npub1zygjyg3nxdzyg424ven8waug3zvejqqq424thw7venwammhwlllsj2q4yf';
    const testHexPubkey = '1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff';
    const otherTestNpubPubkey = 'npub140x77qfrg4ncnlkuh2v8v4pjzz4ummcpydzk0z07mjafsaj5xggq9d4zqy';
    const otherTestHexPubkey = 'abcdef0123456789fedcba9876543210abcdef0123456789fedcba9876543210';

    const npubHexMap = {
      testNpubPubkey: testHexPubkey,
      otherTestNpubPubkey: otherTestHexPubkey,
    };

    const hexNpubMap = {
      testHexPubkey: testNpubPubkey,
      otherTestHexPubkey: otherTestNpubPubkey,
    };

    late PubkeyFormatter formatter;
    late String? Function({required String hexPubkey}) mockNpubFromHexPubkey;
    late String? Function({required String npub}) mockHexPubkeyFromNpub;

    setUp(() {
      mockNpubFromHexPubkey = ({required String hexPubkey}) => hexNpubMap[hexPubkey];
      mockHexPubkeyFromNpub = ({required String npub}) => npubHexMap[npub];
    });

    group('toNpub', () {
      test('returns npub when input is already npub', () {
        formatter = PubkeyFormatter(
          pubkey: testNpubPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, equals(testNpubPubkey));
      });

      test('converts hex to npub', () {
        formatter = PubkeyFormatter(
          pubkey: testHexPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, equals(testNpubPubkey));
      });

      test('trims and converts hex to npub', () {
        formatter = PubkeyFormatter(
          pubkey: ' $testHexPubkey ',
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, equals(testNpubPubkey));
      });

      test('converts other hex to npub', () {
        formatter = PubkeyFormatter(
          pubkey: otherTestHexPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, equals(otherTestNpubPubkey));
      });

      test('returns null for invalid pubkey', () {
        formatter = PubkeyFormatter(
          pubkey: 'invalid',
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, isNull);
      });

      test('returns null when pubkey is null', () {
        formatter = PubkeyFormatter(
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toNpub();
        expect(result, isNull);
      });
    });

    group('toHex', () {
      test('returns hex when input is already hex', () {
        formatter = PubkeyFormatter(
          pubkey: testHexPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, equals(testHexPubkey));
      });

      test('converts npub to hex', () {
        formatter = PubkeyFormatter(
          pubkey: testNpubPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, testHexPubkey);
      });

      test('trims and converts npub to hex', () {
        formatter = PubkeyFormatter(
          pubkey: ' $testNpubPubkey ',
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, testHexPubkey);
      });

      test('converts other npub to hex', () {
        formatter = PubkeyFormatter(
          pubkey: otherTestNpubPubkey,
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, equals(otherTestHexPubkey));
      });

      test('returns null for invalid pubkey', () {
        formatter = PubkeyFormatter(
          pubkey: 'invalid',
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, isNull);
      });

      test('returns null when pubkey is null', () {
        formatter = PubkeyFormatter(
          npubFromHexPubkey: mockNpubFromHexPubkey,
          hexPubkeyFromNpub: mockHexPubkeyFromNpub,
        );

        final result = formatter.toHex();
        expect(result, isNull);
      });
    });
  });
}
