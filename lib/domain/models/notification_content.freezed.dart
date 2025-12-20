// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NotificationContent {
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String get groupKey => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;

  /// Create a copy of NotificationContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationContentCopyWith<NotificationContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationContentCopyWith<$Res> {
  factory $NotificationContentCopyWith(
    NotificationContent value,
    $Res Function(NotificationContent) then,
  ) = _$NotificationContentCopyWithImpl<$Res, NotificationContent>;
  @useResult
  $Res call({
    String title,
    String body,
    String groupKey,
    Map<String, dynamic> payload,
  });
}

/// @nodoc
class _$NotificationContentCopyWithImpl<$Res, $Val extends NotificationContent>
    implements $NotificationContentCopyWith<$Res> {
  _$NotificationContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? body = null,
    Object? groupKey = null,
    Object? payload = null,
  }) {
    return _then(
      _value.copyWith(
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            body:
                null == body
                    ? _value.body
                    : body // ignore: cast_nullable_to_non_nullable
                        as String,
            groupKey:
                null == groupKey
                    ? _value.groupKey
                    : groupKey // ignore: cast_nullable_to_non_nullable
                        as String,
            payload:
                null == payload
                    ? _value.payload
                    : payload // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationContentImplCopyWith<$Res>
    implements $NotificationContentCopyWith<$Res> {
  factory _$$NotificationContentImplCopyWith(
    _$NotificationContentImpl value,
    $Res Function(_$NotificationContentImpl) then,
  ) = __$$NotificationContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String title,
    String body,
    String groupKey,
    Map<String, dynamic> payload,
  });
}

/// @nodoc
class __$$NotificationContentImplCopyWithImpl<$Res>
    extends _$NotificationContentCopyWithImpl<$Res, _$NotificationContentImpl>
    implements _$$NotificationContentImplCopyWith<$Res> {
  __$$NotificationContentImplCopyWithImpl(
    _$NotificationContentImpl _value,
    $Res Function(_$NotificationContentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? body = null,
    Object? groupKey = null,
    Object? payload = null,
  }) {
    return _then(
      _$NotificationContentImpl(
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        body:
            null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                    as String,
        groupKey:
            null == groupKey
                ? _value.groupKey
                : groupKey // ignore: cast_nullable_to_non_nullable
                    as String,
        payload:
            null == payload
                ? _value._payload
                : payload // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc

class _$NotificationContentImpl implements _NotificationContent {
  const _$NotificationContentImpl({
    required this.title,
    required this.body,
    required this.groupKey,
    required final Map<String, dynamic> payload,
  }) : _payload = payload;

  @override
  final String title;
  @override
  final String body;
  @override
  final String groupKey;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  String toString() {
    return 'NotificationContent(title: $title, body: $body, groupKey: $groupKey, payload: $payload)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationContentImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.groupKey, groupKey) || other.groupKey == groupKey) &&
            const DeepCollectionEquality().equals(other._payload, _payload));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    body,
    groupKey,
    const DeepCollectionEquality().hash(_payload),
  );

  /// Create a copy of NotificationContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationContentImplCopyWith<_$NotificationContentImpl> get copyWith =>
      __$$NotificationContentImplCopyWithImpl<_$NotificationContentImpl>(
        this,
        _$identity,
      );
}

abstract class _NotificationContent implements NotificationContent {
  const factory _NotificationContent({
    required final String title,
    required final String body,
    required final String groupKey,
    required final Map<String, dynamic> payload,
  }) = _$NotificationContentImpl;

  @override
  String get title;
  @override
  String get body;
  @override
  String get groupKey;
  @override
  Map<String, dynamic> get payload;

  /// Create a copy of NotificationContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationContentImplCopyWith<_$NotificationContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
