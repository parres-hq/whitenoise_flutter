// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ProfileState {
  String? get displayName => throw _privateConstructorUsedError;
  String? get about => throw _privateConstructorUsedError;
  String? get picture => throw _privateConstructorUsedError;
  String? get nip05 => throw _privateConstructorUsedError;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileStateCopyWith<ProfileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileStateCopyWith<$Res> {
  factory $ProfileStateCopyWith(
    ProfileState value,
    $Res Function(ProfileState) then,
  ) = _$ProfileStateCopyWithImpl<$Res, ProfileState>;
  @useResult
  $Res call({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
  });
}

/// @nodoc
class _$ProfileStateCopyWithImpl<$Res, $Val extends ProfileState>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = freezed,
    Object? about = freezed,
    Object? picture = freezed,
    Object? nip05 = freezed,
  }) {
    return _then(
      _value.copyWith(
            displayName:
                freezed == displayName
                    ? _value.displayName
                    : displayName // ignore: cast_nullable_to_non_nullable
                        as String?,
            about:
                freezed == about
                    ? _value.about
                    : about // ignore: cast_nullable_to_non_nullable
                        as String?,
            picture:
                freezed == picture
                    ? _value.picture
                    : picture // ignore: cast_nullable_to_non_nullable
                        as String?,
            nip05:
                freezed == nip05
                    ? _value.nip05
                    : nip05 // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProfileStateImplCopyWith<$Res>
    implements $ProfileStateCopyWith<$Res> {
  factory _$$ProfileStateImplCopyWith(
    _$ProfileStateImpl value,
    $Res Function(_$ProfileStateImpl) then,
  ) = __$$ProfileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
  });
}

/// @nodoc
class __$$ProfileStateImplCopyWithImpl<$Res>
    extends _$ProfileStateCopyWithImpl<$Res, _$ProfileStateImpl>
    implements _$$ProfileStateImplCopyWith<$Res> {
  __$$ProfileStateImplCopyWithImpl(
    _$ProfileStateImpl _value,
    $Res Function(_$ProfileStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = freezed,
    Object? about = freezed,
    Object? picture = freezed,
    Object? nip05 = freezed,
  }) {
    return _then(
      _$ProfileStateImpl(
        displayName:
            freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                    as String?,
        about:
            freezed == about
                ? _value.about
                : about // ignore: cast_nullable_to_non_nullable
                    as String?,
        picture:
            freezed == picture
                ? _value.picture
                : picture // ignore: cast_nullable_to_non_nullable
                    as String?,
        nip05:
            freezed == nip05
                ? _value.nip05
                : nip05 // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$ProfileStateImpl extends _ProfileState {
  const _$ProfileStateImpl({
    this.displayName,
    this.about,
    this.picture,
    this.nip05,
  }) : super._();

  @override
  final String? displayName;
  @override
  final String? about;
  @override
  final String? picture;
  @override
  final String? nip05;

  @override
  String toString() {
    return 'ProfileState(displayName: $displayName, about: $about, picture: $picture, nip05: $nip05)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileStateImpl &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.about, about) || other.about == about) &&
            (identical(other.picture, picture) || other.picture == picture) &&
            (identical(other.nip05, nip05) || other.nip05 == nip05));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, displayName, about, picture, nip05);

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      __$$ProfileStateImplCopyWithImpl<_$ProfileStateImpl>(this, _$identity);
}

abstract class _ProfileState extends ProfileState {
  const factory _ProfileState({
    final String? displayName,
    final String? about,
    final String? picture,
    final String? nip05,
  }) = _$ProfileStateImpl;
  const _ProfileState._() : super._();

  @override
  String? get displayName;
  @override
  String? get about;
  @override
  String? get picture;
  @override
  String? get nip05;

  /// Create a copy of ProfileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
