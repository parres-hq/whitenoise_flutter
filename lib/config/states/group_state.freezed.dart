// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GroupsState {
  List<GroupData>? get groups => throw _privateConstructorUsedError;
  Map<String, List<PublicKey>>? get groupMembers =>
      throw _privateConstructorUsedError; // groupId -> members
  Map<String, List<PublicKey>>? get groupAdmins =>
      throw _privateConstructorUsedError; // groupId -> admins
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of GroupsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupsStateCopyWith<GroupsState> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupsStateCopyWith<$Res> {
  factory $GroupsStateCopyWith(
    GroupsState value,
    $Res Function(GroupsState) then,
  ) = _$GroupsStateCopyWithImpl<$Res, GroupsState>;
  @useResult
  $Res call({
    List<GroupData>? groups,
    Map<String, List<PublicKey>>? groupMembers,
    Map<String, List<PublicKey>>? groupAdmins,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class _$GroupsStateCopyWithImpl<$Res, $Val extends GroupsState>
    implements $GroupsStateCopyWith<$Res> {
  _$GroupsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groups = freezed,
    Object? groupMembers = freezed,
    Object? groupAdmins = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            groups:
                freezed == groups
                    ? _value.groups
                    : groups // ignore: cast_nullable_to_non_nullable
                        as List<GroupData>?,
            groupMembers:
                freezed == groupMembers
                    ? _value.groupMembers
                    : groupMembers // ignore: cast_nullable_to_non_nullable
                        as Map<String, List<PublicKey>>?,
            groupAdmins:
                freezed == groupAdmins
                    ? _value.groupAdmins
                    : groupAdmins // ignore: cast_nullable_to_non_nullable
                        as Map<String, List<PublicKey>>?,
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
abstract class _$$GroupsStateImplCopyWith<$Res> implements $GroupsStateCopyWith<$Res> {
  factory _$$GroupsStateImplCopyWith(
    _$GroupsStateImpl value,
    $Res Function(_$GroupsStateImpl) then,
  ) = __$$GroupsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<GroupData>? groups,
    Map<String, List<PublicKey>>? groupMembers,
    Map<String, List<PublicKey>>? groupAdmins,
    bool isLoading,
    String? error,
  });
}

/// @nodoc
class __$$GroupsStateImplCopyWithImpl<$Res>
    extends _$GroupsStateCopyWithImpl<$Res, _$GroupsStateImpl>
    implements _$$GroupsStateImplCopyWith<$Res> {
  __$$GroupsStateImplCopyWithImpl(
    _$GroupsStateImpl _value,
    $Res Function(_$GroupsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groups = freezed,
    Object? groupMembers = freezed,
    Object? groupAdmins = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$GroupsStateImpl(
        groups:
            freezed == groups
                ? _value._groups
                : groups // ignore: cast_nullable_to_non_nullable
                    as List<GroupData>?,
        groupMembers:
            freezed == groupMembers
                ? _value._groupMembers
                : groupMembers // ignore: cast_nullable_to_non_nullable
                    as Map<String, List<PublicKey>>?,
        groupAdmins:
            freezed == groupAdmins
                ? _value._groupAdmins
                : groupAdmins // ignore: cast_nullable_to_non_nullable
                    as Map<String, List<PublicKey>>?,
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

class _$GroupsStateImpl implements _GroupsState {
  const _$GroupsStateImpl({
    final List<GroupData>? groups,
    final Map<String, List<PublicKey>>? groupMembers,
    final Map<String, List<PublicKey>>? groupAdmins,
    this.isLoading = false,
    this.error,
  }) : _groups = groups,
       _groupMembers = groupMembers,
       _groupAdmins = groupAdmins;

  final List<GroupData>? _groups;
  @override
  List<GroupData>? get groups {
    final value = _groups;
    if (value == null) return null;
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, List<PublicKey>>? _groupMembers;
  @override
  Map<String, List<PublicKey>>? get groupMembers {
    final value = _groupMembers;
    if (value == null) return null;
    if (_groupMembers is EqualUnmodifiableMapView) return _groupMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> members
  final Map<String, List<PublicKey>>? _groupAdmins;
  // groupId -> members
  @override
  Map<String, List<PublicKey>>? get groupAdmins {
    final value = _groupAdmins;
    if (value == null) return null;
    if (_groupAdmins is EqualUnmodifiableMapView) return _groupAdmins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> admins
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'GroupsState(groups: $groups, groupMembers: $groupMembers, groupAdmins: $groupAdmins, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupsStateImpl &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality().equals(
              other._groupMembers,
              _groupMembers,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupAdmins,
              _groupAdmins,
            ) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_groups),
    const DeepCollectionEquality().hash(_groupMembers),
    const DeepCollectionEquality().hash(_groupAdmins),
    isLoading,
    error,
  );

  /// Create a copy of GroupsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupsStateImplCopyWith<_$GroupsStateImpl> get copyWith =>
      __$$GroupsStateImplCopyWithImpl<_$GroupsStateImpl>(this, _$identity);
}

abstract class _GroupsState implements GroupsState {
  const factory _GroupsState({
    final List<GroupData>? groups,
    final Map<String, List<PublicKey>>? groupMembers,
    final Map<String, List<PublicKey>>? groupAdmins,
    final bool isLoading,
    final String? error,
  }) = _$GroupsStateImpl;

  @override
  List<GroupData>? get groups;
  @override
  Map<String, List<PublicKey>>? get groupMembers; // groupId -> members
  @override
  Map<String, List<PublicKey>>? get groupAdmins; // groupId -> admins
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of GroupsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupsStateImplCopyWith<_$GroupsStateImpl> get copyWith => throw _privateConstructorUsedError;
}
