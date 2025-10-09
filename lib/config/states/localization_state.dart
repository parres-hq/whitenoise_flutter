import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'localization_state.freezed.dart';

@freezed
class LocalizationState with _$LocalizationState {
  const factory LocalizationState({
    required Locale currentLocale,
    @Default('system') String selectedLanguage, // system, en, es, de, it, tr, fr, pt, ru
    @Default(false) bool isLoading,
    String? error,
  }) = _LocalizationState;

  const LocalizationState._();
}
