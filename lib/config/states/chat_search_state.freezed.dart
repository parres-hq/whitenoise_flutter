// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatSearchState {
  String get query => throw _privateConstructorUsedError;
  bool get isSearchActive => throw _privateConstructorUsedError;
  List<SearchMatch> get matches => throw _privateConstructorUsedError;
  int get currentMatchIndex => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of ChatSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatSearchStateCopyWith<ChatSearchState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatSearchStateCopyWith<$Res> {
  factory $ChatSearchStateCopyWith(
    ChatSearchState value,
    $Res Function(ChatSearchState) then,
  ) = _$ChatSearchStateCopyWithImpl<$Res, ChatSearchState>;
  @useResult
  $Res call({
    String query,
    bool isSearchActive,
    List<SearchMatch> matches,
    int currentMatchIndex,
    bool isLoading,
  });
}

/// @nodoc
class _$ChatSearchStateCopyWithImpl<$Res, $Val extends ChatSearchState>
    implements $ChatSearchStateCopyWith<$Res> {
  _$ChatSearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? isSearchActive = null,
    Object? matches = null,
    Object? currentMatchIndex = null,
    Object? isLoading = null,
  }) {
    return _then(
      _value.copyWith(
            query:
                null == query
                    ? _value.query
                    : query // ignore: cast_nullable_to_non_nullable
                        as String,
            isSearchActive:
                null == isSearchActive
                    ? _value.isSearchActive
                    : isSearchActive // ignore: cast_nullable_to_non_nullable
                        as bool,
            matches:
                null == matches
                    ? _value.matches
                    : matches // ignore: cast_nullable_to_non_nullable
                        as List<SearchMatch>,
            currentMatchIndex:
                null == currentMatchIndex
                    ? _value.currentMatchIndex
                    : currentMatchIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            isLoading:
                null == isLoading
                    ? _value.isLoading
                    : isLoading // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatSearchStateImplCopyWith<$Res>
    implements $ChatSearchStateCopyWith<$Res> {
  factory _$$ChatSearchStateImplCopyWith(
    _$ChatSearchStateImpl value,
    $Res Function(_$ChatSearchStateImpl) then,
  ) = __$$ChatSearchStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String query,
    bool isSearchActive,
    List<SearchMatch> matches,
    int currentMatchIndex,
    bool isLoading,
  });
}

/// @nodoc
class __$$ChatSearchStateImplCopyWithImpl<$Res>
    extends _$ChatSearchStateCopyWithImpl<$Res, _$ChatSearchStateImpl>
    implements _$$ChatSearchStateImplCopyWith<$Res> {
  __$$ChatSearchStateImplCopyWithImpl(
    _$ChatSearchStateImpl _value,
    $Res Function(_$ChatSearchStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = null,
    Object? isSearchActive = null,
    Object? matches = null,
    Object? currentMatchIndex = null,
    Object? isLoading = null,
  }) {
    return _then(
      _$ChatSearchStateImpl(
        query:
            null == query
                ? _value.query
                : query // ignore: cast_nullable_to_non_nullable
                    as String,
        isSearchActive:
            null == isSearchActive
                ? _value.isSearchActive
                : isSearchActive // ignore: cast_nullable_to_non_nullable
                    as bool,
        matches:
            null == matches
                ? _value._matches
                : matches // ignore: cast_nullable_to_non_nullable
                    as List<SearchMatch>,
        currentMatchIndex:
            null == currentMatchIndex
                ? _value.currentMatchIndex
                : currentMatchIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        isLoading:
            null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$ChatSearchStateImpl implements _ChatSearchState {
  const _$ChatSearchStateImpl({
    this.query = '',
    this.isSearchActive = false,
    final List<SearchMatch> matches = const [],
    this.currentMatchIndex = 0,
    this.isLoading = false,
  }) : _matches = matches;

  @override
  @JsonKey()
  final String query;
  @override
  @JsonKey()
  final bool isSearchActive;
  final List<SearchMatch> _matches;
  @override
  @JsonKey()
  List<SearchMatch> get matches {
    if (_matches is EqualUnmodifiableListView) return _matches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_matches);
  }

  @override
  @JsonKey()
  final int currentMatchIndex;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ChatSearchState(query: $query, isSearchActive: $isSearchActive, matches: $matches, currentMatchIndex: $currentMatchIndex, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatSearchStateImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.isSearchActive, isSearchActive) ||
                other.isSearchActive == isSearchActive) &&
            const DeepCollectionEquality().equals(other._matches, _matches) &&
            (identical(other.currentMatchIndex, currentMatchIndex) ||
                other.currentMatchIndex == currentMatchIndex) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    isSearchActive,
    const DeepCollectionEquality().hash(_matches),
    currentMatchIndex,
    isLoading,
  );

  /// Create a copy of ChatSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatSearchStateImplCopyWith<_$ChatSearchStateImpl> get copyWith =>
      __$$ChatSearchStateImplCopyWithImpl<_$ChatSearchStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ChatSearchState implements ChatSearchState {
  const factory _ChatSearchState({
    final String query,
    final bool isSearchActive,
    final List<SearchMatch> matches,
    final int currentMatchIndex,
    final bool isLoading,
  }) = _$ChatSearchStateImpl;

  @override
  String get query;
  @override
  bool get isSearchActive;
  @override
  List<SearchMatch> get matches;
  @override
  int get currentMatchIndex;
  @override
  bool get isLoading;

  /// Create a copy of ChatSearchState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatSearchStateImplCopyWith<_$ChatSearchStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SearchMatch {
  String get messageId => throw _privateConstructorUsedError;
  int get messageIndex => throw _privateConstructorUsedError;
  String get messageContent => throw _privateConstructorUsedError;
  List<TextMatch> get textMatches => throw _privateConstructorUsedError;

  /// Create a copy of SearchMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SearchMatchCopyWith<SearchMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchMatchCopyWith<$Res> {
  factory $SearchMatchCopyWith(
    SearchMatch value,
    $Res Function(SearchMatch) then,
  ) = _$SearchMatchCopyWithImpl<$Res, SearchMatch>;
  @useResult
  $Res call({
    String messageId,
    int messageIndex,
    String messageContent,
    List<TextMatch> textMatches,
  });
}

/// @nodoc
class _$SearchMatchCopyWithImpl<$Res, $Val extends SearchMatch>
    implements $SearchMatchCopyWith<$Res> {
  _$SearchMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? messageIndex = null,
    Object? messageContent = null,
    Object? textMatches = null,
  }) {
    return _then(
      _value.copyWith(
            messageId:
                null == messageId
                    ? _value.messageId
                    : messageId // ignore: cast_nullable_to_non_nullable
                        as String,
            messageIndex:
                null == messageIndex
                    ? _value.messageIndex
                    : messageIndex // ignore: cast_nullable_to_non_nullable
                        as int,
            messageContent:
                null == messageContent
                    ? _value.messageContent
                    : messageContent // ignore: cast_nullable_to_non_nullable
                        as String,
            textMatches:
                null == textMatches
                    ? _value.textMatches
                    : textMatches // ignore: cast_nullable_to_non_nullable
                        as List<TextMatch>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SearchMatchImplCopyWith<$Res>
    implements $SearchMatchCopyWith<$Res> {
  factory _$$SearchMatchImplCopyWith(
    _$SearchMatchImpl value,
    $Res Function(_$SearchMatchImpl) then,
  ) = __$$SearchMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String messageId,
    int messageIndex,
    String messageContent,
    List<TextMatch> textMatches,
  });
}

/// @nodoc
class __$$SearchMatchImplCopyWithImpl<$Res>
    extends _$SearchMatchCopyWithImpl<$Res, _$SearchMatchImpl>
    implements _$$SearchMatchImplCopyWith<$Res> {
  __$$SearchMatchImplCopyWithImpl(
    _$SearchMatchImpl _value,
    $Res Function(_$SearchMatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? messageIndex = null,
    Object? messageContent = null,
    Object? textMatches = null,
  }) {
    return _then(
      _$SearchMatchImpl(
        messageId:
            null == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                    as String,
        messageIndex:
            null == messageIndex
                ? _value.messageIndex
                : messageIndex // ignore: cast_nullable_to_non_nullable
                    as int,
        messageContent:
            null == messageContent
                ? _value.messageContent
                : messageContent // ignore: cast_nullable_to_non_nullable
                    as String,
        textMatches:
            null == textMatches
                ? _value._textMatches
                : textMatches // ignore: cast_nullable_to_non_nullable
                    as List<TextMatch>,
      ),
    );
  }
}

/// @nodoc

class _$SearchMatchImpl implements _SearchMatch {
  const _$SearchMatchImpl({
    required this.messageId,
    required this.messageIndex,
    required this.messageContent,
    required final List<TextMatch> textMatches,
  }) : _textMatches = textMatches;

  @override
  final String messageId;
  @override
  final int messageIndex;
  @override
  final String messageContent;
  final List<TextMatch> _textMatches;
  @override
  List<TextMatch> get textMatches {
    if (_textMatches is EqualUnmodifiableListView) return _textMatches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_textMatches);
  }

  @override
  String toString() {
    return 'SearchMatch(messageId: $messageId, messageIndex: $messageIndex, messageContent: $messageContent, textMatches: $textMatches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchMatchImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.messageIndex, messageIndex) ||
                other.messageIndex == messageIndex) &&
            (identical(other.messageContent, messageContent) ||
                other.messageContent == messageContent) &&
            const DeepCollectionEquality().equals(
              other._textMatches,
              _textMatches,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    messageId,
    messageIndex,
    messageContent,
    const DeepCollectionEquality().hash(_textMatches),
  );

  /// Create a copy of SearchMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchMatchImplCopyWith<_$SearchMatchImpl> get copyWith =>
      __$$SearchMatchImplCopyWithImpl<_$SearchMatchImpl>(this, _$identity);
}

abstract class _SearchMatch implements SearchMatch {
  const factory _SearchMatch({
    required final String messageId,
    required final int messageIndex,
    required final String messageContent,
    required final List<TextMatch> textMatches,
  }) = _$SearchMatchImpl;

  @override
  String get messageId;
  @override
  int get messageIndex;
  @override
  String get messageContent;
  @override
  List<TextMatch> get textMatches;

  /// Create a copy of SearchMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchMatchImplCopyWith<_$SearchMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TextMatch {
  int get start => throw _privateConstructorUsedError;
  int get end => throw _privateConstructorUsedError;
  String get matchedText => throw _privateConstructorUsedError;

  /// Create a copy of TextMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TextMatchCopyWith<TextMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TextMatchCopyWith<$Res> {
  factory $TextMatchCopyWith(TextMatch value, $Res Function(TextMatch) then) =
      _$TextMatchCopyWithImpl<$Res, TextMatch>;
  @useResult
  $Res call({int start, int end, String matchedText});
}

/// @nodoc
class _$TextMatchCopyWithImpl<$Res, $Val extends TextMatch>
    implements $TextMatchCopyWith<$Res> {
  _$TextMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TextMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? matchedText = null,
  }) {
    return _then(
      _value.copyWith(
            start:
                null == start
                    ? _value.start
                    : start // ignore: cast_nullable_to_non_nullable
                        as int,
            end:
                null == end
                    ? _value.end
                    : end // ignore: cast_nullable_to_non_nullable
                        as int,
            matchedText:
                null == matchedText
                    ? _value.matchedText
                    : matchedText // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TextMatchImplCopyWith<$Res>
    implements $TextMatchCopyWith<$Res> {
  factory _$$TextMatchImplCopyWith(
    _$TextMatchImpl value,
    $Res Function(_$TextMatchImpl) then,
  ) = __$$TextMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int start, int end, String matchedText});
}

/// @nodoc
class __$$TextMatchImplCopyWithImpl<$Res>
    extends _$TextMatchCopyWithImpl<$Res, _$TextMatchImpl>
    implements _$$TextMatchImplCopyWith<$Res> {
  __$$TextMatchImplCopyWithImpl(
    _$TextMatchImpl _value,
    $Res Function(_$TextMatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TextMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? start = null,
    Object? end = null,
    Object? matchedText = null,
  }) {
    return _then(
      _$TextMatchImpl(
        start:
            null == start
                ? _value.start
                : start // ignore: cast_nullable_to_non_nullable
                    as int,
        end:
            null == end
                ? _value.end
                : end // ignore: cast_nullable_to_non_nullable
                    as int,
        matchedText:
            null == matchedText
                ? _value.matchedText
                : matchedText // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$TextMatchImpl implements _TextMatch {
  const _$TextMatchImpl({
    required this.start,
    required this.end,
    required this.matchedText,
  });

  @override
  final int start;
  @override
  final int end;
  @override
  final String matchedText;

  @override
  String toString() {
    return 'TextMatch(start: $start, end: $end, matchedText: $matchedText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextMatchImpl &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.matchedText, matchedText) ||
                other.matchedText == matchedText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, start, end, matchedText);

  /// Create a copy of TextMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextMatchImplCopyWith<_$TextMatchImpl> get copyWith =>
      __$$TextMatchImplCopyWithImpl<_$TextMatchImpl>(this, _$identity);
}

abstract class _TextMatch implements TextMatch {
  const factory _TextMatch({
    required final int start,
    required final int end,
    required final String matchedText,
  }) = _$TextMatchImpl;

  @override
  int get start;
  @override
  int get end;
  @override
  String get matchedText;

  /// Create a copy of TextMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextMatchImplCopyWith<_$TextMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
