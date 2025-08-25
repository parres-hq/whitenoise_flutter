// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'welcome_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$WelcomeState {
  List<Welcome>? get welcomes => throw _privateConstructorUsedError;
  Map<String, Welcome>? get welcomeById => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WelcomeStateCopyWith<WelcomeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomeStateCopyWith<$Res> {
  factory $WelcomeStateCopyWith(
    WelcomeState value,
    $Res Function(WelcomeState) then,
  ) = _$WelcomeStateCopyWithImpl<$Res, WelcomeState>;
  @useResult
  $Res call({
    List<Welcome>? welcomes,
    Map<String, Welcome>? welcomeById,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$WelcomeStateCopyWithImpl<$Res, $Val extends WelcomeState>
    implements $WelcomeStateCopyWith<$Res> {
  _$WelcomeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? welcomes = freezed,
    Object? welcomeById = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            welcomes:
                freezed == welcomes
                    ? _value.welcomes
                    : welcomes // ignore: cast_nullable_to_non_nullable
                        as List<Welcome>?,
            welcomeById:
                freezed == welcomeById
                    ? _value.welcomeById
                    : welcomeById // ignore: cast_nullable_to_non_nullable
                        as Map<String, Welcome>?,
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
abstract class _$$WelcomeStateImplCopyWith<$Res>
    implements $WelcomeStateCopyWith<$Res> {
  factory _$$WelcomeStateImplCopyWith(
    _$WelcomeStateImpl value,
    $Res Function(_$WelcomeStateImpl) then,
  ) = __$$WelcomeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Welcome>? welcomes,
    Map<String, Welcome>? welcomeById,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$WelcomeStateImplCopyWithImpl<$Res>
    extends _$WelcomeStateCopyWithImpl<$Res, _$WelcomeStateImpl>
    implements _$$WelcomeStateImplCopyWith<$Res> {
  __$$WelcomeStateImplCopyWithImpl(
    _$WelcomeStateImpl _value,
    $Res Function(_$WelcomeStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? welcomes = freezed,
    Object? welcomeById = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$WelcomeStateImpl(
        welcomes:
            freezed == welcomes
                ? _value._welcomes
                : welcomes // ignore: cast_nullable_to_non_nullable
                    as List<Welcome>?,
        welcomeById:
            freezed == welcomeById
                ? _value._welcomeById
                : welcomeById // ignore: cast_nullable_to_non_nullable
                    as Map<String, Welcome>?,
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

class _$WelcomeStateImpl implements _WelcomeState {
  const _$WelcomeStateImpl({
    final List<Welcome>? welcomes,
    final Map<String, Welcome>? welcomeById,
    this.isLoading = false,
    this.error,
  }) : _welcomes = welcomes,
       _welcomeById = welcomeById;

  final List<Welcome>? _welcomes;
  @override
  List<Welcome>? get welcomes {
    final value = _welcomes;
    if (value == null) return null;
    if (_welcomes is EqualUnmodifiableListView) return _welcomes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, Welcome>? _welcomeById;
  @override
  Map<String, Welcome>? get welcomeById {
    final value = _welcomeById;
    if (value == null) return null;
    if (_welcomeById is EqualUnmodifiableMapView) return _welcomeById;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'WelcomeState(welcomes: $welcomes, welcomeById: $welcomeById, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WelcomeStateImpl &&
            const DeepCollectionEquality().equals(other._welcomes, _welcomes) &&
            const DeepCollectionEquality().equals(
              other._welcomeById,
              _welcomeById,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_welcomes),
    const DeepCollectionEquality().hash(_welcomeById),
    isLoading,
    error,
  );

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WelcomeStateImplCopyWith<_$WelcomeStateImpl> get copyWith =>
      __$$WelcomeStateImplCopyWithImpl<_$WelcomeStateImpl>(this, _$identity);
}

abstract class _WelcomeState implements WelcomeState {
  const factory _WelcomeState({
    final List<Welcome>? welcomes,
    final Map<String, Welcome>? welcomeById,
    final bool isLoading,
    final String? error,
  }) = _$WelcomeStateImpl;

  @override
  List<Welcome>? get welcomes;
  @override
  Map<String, Welcome>? get welcomeById;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of WelcomeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WelcomeStateImplCopyWith<_$WelcomeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
