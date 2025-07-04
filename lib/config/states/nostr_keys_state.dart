import 'package:freezed_annotation/freezed_annotation.dart';

part 'nostr_keys_state.freezed.dart';

@freezed
class NostrKeysState with _$NostrKeysState {
  const factory NostrKeysState({
    String? nsec,
    String? npub,
    @Default(false) bool isLoading,
    String? error,
  }) = _NostrKeysState;
}
