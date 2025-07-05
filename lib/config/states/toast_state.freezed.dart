// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'toast_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ToastMessage {
  String get id => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  ToastType get type => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;
  bool get autoDismiss => throw _privateConstructorUsedError;
  bool get showBelowAppBar => throw _privateConstructorUsedError;

  /// Create a copy of ToastMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToastMessageCopyWith<ToastMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToastMessageCopyWith<$Res> {
  factory $ToastMessageCopyWith(
    ToastMessage value,
    $Res Function(ToastMessage) then,
  ) = _$ToastMessageCopyWithImpl<$Res, ToastMessage>;
  @useResult
  $Res call({
    String id,
    String message,
    ToastType type,
    int durationMs,
    bool autoDismiss,
    bool showBelowAppBar,
  });
}

/// @nodoc
class _$ToastMessageCopyWithImpl<$Res, $Val extends ToastMessage>
    implements $ToastMessageCopyWith<$Res> {
  _$ToastMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToastMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? message = null,
    Object? type = null,
    Object? durationMs = null,
    Object? autoDismiss = null,
    Object? showBelowAppBar = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as ToastType,
            durationMs:
                null == durationMs
                    ? _value.durationMs
                    : durationMs // ignore: cast_nullable_to_non_nullable
                        as int,
            autoDismiss:
                null == autoDismiss
                    ? _value.autoDismiss
                    : autoDismiss // ignore: cast_nullable_to_non_nullable
                        as bool,
            showBelowAppBar:
                null == showBelowAppBar
                    ? _value.showBelowAppBar
                    : showBelowAppBar // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ToastMessageImplCopyWith<$Res>
    implements $ToastMessageCopyWith<$Res> {
  factory _$$ToastMessageImplCopyWith(
    _$ToastMessageImpl value,
    $Res Function(_$ToastMessageImpl) then,
  ) = __$$ToastMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String message,
    ToastType type,
    int durationMs,
    bool autoDismiss,
    bool showBelowAppBar,
  });
}

/// @nodoc
class __$$ToastMessageImplCopyWithImpl<$Res>
    extends _$ToastMessageCopyWithImpl<$Res, _$ToastMessageImpl>
    implements _$$ToastMessageImplCopyWith<$Res> {
  __$$ToastMessageImplCopyWithImpl(
    _$ToastMessageImpl _value,
    $Res Function(_$ToastMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ToastMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? message = null,
    Object? type = null,
    Object? durationMs = null,
    Object? autoDismiss = null,
    Object? showBelowAppBar = null,
  }) {
    return _then(
      _$ToastMessageImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as ToastType,
        durationMs:
            null == durationMs
                ? _value.durationMs
                : durationMs // ignore: cast_nullable_to_non_nullable
                    as int,
        autoDismiss:
            null == autoDismiss
                ? _value.autoDismiss
                : autoDismiss // ignore: cast_nullable_to_non_nullable
                    as bool,
        showBelowAppBar:
            null == showBelowAppBar
                ? _value.showBelowAppBar
                : showBelowAppBar // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$ToastMessageImpl implements _ToastMessage {
  const _$ToastMessageImpl({
    required this.id,
    required this.message,
    required this.type,
    this.durationMs = 8000,
    this.autoDismiss = true,
    this.showBelowAppBar = false,
  });

  @override
  final String id;
  @override
  final String message;
  @override
  final ToastType type;
  @override
  @JsonKey()
  final int durationMs;
  @override
  @JsonKey()
  final bool autoDismiss;
  @override
  @JsonKey()
  final bool showBelowAppBar;

  @override
  String toString() {
    return 'ToastMessage(id: $id, message: $message, type: $type, durationMs: $durationMs, autoDismiss: $autoDismiss, showBelowAppBar: $showBelowAppBar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToastMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.autoDismiss, autoDismiss) ||
                other.autoDismiss == autoDismiss) &&
            (identical(other.showBelowAppBar, showBelowAppBar) ||
                other.showBelowAppBar == showBelowAppBar));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    message,
    type,
    durationMs,
    autoDismiss,
    showBelowAppBar,
  );

  /// Create a copy of ToastMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToastMessageImplCopyWith<_$ToastMessageImpl> get copyWith =>
      __$$ToastMessageImplCopyWithImpl<_$ToastMessageImpl>(this, _$identity);
}

abstract class _ToastMessage implements ToastMessage {
  const factory _ToastMessage({
    required final String id,
    required final String message,
    required final ToastType type,
    final int durationMs,
    final bool autoDismiss,
    final bool showBelowAppBar,
  }) = _$ToastMessageImpl;

  @override
  String get id;
  @override
  String get message;
  @override
  ToastType get type;
  @override
  int get durationMs;
  @override
  bool get autoDismiss;
  @override
  bool get showBelowAppBar;

  /// Create a copy of ToastMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToastMessageImplCopyWith<_$ToastMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ToastConfig {
  ToastStackMode get stackMode => throw _privateConstructorUsedError;
  int get defaultDurationMs => throw _privateConstructorUsedError;
  bool get autoDismiss => throw _privateConstructorUsedError;
  bool get defaultShowBelowAppBar => throw _privateConstructorUsedError;

  /// Create a copy of ToastConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToastConfigCopyWith<ToastConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToastConfigCopyWith<$Res> {
  factory $ToastConfigCopyWith(
    ToastConfig value,
    $Res Function(ToastConfig) then,
  ) = _$ToastConfigCopyWithImpl<$Res, ToastConfig>;
  @useResult
  $Res call({
    ToastStackMode stackMode,
    int defaultDurationMs,
    bool autoDismiss,
    bool defaultShowBelowAppBar,
  });
}

/// @nodoc
class _$ToastConfigCopyWithImpl<$Res, $Val extends ToastConfig>
    implements $ToastConfigCopyWith<$Res> {
  _$ToastConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToastConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stackMode = null,
    Object? defaultDurationMs = null,
    Object? autoDismiss = null,
    Object? defaultShowBelowAppBar = null,
  }) {
    return _then(
      _value.copyWith(
            stackMode:
                null == stackMode
                    ? _value.stackMode
                    : stackMode // ignore: cast_nullable_to_non_nullable
                        as ToastStackMode,
            defaultDurationMs:
                null == defaultDurationMs
                    ? _value.defaultDurationMs
                    : defaultDurationMs // ignore: cast_nullable_to_non_nullable
                        as int,
            autoDismiss:
                null == autoDismiss
                    ? _value.autoDismiss
                    : autoDismiss // ignore: cast_nullable_to_non_nullable
                        as bool,
            defaultShowBelowAppBar:
                null == defaultShowBelowAppBar
                    ? _value.defaultShowBelowAppBar
                    : defaultShowBelowAppBar // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ToastConfigImplCopyWith<$Res>
    implements $ToastConfigCopyWith<$Res> {
  factory _$$ToastConfigImplCopyWith(
    _$ToastConfigImpl value,
    $Res Function(_$ToastConfigImpl) then,
  ) = __$$ToastConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ToastStackMode stackMode,
    int defaultDurationMs,
    bool autoDismiss,
    bool defaultShowBelowAppBar,
  });
}

/// @nodoc
class __$$ToastConfigImplCopyWithImpl<$Res>
    extends _$ToastConfigCopyWithImpl<$Res, _$ToastConfigImpl>
    implements _$$ToastConfigImplCopyWith<$Res> {
  __$$ToastConfigImplCopyWithImpl(
    _$ToastConfigImpl _value,
    $Res Function(_$ToastConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ToastConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stackMode = null,
    Object? defaultDurationMs = null,
    Object? autoDismiss = null,
    Object? defaultShowBelowAppBar = null,
  }) {
    return _then(
      _$ToastConfigImpl(
        stackMode:
            null == stackMode
                ? _value.stackMode
                : stackMode // ignore: cast_nullable_to_non_nullable
                    as ToastStackMode,
        defaultDurationMs:
            null == defaultDurationMs
                ? _value.defaultDurationMs
                : defaultDurationMs // ignore: cast_nullable_to_non_nullable
                    as int,
        autoDismiss:
            null == autoDismiss
                ? _value.autoDismiss
                : autoDismiss // ignore: cast_nullable_to_non_nullable
                    as bool,
        defaultShowBelowAppBar:
            null == defaultShowBelowAppBar
                ? _value.defaultShowBelowAppBar
                : defaultShowBelowAppBar // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$ToastConfigImpl implements _ToastConfig {
  const _$ToastConfigImpl({
    this.stackMode = ToastStackMode.replace,
    this.defaultDurationMs = 8000,
    this.autoDismiss = true,
    this.defaultShowBelowAppBar = false,
  });

  @override
  @JsonKey()
  final ToastStackMode stackMode;
  @override
  @JsonKey()
  final int defaultDurationMs;
  @override
  @JsonKey()
  final bool autoDismiss;
  @override
  @JsonKey()
  final bool defaultShowBelowAppBar;

  @override
  String toString() {
    return 'ToastConfig(stackMode: $stackMode, defaultDurationMs: $defaultDurationMs, autoDismiss: $autoDismiss, defaultShowBelowAppBar: $defaultShowBelowAppBar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToastConfigImpl &&
            (identical(other.stackMode, stackMode) ||
                other.stackMode == stackMode) &&
            (identical(other.defaultDurationMs, defaultDurationMs) ||
                other.defaultDurationMs == defaultDurationMs) &&
            (identical(other.autoDismiss, autoDismiss) ||
                other.autoDismiss == autoDismiss) &&
            (identical(other.defaultShowBelowAppBar, defaultShowBelowAppBar) ||
                other.defaultShowBelowAppBar == defaultShowBelowAppBar));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    stackMode,
    defaultDurationMs,
    autoDismiss,
    defaultShowBelowAppBar,
  );

  /// Create a copy of ToastConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToastConfigImplCopyWith<_$ToastConfigImpl> get copyWith =>
      __$$ToastConfigImplCopyWithImpl<_$ToastConfigImpl>(this, _$identity);
}

abstract class _ToastConfig implements ToastConfig {
  const factory _ToastConfig({
    final ToastStackMode stackMode,
    final int defaultDurationMs,
    final bool autoDismiss,
    final bool defaultShowBelowAppBar,
  }) = _$ToastConfigImpl;

  @override
  ToastStackMode get stackMode;
  @override
  int get defaultDurationMs;
  @override
  bool get autoDismiss;
  @override
  bool get defaultShowBelowAppBar;

  /// Create a copy of ToastConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToastConfigImplCopyWith<_$ToastConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ToastState {
  List<ToastMessage> get messages => throw _privateConstructorUsedError;
  ToastConfig get config => throw _privateConstructorUsedError;

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ToastStateCopyWith<ToastState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ToastStateCopyWith<$Res> {
  factory $ToastStateCopyWith(
    ToastState value,
    $Res Function(ToastState) then,
  ) = _$ToastStateCopyWithImpl<$Res, ToastState>;
  @useResult
  $Res call({List<ToastMessage> messages, ToastConfig config});

  $ToastConfigCopyWith<$Res> get config;
}

/// @nodoc
class _$ToastStateCopyWithImpl<$Res, $Val extends ToastState>
    implements $ToastStateCopyWith<$Res> {
  _$ToastStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messages = null, Object? config = null}) {
    return _then(
      _value.copyWith(
            messages:
                null == messages
                    ? _value.messages
                    : messages // ignore: cast_nullable_to_non_nullable
                        as List<ToastMessage>,
            config:
                null == config
                    ? _value.config
                    : config // ignore: cast_nullable_to_non_nullable
                        as ToastConfig,
          )
          as $Val,
    );
  }

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ToastConfigCopyWith<$Res> get config {
    return $ToastConfigCopyWith<$Res>(_value.config, (value) {
      return _then(_value.copyWith(config: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ToastStateImplCopyWith<$Res>
    implements $ToastStateCopyWith<$Res> {
  factory _$$ToastStateImplCopyWith(
    _$ToastStateImpl value,
    $Res Function(_$ToastStateImpl) then,
  ) = __$$ToastStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<ToastMessage> messages, ToastConfig config});

  @override
  $ToastConfigCopyWith<$Res> get config;
}

/// @nodoc
class __$$ToastStateImplCopyWithImpl<$Res>
    extends _$ToastStateCopyWithImpl<$Res, _$ToastStateImpl>
    implements _$$ToastStateImplCopyWith<$Res> {
  __$$ToastStateImplCopyWithImpl(
    _$ToastStateImpl _value,
    $Res Function(_$ToastStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? messages = null, Object? config = null}) {
    return _then(
      _$ToastStateImpl(
        messages:
            null == messages
                ? _value._messages
                : messages // ignore: cast_nullable_to_non_nullable
                    as List<ToastMessage>,
        config:
            null == config
                ? _value.config
                : config // ignore: cast_nullable_to_non_nullable
                    as ToastConfig,
      ),
    );
  }
}

/// @nodoc

class _$ToastStateImpl extends _ToastState {
  const _$ToastStateImpl({
    final List<ToastMessage> messages = const [],
    this.config = const ToastConfig(),
  }) : _messages = messages,
       super._();

  final List<ToastMessage> _messages;
  @override
  @JsonKey()
  List<ToastMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  @JsonKey()
  final ToastConfig config;

  @override
  String toString() {
    return 'ToastState(messages: $messages, config: $config)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ToastStateImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.config, config) || other.config == config));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_messages),
    config,
  );

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ToastStateImplCopyWith<_$ToastStateImpl> get copyWith =>
      __$$ToastStateImplCopyWithImpl<_$ToastStateImpl>(this, _$identity);
}

abstract class _ToastState extends ToastState {
  const factory _ToastState({
    final List<ToastMessage> messages,
    final ToastConfig config,
  }) = _$ToastStateImpl;
  const _ToastState._() : super._();

  @override
  List<ToastMessage> get messages;
  @override
  ToastConfig get config;

  /// Create a copy of ToastState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ToastStateImplCopyWith<_$ToastStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
