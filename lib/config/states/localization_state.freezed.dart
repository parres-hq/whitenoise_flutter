// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'localization_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LocalizationState {
  Locale get currentLocale => throw _privateConstructorUsedError;
  String get selectedLanguage => throw _privateConstructorUsedError; // system, en, es, de, it
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of LocalizationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LocalizationStateCopyWith<LocalizationState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocalizationStateCopyWith<$Res> {
  factory $LocalizationStateCopyWith(
    LocalizationState value,
    $Res Function(LocalizationState) then,
  ) = _$LocalizationStateCopyWithImpl<$Res, LocalizationState>;
  @useResult
  $Res call({
    Locale currentLocale,
    String selectedLanguage,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$LocalizationStateCopyWithImpl<$Res, $Val extends LocalizationState>
    implements $LocalizationStateCopyWith<$Res> {
  _$LocalizationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LocalizationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentLocale = null,
    Object? selectedLanguage = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            currentLocale:
                null == currentLocale
                    ? _value.currentLocale
                    : currentLocale // ignore: cast_nullable_to_non_nullable
                        as Locale,
            selectedLanguage:
                null == selectedLanguage
                    ? _value.selectedLanguage
                    : selectedLanguage // ignore: cast_nullable_to_non_nullable
                        as String,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
            error:
                freezed == error
                    ? _value.error
                    : error // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LocalizationStateImplCopyWith<$Res> implements $LocalizationStateCopyWith<$Res> {
  factory _$$LocalizationStateImplCopyWith(
    _$LocalizationStateImpl value,
    $Res Function(_$LocalizationStateImpl) then,
  ) = __$$LocalizationStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Locale currentLocale,
    String selectedLanguage,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$LocalizationStateImplCopyWithImpl<$Res>
    extends _$LocalizationStateCopyWithImpl<$Res, _$LocalizationStateImpl>
    implements _$$LocalizationStateImplCopyWith<$Res> {
  __$$LocalizationStateImplCopyWithImpl(
    _$LocalizationStateImpl _value,
    $Res Function(_$LocalizationStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LocalizationState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentLocale = null,
    Object? selectedLanguage = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$LocalizationStateImpl(
        currentLocale:
            null == currentLocale
                ? _value.currentLocale
                : currentLocale // ignore: cast_nullable_to_non_nullable
                    as Locale,
        selectedLanguage:
            null == selectedLanguage
                ? _value.selectedLanguage
                : selectedLanguage // ignore: cast_nullable_to_non_nullable
                    as String,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
        error:
            freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$LocalizationStateImpl extends _LocalizationState {
  const _$LocalizationStateImpl({
    required this.currentLocale,
    this.selectedLanguage = 'system',
    this.isLoading = false,
    this.error,
  }) : super._();

  @override
  final Locale currentLocale;
  @override
  @JsonKey()
  final String selectedLanguage;
  // system, en, es, de, it
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'LocalizationState(currentLocale: $currentLocale, selectedLanguage: $selectedLanguage, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocalizationStateImpl &&
            (identical(other.currentLocale, currentLocale) ||
                other.currentLocale == currentLocale) &&
            (identical(other.selectedLanguage, selectedLanguage) ||
                other.selectedLanguage == selectedLanguage) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentLocale,
    selectedLanguage,
    isLoading,
    error,
  );

  /// Create a copy of LocalizationState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LocalizationStateImplCopyWith<_$LocalizationStateImpl> get copyWith =>
      __$$LocalizationStateImplCopyWithImpl<_$LocalizationStateImpl>(
        this,
        _$identity,
      );
}

abstract class _LocalizationState extends LocalizationState {
  const factory _LocalizationState({
    required final Locale currentLocale,
    final String selectedLanguage,
    final bool isLoading,
    final String? error,
  }) = _$LocalizationStateImpl;
  const _LocalizationState._() : super._();

  @override
  Locale get currentLocale;
  @override
  String get selectedLanguage; // system, en, es, de, it
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of LocalizationState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LocalizationStateImplCopyWith<_$LocalizationStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
