// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_input_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatInputState {
  bool get isLoadingDraft => throw _privateConstructorUsedError;
  bool get showMediaSelector => throw _privateConstructorUsedError;
  List<String> get selectedImages => throw _privateConstructorUsedError;
  double? get singleLineHeight => throw _privateConstructorUsedError;
  String? get previousEditingMessageContent =>
      throw _privateConstructorUsedError;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatInputStateCopyWith<ChatInputState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatInputStateCopyWith<$Res> {
  factory $ChatInputStateCopyWith(
    ChatInputState value,
    $Res Function(ChatInputState) then,
  ) = _$ChatInputStateCopyWithImpl<$Res, ChatInputState>;
  @useResult
  $Res call({
    bool isLoadingDraft,
    bool showMediaSelector,
    List<String> selectedImages,
    double? singleLineHeight,
    String? previousEditingMessageContent,
  });
}

/// @nodoc
class _$ChatInputStateCopyWithImpl<$Res, $Val extends ChatInputState>
    implements $ChatInputStateCopyWith<$Res> {
  _$ChatInputStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingDraft = null,
    Object? showMediaSelector = null,
    Object? selectedImages = null,
    Object? singleLineHeight = freezed,
    Object? previousEditingMessageContent = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoadingDraft:
                null == isLoadingDraft
                    ? _value.isLoadingDraft
                    : isLoadingDraft // ignore: cast_nullable_to_non_nullable
                        as bool,
            showMediaSelector:
                null == showMediaSelector
                    ? _value.showMediaSelector
                    : showMediaSelector // ignore: cast_nullable_to_non_nullable
                        as bool,
            selectedImages:
                null == selectedImages
                    ? _value.selectedImages
                    : selectedImages // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            singleLineHeight:
                freezed == singleLineHeight
                    ? _value.singleLineHeight
                    : singleLineHeight // ignore: cast_nullable_to_non_nullable
                        as double?,
            previousEditingMessageContent:
                freezed == previousEditingMessageContent
                    ? _value.previousEditingMessageContent
                    : previousEditingMessageContent // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatInputStateImplCopyWith<$Res>
    implements $ChatInputStateCopyWith<$Res> {
  factory _$$ChatInputStateImplCopyWith(
    _$ChatInputStateImpl value,
    $Res Function(_$ChatInputStateImpl) then,
  ) = __$$ChatInputStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoadingDraft,
    bool showMediaSelector,
    List<String> selectedImages,
    double? singleLineHeight,
    String? previousEditingMessageContent,
  });
}

/// @nodoc
class __$$ChatInputStateImplCopyWithImpl<$Res>
    extends _$ChatInputStateCopyWithImpl<$Res, _$ChatInputStateImpl>
    implements _$$ChatInputStateImplCopyWith<$Res> {
  __$$ChatInputStateImplCopyWithImpl(
    _$ChatInputStateImpl _value,
    $Res Function(_$ChatInputStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingDraft = null,
    Object? showMediaSelector = null,
    Object? selectedImages = null,
    Object? singleLineHeight = freezed,
    Object? previousEditingMessageContent = freezed,
  }) {
    return _then(
      _$ChatInputStateImpl(
        isLoadingDraft:
            null == isLoadingDraft
                ? _value.isLoadingDraft
                : isLoadingDraft // ignore: cast_nullable_to_non_nullable
                    as bool,
        showMediaSelector:
            null == showMediaSelector
                ? _value.showMediaSelector
                : showMediaSelector // ignore: cast_nullable_to_non_nullable
                    as bool,
        selectedImages:
            null == selectedImages
                ? _value._selectedImages
                : selectedImages // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        singleLineHeight:
            freezed == singleLineHeight
                ? _value.singleLineHeight
                : singleLineHeight // ignore: cast_nullable_to_non_nullable
                    as double?,
        previousEditingMessageContent:
            freezed == previousEditingMessageContent
                ? _value.previousEditingMessageContent
                : previousEditingMessageContent // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

class _$ChatInputStateImpl implements _ChatInputState {
  const _$ChatInputStateImpl({
    this.isLoadingDraft = false,
    this.showMediaSelector = false,
    final List<String> selectedImages = const [],
    this.singleLineHeight,
    this.previousEditingMessageContent,
  }) : _selectedImages = selectedImages;

  @override
  @JsonKey()
  final bool isLoadingDraft;
  @override
  @JsonKey()
  final bool showMediaSelector;
  final List<String> _selectedImages;
  @override
  @JsonKey()
  List<String> get selectedImages {
    if (_selectedImages is EqualUnmodifiableListView) return _selectedImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedImages);
  }

  @override
  final double? singleLineHeight;
  @override
  final String? previousEditingMessageContent;

  @override
  String toString() {
    return 'ChatInputState(isLoadingDraft: $isLoadingDraft, showMediaSelector: $showMediaSelector, selectedImages: $selectedImages, singleLineHeight: $singleLineHeight, previousEditingMessageContent: $previousEditingMessageContent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInputStateImpl &&
            (identical(other.isLoadingDraft, isLoadingDraft) ||
                other.isLoadingDraft == isLoadingDraft) &&
            (identical(other.showMediaSelector, showMediaSelector) ||
                other.showMediaSelector == showMediaSelector) &&
            const DeepCollectionEquality().equals(
              other._selectedImages,
              _selectedImages,
            ) &&
            (identical(other.singleLineHeight, singleLineHeight) ||
                other.singleLineHeight == singleLineHeight) &&
            (identical(
                  other.previousEditingMessageContent,
                  previousEditingMessageContent,
                ) ||
                other.previousEditingMessageContent ==
                    previousEditingMessageContent));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoadingDraft,
    showMediaSelector,
    const DeepCollectionEquality().hash(_selectedImages),
    singleLineHeight,
    previousEditingMessageContent,
  );

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInputStateImplCopyWith<_$ChatInputStateImpl> get copyWith =>
      __$$ChatInputStateImplCopyWithImpl<_$ChatInputStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ChatInputState implements ChatInputState {
  const factory _ChatInputState({
    final bool isLoadingDraft,
    final bool showMediaSelector,
    final List<String> selectedImages,
    final double? singleLineHeight,
    final String? previousEditingMessageContent,
  }) = _$ChatInputStateImpl;

  @override
  bool get isLoadingDraft;
  @override
  bool get showMediaSelector;
  @override
  List<String> get selectedImages;
  @override
  double? get singleLineHeight;
  @override
  String? get previousEditingMessageContent;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatInputStateImplCopyWith<_$ChatInputStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
