import 'package:freezed_annotation/freezed_annotation.dart';

part 'toast_state.freezed.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

enum ToastStackMode {
  stack,
  replace,
}

@freezed
class ToastMessage with _$ToastMessage {
  const factory ToastMessage({
    required String id,
    required String message,
    required ToastType type,
    @Default(8000) int durationMs,
    @Default(true) bool autoDismiss,
    @Default(false) bool showBelowAppBar,
  }) = _ToastMessage;
}

@freezed
class ToastConfig with _$ToastConfig {
  const factory ToastConfig({
    @Default(ToastStackMode.replace) ToastStackMode stackMode,
    @Default(8000) int defaultDurationMs,
    @Default(true) bool autoDismiss,
    @Default(false) bool defaultShowBelowAppBar,
  }) = _ToastConfig;
}

@freezed
class ToastState with _$ToastState {
  const factory ToastState({
    @Default([]) List<ToastMessage> messages,
    @Default(ToastConfig()) ToastConfig config,
  }) = _ToastState;

  const ToastState._();
}
