import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

part 'welcome_state.freezed.dart';

@freezed
abstract class WelcomesState with _$WelcomesState {
  const factory WelcomesState({
    List<WelcomeData>? welcomes,
    Map<String, WelcomeData>? welcomeById,
    @Default(false) bool isLoading,
    String? error,
  }) = _WelcomesState;
}
