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
mixin _$WelcomesState {
  List<Welcome>? get welcomes => throw _privateConstructorUsedError;
  Map<String, Welcome>? get welcomeById => throw _privateConstructorUsedError;
  Map<String, User>? get welcomerUsers => throw _privateConstructorUsedError;
  Map<String, String>? get welcomeDigests => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of WelcomesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WelcomesStateCopyWith<WelcomesState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WelcomesStateCopyWith<$Res> {
  factory $WelcomesStateCopyWith(
    WelcomesState value,
    $Res Function(WelcomesState) then,
  ) = _$WelcomesStateCopyWithImpl<$Res, WelcomesState>;
  @useResult
  $Res call({
    List<Welcome>? welcomes,
    Map<String, Welcome>? welcomeById,
    Map<String, User>? welcomerUsers,
    Map<String, String>? welcomeDigests,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$WelcomesStateCopyWithImpl<$Res, $Val extends WelcomesState>
    implements $WelcomesStateCopyWith<$Res> {
  _$WelcomesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WelcomesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? welcomes = freezed,
    Object? welcomeById = freezed,
    Object? welcomerUsers = freezed,
    Object? welcomeDigests = freezed,
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
            welcomerUsers:
                freezed == welcomerUsers
                    ? _value.welcomerUsers
                    : welcomerUsers // ignore: cast_nullable_to_non_nullable
                        as Map<String, User>?,
            welcomeDigests:
                freezed == welcomeDigests
                    ? _value.welcomeDigests
                    : welcomeDigests // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>?,
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
abstract class _$$WelcomesStateImplCopyWith<$Res> implements $WelcomesStateCopyWith<$Res> {
  factory _$$WelcomesStateImplCopyWith(
    _$WelcomesStateImpl value,
    $Res Function(_$WelcomesStateImpl) then,
  ) = __$$WelcomesStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Welcome>? welcomes,
    Map<String, Welcome>? welcomeById,
    Map<String, User>? welcomerUsers,
    Map<String, String>? welcomeDigests,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$WelcomesStateImplCopyWithImpl<$Res>
    extends _$WelcomesStateCopyWithImpl<$Res, _$WelcomesStateImpl>
    implements _$$WelcomesStateImplCopyWith<$Res> {
  __$$WelcomesStateImplCopyWithImpl(
    _$WelcomesStateImpl _value,
    $Res Function(_$WelcomesStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WelcomesState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? welcomes = freezed,
    Object? welcomeById = freezed,
    Object? welcomerUsers = freezed,
    Object? welcomeDigests = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$WelcomesStateImpl(
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
        welcomerUsers:
            freezed == welcomerUsers
                ? _value._welcomerUsers
                : welcomerUsers // ignore: cast_nullable_to_non_nullable
                    as Map<String, User>?,
        welcomeDigests:
            freezed == welcomeDigests
                ? _value._welcomeDigests
                : welcomeDigests // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>?,
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

class _$WelcomesStateImpl implements _WelcomesState {
  const _$WelcomesStateImpl({
    final List<Welcome>? welcomes,
    final Map<String, Welcome>? welcomeById,
    final Map<String, User>? welcomerUsers,
    final Map<String, String>? welcomeDigests,
    this.isLoading = false,
    this.error,
  }) : _welcomes = welcomes,
       _welcomeById = welcomeById,
       _welcomerUsers = welcomerUsers,
       _welcomeDigests = welcomeDigests;

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

  final Map<String, User>? _welcomerUsers;
  @override
  Map<String, User>? get welcomerUsers {
    final value = _welcomerUsers;
    if (value == null) return null;
    if (_welcomerUsers is EqualUnmodifiableMapView) return _welcomerUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, String>? _welcomeDigests;
  @override
  Map<String, String>? get welcomeDigests {
    final value = _welcomeDigests;
    if (value == null) return null;
    if (_welcomeDigests is EqualUnmodifiableMapView) return _welcomeDigests;
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
    return 'WelcomesState(welcomes: $welcomes, welcomeById: $welcomeById, welcomerUsers: $welcomerUsers, welcomeDigests: $welcomeDigests, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WelcomesStateImpl &&
            const DeepCollectionEquality().equals(other._welcomes, _welcomes) &&
            const DeepCollectionEquality().equals(
              other._welcomeById,
              _welcomeById,
            ) &&
            const DeepCollectionEquality().equals(
              other._welcomerUsers,
              _welcomerUsers,
            ) &&
            const DeepCollectionEquality().equals(
              other._welcomeDigests,
              _welcomeDigests,
            ) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_welcomes),
    const DeepCollectionEquality().hash(_welcomeById),
    const DeepCollectionEquality().hash(_welcomerUsers),
    const DeepCollectionEquality().hash(_welcomeDigests),
    isLoading,
    error,
  );

  /// Create a copy of WelcomesState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WelcomesStateImplCopyWith<_$WelcomesStateImpl> get copyWith =>
      __$$WelcomesStateImplCopyWithImpl<_$WelcomesStateImpl>(this, _$identity);
}

abstract class _WelcomesState implements WelcomesState {
  const factory _WelcomesState({
    final List<Welcome>? welcomes,
    final Map<String, Welcome>? welcomeById,
    final Map<String, User>? welcomerUsers,
    final Map<String, String>? welcomeDigests,
    final bool isLoading,
    final String? error,
  }) = _$WelcomesStateImpl;

  @override
  List<Welcome>? get welcomes;
  @override
  Map<String, Welcome>? get welcomeById;
  @override
  Map<String, User>? get welcomerUsers;
  @override
  Map<String, String>? get welcomeDigests;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of WelcomesState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WelcomesStateImplCopyWith<_$WelcomesStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
