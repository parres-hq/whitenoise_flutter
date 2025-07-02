// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatState {
  // Map of groupId -> list of messages
  Map<String, List<MessageWithTokensData>> get groupMessages =>
      throw _privateConstructorUsedError; // Currently selected group ID
  String? get selectedGroupId =>
      throw _privateConstructorUsedError; // Loading states per group
  Map<String, bool> get groupLoadingStates =>
      throw _privateConstructorUsedError; // Error states per group
  Map<String, String?> get groupErrorStates =>
      throw _privateConstructorUsedError; // Global loading state
  bool get isLoading =>
      throw _privateConstructorUsedError; // Global error state
  String? get error =>
      throw _privateConstructorUsedError; // Sending message states per group
  Map<String, bool> get sendingStates => throw _privateConstructorUsedError;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatStateCopyWith<ChatState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
  @useResult
  $Res call({
    Map<String, List<MessageWithTokensData>> groupMessages,
    String? selectedGroupId,
    Map<String, bool> groupLoadingStates,
    Map<String, String?> groupErrorStates,
    bool isLoading,
    String? error,
    Map<String, bool> sendingStates,
  });
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupMessages = null,
    Object? selectedGroupId = freezed,
    Object? groupLoadingStates = null,
    Object? groupErrorStates = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? sendingStates = null,
  }) {
    return _then(
      _value.copyWith(
            groupMessages:
                null == groupMessages
                    ? _value.groupMessages
                    : groupMessages // ignore: cast_nullable_to_non_nullable
                        as Map<String, List<MessageWithTokensData>>,
            selectedGroupId:
                freezed == selectedGroupId
                    ? _value.selectedGroupId
                    : selectedGroupId // ignore: cast_nullable_to_non_nullable
                        as String?,
            groupLoadingStates:
                null == groupLoadingStates
                    ? _value.groupLoadingStates
                    : groupLoadingStates // ignore: cast_nullable_to_non_nullable
                        as Map<String, bool>,
            groupErrorStates:
                null == groupErrorStates
                    ? _value.groupErrorStates
                    : groupErrorStates // ignore: cast_nullable_to_non_nullable
                        as Map<String, String?>,
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
            sendingStates:
                null == sendingStates
                    ? _value.sendingStates
                    : sendingStates // ignore: cast_nullable_to_non_nullable
                        as Map<String, bool>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatStateImplCopyWith<$Res>
    implements $ChatStateCopyWith<$Res> {
  factory _$$ChatStateImplCopyWith(
    _$ChatStateImpl value,
    $Res Function(_$ChatStateImpl) then,
  ) = __$$ChatStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, List<MessageWithTokensData>> groupMessages,
    String? selectedGroupId,
    Map<String, bool> groupLoadingStates,
    Map<String, String?> groupErrorStates,
    bool isLoading,
    String? error,
    Map<String, bool> sendingStates,
  });
}

/// @nodoc
class __$$ChatStateImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatStateImpl>
    implements _$$ChatStateImplCopyWith<$Res> {
  __$$ChatStateImplCopyWithImpl(
    _$ChatStateImpl _value,
    $Res Function(_$ChatStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupMessages = null,
    Object? selectedGroupId = freezed,
    Object? groupLoadingStates = null,
    Object? groupErrorStates = null,
    Object? isLoading = null,
    Object? error = freezed,
    Object? sendingStates = null,
  }) {
    return _then(
      _$ChatStateImpl(
        groupMessages:
            null == groupMessages
                ? _value._groupMessages
                : groupMessages // ignore: cast_nullable_to_non_nullable
                    as Map<String, List<MessageWithTokensData>>,
        selectedGroupId:
            freezed == selectedGroupId
                ? _value.selectedGroupId
                : selectedGroupId // ignore: cast_nullable_to_non_nullable
                    as String?,
        groupLoadingStates:
            null == groupLoadingStates
                ? _value._groupLoadingStates
                : groupLoadingStates // ignore: cast_nullable_to_non_nullable
                    as Map<String, bool>,
        groupErrorStates:
            null == groupErrorStates
                ? _value._groupErrorStates
                : groupErrorStates // ignore: cast_nullable_to_non_nullable
                    as Map<String, String?>,
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
        sendingStates:
            null == sendingStates
                ? _value._sendingStates
                : sendingStates // ignore: cast_nullable_to_non_nullable
                    as Map<String, bool>,
      ),
    );
  }
}

/// @nodoc

class _$ChatStateImpl extends _ChatState {
  const _$ChatStateImpl({
    final Map<String, List<MessageWithTokensData>> groupMessages = const {},
    this.selectedGroupId,
    final Map<String, bool> groupLoadingStates = const {},
    final Map<String, String?> groupErrorStates = const {},
    this.isLoading = false,
    this.error,
    final Map<String, bool> sendingStates = const {},
  }) : _groupMessages = groupMessages,
       _groupLoadingStates = groupLoadingStates,
       _groupErrorStates = groupErrorStates,
       _sendingStates = sendingStates,
       super._();

  // Map of groupId -> list of messages
  final Map<String, List<MessageWithTokensData>> _groupMessages;
  // Map of groupId -> list of messages
  @override
  @JsonKey()
  Map<String, List<MessageWithTokensData>> get groupMessages {
    if (_groupMessages is EqualUnmodifiableMapView) return _groupMessages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_groupMessages);
  }

  // Currently selected group ID
  @override
  final String? selectedGroupId;
  // Loading states per group
  final Map<String, bool> _groupLoadingStates;
  // Loading states per group
  @override
  @JsonKey()
  Map<String, bool> get groupLoadingStates {
    if (_groupLoadingStates is EqualUnmodifiableMapView)
      return _groupLoadingStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_groupLoadingStates);
  }

  // Error states per group
  final Map<String, String?> _groupErrorStates;
  // Error states per group
  @override
  @JsonKey()
  Map<String, String?> get groupErrorStates {
    if (_groupErrorStates is EqualUnmodifiableMapView) return _groupErrorStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_groupErrorStates);
  }

  // Global loading state
  @override
  @JsonKey()
  final bool isLoading;
  // Global error state
  @override
  final String? error;
  // Sending message states per group
  final Map<String, bool> _sendingStates;
  // Sending message states per group
  @override
  @JsonKey()
  Map<String, bool> get sendingStates {
    if (_sendingStates is EqualUnmodifiableMapView) return _sendingStates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_sendingStates);
  }

  @override
  String toString() {
    return 'ChatState(groupMessages: $groupMessages, selectedGroupId: $selectedGroupId, groupLoadingStates: $groupLoadingStates, groupErrorStates: $groupErrorStates, isLoading: $isLoading, error: $error, sendingStates: $sendingStates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatStateImpl &&
            const DeepCollectionEquality().equals(
              other._groupMessages,
              _groupMessages,
            ) &&
            (identical(other.selectedGroupId, selectedGroupId) ||
                other.selectedGroupId == selectedGroupId) &&
            const DeepCollectionEquality().equals(
              other._groupLoadingStates,
              _groupLoadingStates,
            ) &&
            const DeepCollectionEquality().equals(
              other._groupErrorStates,
              _groupErrorStates,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error) &&
            const DeepCollectionEquality().equals(
              other._sendingStates,
              _sendingStates,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_groupMessages),
    selectedGroupId,
    const DeepCollectionEquality().hash(_groupLoadingStates),
    const DeepCollectionEquality().hash(_groupErrorStates),
    isLoading,
    error,
    const DeepCollectionEquality().hash(_sendingStates),
  );

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      __$$ChatStateImplCopyWithImpl<_$ChatStateImpl>(this, _$identity);
}

abstract class _ChatState extends ChatState {
  const factory _ChatState({
    final Map<String, List<MessageWithTokensData>> groupMessages,
    final String? selectedGroupId,
    final Map<String, bool> groupLoadingStates,
    final Map<String, String?> groupErrorStates,
    final bool isLoading,
    final String? error,
    final Map<String, bool> sendingStates,
  }) = _$ChatStateImpl;
  const _ChatState._() : super._();

  // Map of groupId -> list of messages
  @override
  Map<String, List<MessageWithTokensData>> get groupMessages; // Currently selected group ID
  @override
  String? get selectedGroupId; // Loading states per group
  @override
  Map<String, bool> get groupLoadingStates; // Error states per group
  @override
  Map<String, String?> get groupErrorStates; // Global loading state
  @override
  bool get isLoading; // Global error state
  @override
  String? get error; // Sending message states per group
  @override
  Map<String, bool> get sendingStates;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatStateImplCopyWith<_$ChatStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
