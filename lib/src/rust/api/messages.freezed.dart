// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messages.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MessageStreamItem {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<ChatMessage> messages) initialSnapshot,
    required TResult Function(MessageUpdate update) update,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<ChatMessage> messages)? initialSnapshot,
    TResult? Function(MessageUpdate update)? update,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<ChatMessage> messages)? initialSnapshot,
    TResult Function(MessageUpdate update)? update,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageStreamItem_InitialSnapshot value) initialSnapshot,
    required TResult Function(MessageStreamItem_Update value) update,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult? Function(MessageStreamItem_Update value)? update,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult Function(MessageStreamItem_Update value)? update,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageStreamItemCopyWith<$Res> {
  factory $MessageStreamItemCopyWith(
    MessageStreamItem value,
    $Res Function(MessageStreamItem) then,
  ) = _$MessageStreamItemCopyWithImpl<$Res, MessageStreamItem>;
}

/// @nodoc
class _$MessageStreamItemCopyWithImpl<$Res, $Val extends MessageStreamItem>
    implements $MessageStreamItemCopyWith<$Res> {
  _$MessageStreamItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MessageStreamItem_InitialSnapshotImplCopyWith<$Res> {
  factory _$$MessageStreamItem_InitialSnapshotImplCopyWith(
    _$MessageStreamItem_InitialSnapshotImpl value,
    $Res Function(_$MessageStreamItem_InitialSnapshotImpl) then,
  ) = __$$MessageStreamItem_InitialSnapshotImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<ChatMessage> messages});
}

/// @nodoc
class __$$MessageStreamItem_InitialSnapshotImplCopyWithImpl<$Res>
    extends _$MessageStreamItemCopyWithImpl<$Res, _$MessageStreamItem_InitialSnapshotImpl>
    implements _$$MessageStreamItem_InitialSnapshotImplCopyWith<$Res> {
  __$$MessageStreamItem_InitialSnapshotImplCopyWithImpl(
    _$MessageStreamItem_InitialSnapshotImpl _value,
    $Res Function(_$MessageStreamItem_InitialSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messages = null}) {
    return _then(
      _$MessageStreamItem_InitialSnapshotImpl(
        messages:
            null == messages
                ? _value._messages
                : messages // ignore: cast_nullable_to_non_nullable
                    as List<ChatMessage>,
      ),
    );
  }
}

/// @nodoc

class _$MessageStreamItem_InitialSnapshotImpl extends MessageStreamItem_InitialSnapshot {
  const _$MessageStreamItem_InitialSnapshotImpl({
    required final List<ChatMessage> messages,
  }) : _messages = messages,
       super._();

  final List<ChatMessage> _messages;
  @override
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  String toString() {
    return 'MessageStreamItem.initialSnapshot(messages: $messages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStreamItem_InitialSnapshotImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages));
  }

  @override
  int get hashCode => Object.hash(runtimeType, const DeepCollectionEquality().hash(_messages));

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStreamItem_InitialSnapshotImplCopyWith<_$MessageStreamItem_InitialSnapshotImpl>
  get copyWith => __$$MessageStreamItem_InitialSnapshotImplCopyWithImpl<
    _$MessageStreamItem_InitialSnapshotImpl
  >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<ChatMessage> messages) initialSnapshot,
    required TResult Function(MessageUpdate update) update,
  }) {
    return initialSnapshot(messages);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<ChatMessage> messages)? initialSnapshot,
    TResult? Function(MessageUpdate update)? update,
  }) {
    return initialSnapshot?.call(messages);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<ChatMessage> messages)? initialSnapshot,
    TResult Function(MessageUpdate update)? update,
    required TResult orElse(),
  }) {
    if (initialSnapshot != null) {
      return initialSnapshot(messages);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageStreamItem_InitialSnapshot value) initialSnapshot,
    required TResult Function(MessageStreamItem_Update value) update,
  }) {
    return initialSnapshot(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult? Function(MessageStreamItem_Update value)? update,
  }) {
    return initialSnapshot?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult Function(MessageStreamItem_Update value)? update,
    required TResult orElse(),
  }) {
    if (initialSnapshot != null) {
      return initialSnapshot(this);
    }
    return orElse();
  }
}

abstract class MessageStreamItem_InitialSnapshot extends MessageStreamItem {
  const factory MessageStreamItem_InitialSnapshot({
    required final List<ChatMessage> messages,
  }) = _$MessageStreamItem_InitialSnapshotImpl;
  const MessageStreamItem_InitialSnapshot._() : super._();

  List<ChatMessage> get messages;

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageStreamItem_InitialSnapshotImplCopyWith<_$MessageStreamItem_InitialSnapshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageStreamItem_UpdateImplCopyWith<$Res> {
  factory _$$MessageStreamItem_UpdateImplCopyWith(
    _$MessageStreamItem_UpdateImpl value,
    $Res Function(_$MessageStreamItem_UpdateImpl) then,
  ) = __$$MessageStreamItem_UpdateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MessageUpdate update});
}

/// @nodoc
class __$$MessageStreamItem_UpdateImplCopyWithImpl<$Res>
    extends _$MessageStreamItemCopyWithImpl<$Res, _$MessageStreamItem_UpdateImpl>
    implements _$$MessageStreamItem_UpdateImplCopyWith<$Res> {
  __$$MessageStreamItem_UpdateImplCopyWithImpl(
    _$MessageStreamItem_UpdateImpl _value,
    $Res Function(_$MessageStreamItem_UpdateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? update = null}) {
    return _then(
      _$MessageStreamItem_UpdateImpl(
        update:
            null == update
                ? _value.update
                : update // ignore: cast_nullable_to_non_nullable
                    as MessageUpdate,
      ),
    );
  }
}

/// @nodoc

class _$MessageStreamItem_UpdateImpl extends MessageStreamItem_Update {
  const _$MessageStreamItem_UpdateImpl({required this.update}) : super._();

  @override
  final MessageUpdate update;

  @override
  String toString() {
    return 'MessageStreamItem.update(update: $update)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageStreamItem_UpdateImpl &&
            (identical(other.update, update) || other.update == update));
  }

  @override
  int get hashCode => Object.hash(runtimeType, update);

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageStreamItem_UpdateImplCopyWith<_$MessageStreamItem_UpdateImpl> get copyWith =>
      __$$MessageStreamItem_UpdateImplCopyWithImpl<_$MessageStreamItem_UpdateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(List<ChatMessage> messages) initialSnapshot,
    required TResult Function(MessageUpdate update) update,
  }) {
    return update(this.update);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(List<ChatMessage> messages)? initialSnapshot,
    TResult? Function(MessageUpdate update)? update,
  }) {
    return update?.call(this.update);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(List<ChatMessage> messages)? initialSnapshot,
    TResult Function(MessageUpdate update)? update,
    required TResult orElse(),
  }) {
    if (update != null) {
      return update(this.update);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageStreamItem_InitialSnapshot value) initialSnapshot,
    required TResult Function(MessageStreamItem_Update value) update,
  }) {
    return update(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult? Function(MessageStreamItem_Update value)? update,
  }) {
    return update?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageStreamItem_InitialSnapshot value)? initialSnapshot,
    TResult Function(MessageStreamItem_Update value)? update,
    required TResult orElse(),
  }) {
    if (update != null) {
      return update(this);
    }
    return orElse();
  }
}

abstract class MessageStreamItem_Update extends MessageStreamItem {
  const factory MessageStreamItem_Update({
    required final MessageUpdate update,
  }) = _$MessageStreamItem_UpdateImpl;
  const MessageStreamItem_Update._() : super._();

  MessageUpdate get update;

  /// Create a copy of MessageStreamItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageStreamItem_UpdateImplCopyWith<_$MessageStreamItem_UpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
