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
  List<Group>? get groups => throw _privateConstructorUsedError;
  Map<String, Group>? get groupsMap => throw _privateConstructorUsedError; // groupId -> Group
  Map<String, List<User>>? get groupMembers =>
      throw _privateConstructorUsedError; // groupId -> members
  Map<String, List<User>>? get groupAdmins =>
      throw _privateConstructorUsedError; // groupId -> admins
  Map<String, String>? get groupDisplayNames =>
      throw _privateConstructorUsedError; // groupId -> display name
  Map<String, GroupType>? get groupTypes =>
      throw _privateConstructorUsedError; // groupId -> GroupType (cached for synchronous access)
  Map<String, String>? get groupImagePaths =>
      throw _privateConstructorUsedError; // groupId -> image file path
  Map<String, DateTime>? get groupCreatedAts =>
      throw _privateConstructorUsedError; // groupId -> createdAt (for sorting fallback)
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
    List<Group>? groups,
    Map<String, Group>? groupsMap,
    Map<String, List<User>>? groupMembers,
    Map<String, List<User>>? groupAdmins,
    Map<String, String>? groupDisplayNames,
    Map<String, GroupType>? groupTypes,
    Map<String, String>? groupImagePaths,
    Map<String, DateTime>? groupCreatedAts,
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
    Object? groupsMap = freezed,
    Object? groupMembers = freezed,
    Object? groupAdmins = freezed,
    Object? groupDisplayNames = freezed,
    Object? groupTypes = freezed,
    Object? groupImagePaths = freezed,
    Object? groupCreatedAts = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            groups:
                freezed == groups
                    ? _value.groups
                    : groups // ignore: cast_nullable_to_non_nullable
                        as List<Group>?,
            groupsMap:
                freezed == groupsMap
                    ? _value.groupsMap
                    : groupsMap // ignore: cast_nullable_to_non_nullable
                        as Map<String, Group>?,
            groupMembers:
                freezed == groupMembers
                    ? _value.groupMembers
                    : groupMembers // ignore: cast_nullable_to_non_nullable
                        as Map<String, List<User>>?,
            groupAdmins:
                freezed == groupAdmins
                    ? _value.groupAdmins
                    : groupAdmins // ignore: cast_nullable_to_non_nullable
                        as Map<String, List<User>>?,
            groupDisplayNames:
                freezed == groupDisplayNames
                    ? _value.groupDisplayNames
                    : groupDisplayNames // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>?,
            groupTypes:
                freezed == groupTypes
                    ? _value.groupTypes
                    : groupTypes // ignore: cast_nullable_to_non_nullable
                        as Map<String, GroupType>?,
            groupImagePaths:
                freezed == groupImagePaths
                    ? _value.groupImagePaths
                    : groupImagePaths // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>?,
            groupCreatedAts:
                freezed == groupCreatedAts
                    ? _value.groupCreatedAts
                    : groupCreatedAts // ignore: cast_nullable_to_non_nullable
                        as Map<String, DateTime>?,
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
    List<Group>? groups,
    Map<String, Group>? groupsMap,
    Map<String, List<User>>? groupMembers,
    Map<String, List<User>>? groupAdmins,
    Map<String, String>? groupDisplayNames,
    Map<String, GroupType>? groupTypes,
    Map<String, String>? groupImagePaths,
    Map<String, DateTime>? groupCreatedAts,
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
    Object? groupsMap = freezed,
    Object? groupMembers = freezed,
    Object? groupAdmins = freezed,
    Object? groupDisplayNames = freezed,
    Object? groupTypes = freezed,
    Object? groupImagePaths = freezed,
    Object? groupCreatedAts = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(
      _$GroupsStateImpl(
        groups:
            freezed == groups
                ? _value._groups
                : groups // ignore: cast_nullable_to_non_nullable
                    as List<Group>?,
        groupsMap:
            freezed == groupsMap
                ? _value._groupsMap
                : groupsMap // ignore: cast_nullable_to_non_nullable
                    as Map<String, Group>?,
        groupMembers:
            freezed == groupMembers
                ? _value._groupMembers
                : groupMembers // ignore: cast_nullable_to_non_nullable
                    as Map<String, List<User>>?,
        groupAdmins:
            freezed == groupAdmins
                ? _value._groupAdmins
                : groupAdmins // ignore: cast_nullable_to_non_nullable
                    as Map<String, List<User>>?,
        groupDisplayNames:
            freezed == groupDisplayNames
                ? _value._groupDisplayNames
                : groupDisplayNames // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>?,
        groupTypes:
            freezed == groupTypes
                ? _value._groupTypes
                : groupTypes // ignore: cast_nullable_to_non_nullable
                    as Map<String, GroupType>?,
        groupImagePaths:
            freezed == groupImagePaths
                ? _value._groupImagePaths
                : groupImagePaths // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>?,
        groupCreatedAts:
            freezed == groupCreatedAts
                ? _value._groupCreatedAts
                : groupCreatedAts // ignore: cast_nullable_to_non_nullable
                    as Map<String, DateTime>?,
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
    final List<Group>? groups,
    final Map<String, Group>? groupsMap,
    final Map<String, List<User>>? groupMembers,
    final Map<String, List<User>>? groupAdmins,
    final Map<String, String>? groupDisplayNames,
    final Map<String, GroupType>? groupTypes,
    final Map<String, String>? groupImagePaths,
    final Map<String, DateTime>? groupCreatedAts,
    this.isLoading = false,
    this.error,
  }) : _groups = groups,
       _groupsMap = groupsMap,
       _groupMembers = groupMembers,
       _groupAdmins = groupAdmins,
       _groupDisplayNames = groupDisplayNames,
       _groupTypes = groupTypes,
       _groupImagePaths = groupImagePaths,
       _groupCreatedAts = groupCreatedAts;

  final List<Group>? _groups;
  @override
  List<Group>? get groups {
    final value = _groups;
    if (value == null) return null;
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, Group>? _groupsMap;
  @override
  Map<String, Group>? get groupsMap {
    final value = _groupsMap;
    if (value == null) return null;
    if (_groupsMap is EqualUnmodifiableMapView) return _groupsMap;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> Group
  final Map<String, List<User>>? _groupMembers;
  // groupId -> Group
  @override
  Map<String, List<User>>? get groupMembers {
    final value = _groupMembers;
    if (value == null) return null;
    if (_groupMembers is EqualUnmodifiableMapView) return _groupMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> members
  final Map<String, List<User>>? _groupAdmins;
  // groupId -> members
  @override
  Map<String, List<User>>? get groupAdmins {
    final value = _groupAdmins;
    if (value == null) return null;
    if (_groupAdmins is EqualUnmodifiableMapView) return _groupAdmins;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> admins
  final Map<String, String>? _groupDisplayNames;
  // groupId -> admins
  @override
  Map<String, String>? get groupDisplayNames {
    final value = _groupDisplayNames;
    if (value == null) return null;
    if (_groupDisplayNames is EqualUnmodifiableMapView) return _groupDisplayNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> display name
  final Map<String, GroupType>? _groupTypes;
  // groupId -> display name
  @override
  Map<String, GroupType>? get groupTypes {
    final value = _groupTypes;
    if (value == null) return null;
    if (_groupTypes is EqualUnmodifiableMapView) return _groupTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> GroupType (cached for synchronous access)
  final Map<String, String>? _groupImagePaths;
  // groupId -> GroupType (cached for synchronous access)
  @override
  Map<String, String>? get groupImagePaths {
    final value = _groupImagePaths;
    if (value == null) return null;
    if (_groupImagePaths is EqualUnmodifiableMapView) return _groupImagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> image file path
  final Map<String, DateTime>? _groupCreatedAts;
  // groupId -> image file path
  @override
  Map<String, DateTime>? get groupCreatedAts {
    final value = _groupCreatedAts;
    if (value == null) return null;
    if (_groupCreatedAts is EqualUnmodifiableMapView) return _groupCreatedAts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // groupId -> createdAt (for sorting fallback)
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'GroupsState(groups: $groups, groupsMap: $groupsMap, groupMembers: $groupMembers, groupAdmins: $groupAdmins, groupDisplayNames: $groupDisplayNames, groupTypes: $groupTypes, groupImagePaths: $groupImagePaths, groupCreatedAts: $groupCreatedAts, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupsStateImpl &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality().equals(
              other._groupsMap,
              _groupsMap,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupMembers,
              _groupMembers,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupAdmins,
              _groupAdmins,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupDisplayNames,
              _groupDisplayNames,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupTypes,
              _groupTypes,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupImagePaths,
              _groupImagePaths,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupCreatedAts,
              _groupCreatedAts,
            ) &&
            (identical(other.isLoading, isLoading) || other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_groups),
    const DeepCollectionEquality().hash(_groupsMap),
    const DeepCollectionEquality().hash(_groupMembers),
    const DeepCollectionEquality().hash(_groupAdmins),
    const DeepCollectionEquality().hash(_groupDisplayNames),
    const DeepCollectionEquality().hash(_groupTypes),
    const DeepCollectionEquality().hash(_groupImagePaths),
    const DeepCollectionEquality().hash(_groupCreatedAts),
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
    final List<Group>? groups,
    final Map<String, Group>? groupsMap,
    final Map<String, List<User>>? groupMembers,
    final Map<String, List<User>>? groupAdmins,
    final Map<String, String>? groupDisplayNames,
    final Map<String, GroupType>? groupTypes,
    final Map<String, String>? groupImagePaths,
    final Map<String, DateTime>? groupCreatedAts,
    final bool isLoading,
    final String? error,
  }) = _$GroupsStateImpl;

  @override
  List<Group>? get groups;
  @override
  Map<String, Group>? get groupsMap; // groupId -> Group
  @override
  Map<String, List<User>>? get groupMembers; // groupId -> members
  @override
  Map<String, List<User>>? get groupAdmins; // groupId -> admins
  @override
  Map<String, String>? get groupDisplayNames; // groupId -> display name
  @override
  Map<String, GroupType>? get groupTypes; // groupId -> GroupType (cached for synchronous access)
  @override
  Map<String, String>? get groupImagePaths; // groupId -> image file path
  @override
  Map<String, DateTime>? get groupCreatedAts; // groupId -> createdAt (for sorting fallback)
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
