import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

part 'welcome_state.freezed.dart';

@freezed
abstract class WelcomeState with _$WelcomeState {
  const factory WelcomeState({
    List<Welcome>? welcomes,
    Map<String, Welcome>? welcomeById,
    @Default(false) bool isLoading,
    String? error,
  }) = _WelcomeState;
}
