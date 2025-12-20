// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nostr_keys_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NostrKeysState {
  String? get nsec => throw _privateConstructorUsedError;
  String? get npub => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of NostrKeysState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NostrKeysStateCopyWith<NostrKeysState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NostrKeysStateCopyWith<$Res> {
  factory $NostrKeysStateCopyWith(
    NostrKeysState value,
    $Res Function(NostrKeysState) then,
  ) = _$NostrKeysStateCopyWithImpl<$Res, NostrKeysState>;
  @useResult
  $Res call({String? nsec, String? npub, bool isLoading, String? error});
}

/// @nodoc
class _$NostrKeysStateCopyWithImpl<$Res, $Val extends NostrKeysState>
    implements $NostrKeysStateCopyWith<$Res> {
  _$NostrKeysStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NostrKeysState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nsec = freezed,
    Object? npub = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            nsec:
                freezed == nsec
                    ? _value.nsec
                    : nsec // ignore: cast_nullable_to_non_nullable
                        as String?,
            npub:
                freezed == npub
                    ? _value.npub
                    : npub // ignore: cast_nullable_to_non_nullable
                        as String?,
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
abstract class _$$NostrKeysStateImplCopyWith<$Res> implements $NostrKeysStateCopyWith<$Res> {
  factory _$$NostrKeysStateImplCopyWith(
    _$NostrKeysStateImpl value,
    $Res Function(_$NostrKeysStateImpl) then,
  ) = __$$NostrKeysStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? nsec, String? npub, bool isLoading, String? error});
}

/// @nodoc
class __$$NostrKeysStateImplCopyWithImpl<$Res>
    extends _$NostrKeysStateCopyWithImpl<$Res, _$NostrKeysStateImpl>
    implements _$$NostrKeysStateImplCopyWith<$Res> {
  __$$NostrKeysStateImplCopyWithImpl(
    _$NostrKeysStateImpl _value,
    $Res Function(_$NostrKeysStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NostrKeysState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nsec = freezed,
    Object? npub = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$NostrKeysStateImpl(
        nsec:
            freezed == nsec
                ? _value.nsec
                : nsec // ignore: cast_nullable_to_non_nullable
                    as String?,
        npub:
            freezed == npub
                ? _value.npub
                : npub // ignore: cast_nullable_to_non_nullable
                    as String?,
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

class _$NostrKeysStateImpl implements _NostrKeysState {
  const _$NostrKeysStateImpl({
    this.nsec,
    this.npub,
    this.isLoading = false,
    this.error,
  });

  @override
  final String? nsec;
  @override
  final String? npub;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'NostrKeysState(nsec: $nsec, npub: $npub, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NostrKeysStateImpl &&
            (identical(other.nsec, nsec) || other.nsec == nsec) &&
            (identical(other.npub, npub) || other.npub == npub) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, nsec, npub, isLoading, error);

  /// Create a copy of NostrKeysState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NostrKeysStateImplCopyWith<_$NostrKeysStateImpl> get copyWith =>
      __$$NostrKeysStateImplCopyWithImpl<_$NostrKeysStateImpl>(
        this,
        _$identity,
      );
}

abstract class _NostrKeysState implements NostrKeysState {
  const factory _NostrKeysState({
    final String? nsec,
    final String? npub,
    final bool isLoading,
    final String? error,
  }) = _$NostrKeysStateImpl;

  @override
  String? get nsec;
  @override
  String? get npub;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of NostrKeysState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NostrKeysStateImplCopyWith<_$NostrKeysStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
