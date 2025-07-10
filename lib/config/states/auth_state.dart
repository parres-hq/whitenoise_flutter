import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading, // Keep isLoading for foreground operations
    @Default(false) bool isBackgroundProcessing,
    String? error,
  }) = _AuthState;

  const AuthState._();
}
