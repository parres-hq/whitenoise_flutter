import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    String? error,
    Whitenoise? whitenoise,
  }) = _AuthState;

  const AuthState._();
}
