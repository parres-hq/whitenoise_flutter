// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_file_download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MediaFileDownload {
  String get originalFileHash => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String originalFileHash, MediaFile originalFile) pending,
    required TResult Function(String originalFileHash, MediaFile originalFile) downloading,
    required TResult Function(String originalFileHash, MediaFile downloadedFile) downloaded,
    required TResult Function(String originalFileHash, MediaFile originalFile) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult? Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult? Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult? Function(String originalFileHash, MediaFile originalFile)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult Function(String originalFileHash, MediaFile originalFile)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileDownloadPending value) pending,
    required TResult Function(MediaFileDownloadInProgress value) downloading,
    required TResult Function(MediaFileDownloaded value) downloaded,
    required TResult Function(MediaFileDownloadFailed value) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileDownloadPending value)? pending,
    TResult? Function(MediaFileDownloadInProgress value)? downloading,
    TResult? Function(MediaFileDownloaded value)? downloaded,
    TResult? Function(MediaFileDownloadFailed value)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileDownloadPending value)? pending,
    TResult Function(MediaFileDownloadInProgress value)? downloading,
    TResult Function(MediaFileDownloaded value)? downloaded,
    TResult Function(MediaFileDownloadFailed value)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaFileDownloadCopyWith<MediaFileDownload> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaFileDownloadCopyWith<$Res> {
  factory $MediaFileDownloadCopyWith(
    MediaFileDownload value,
    $Res Function(MediaFileDownload) then,
  ) = _$MediaFileDownloadCopyWithImpl<$Res, MediaFileDownload>;
  @useResult
  $Res call({String originalFileHash});
}

/// @nodoc
class _$MediaFileDownloadCopyWithImpl<$Res, $Val extends MediaFileDownload>
    implements $MediaFileDownloadCopyWith<$Res> {
  _$MediaFileDownloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? originalFileHash = null}) {
    return _then(
      _value.copyWith(
            originalFileHash:
                null == originalFileHash
                    ? _value.originalFileHash
                    : originalFileHash // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MediaFileDownloadPendingImplCopyWith<$Res>
    implements $MediaFileDownloadCopyWith<$Res> {
  factory _$$MediaFileDownloadPendingImplCopyWith(
    _$MediaFileDownloadPendingImpl value,
    $Res Function(_$MediaFileDownloadPendingImpl) then,
  ) = __$$MediaFileDownloadPendingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String originalFileHash, MediaFile originalFile});
}

/// @nodoc
class __$$MediaFileDownloadPendingImplCopyWithImpl<$Res>
    extends _$MediaFileDownloadCopyWithImpl<$Res, _$MediaFileDownloadPendingImpl>
    implements _$$MediaFileDownloadPendingImplCopyWith<$Res> {
  __$$MediaFileDownloadPendingImplCopyWithImpl(
    _$MediaFileDownloadPendingImpl _value,
    $Res Function(_$MediaFileDownloadPendingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? originalFileHash = null, Object? originalFile = null}) {
    return _then(
      _$MediaFileDownloadPendingImpl(
        originalFileHash:
            null == originalFileHash
                ? _value.originalFileHash
                : originalFileHash // ignore: cast_nullable_to_non_nullable
                    as String,
        originalFile:
            null == originalFile
                ? _value.originalFile
                : originalFile // ignore: cast_nullable_to_non_nullable
                    as MediaFile,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileDownloadPendingImpl implements MediaFileDownloadPending {
  const _$MediaFileDownloadPendingImpl({
    required this.originalFileHash,
    required this.originalFile,
  });

  @override
  final String originalFileHash;
  @override
  final MediaFile originalFile;

  @override
  String toString() {
    return 'MediaFileDownload.pending(originalFileHash: $originalFileHash, originalFile: $originalFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileDownloadPendingImpl &&
            (identical(other.originalFileHash, originalFileHash) ||
                other.originalFileHash == originalFileHash) &&
            (identical(other.originalFile, originalFile) || other.originalFile == originalFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, originalFileHash, originalFile);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileDownloadPendingImplCopyWith<_$MediaFileDownloadPendingImpl> get copyWith =>
      __$$MediaFileDownloadPendingImplCopyWithImpl<_$MediaFileDownloadPendingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String originalFileHash, MediaFile originalFile) pending,
    required TResult Function(String originalFileHash, MediaFile originalFile) downloading,
    required TResult Function(String originalFileHash, MediaFile downloadedFile) downloaded,
    required TResult Function(String originalFileHash, MediaFile originalFile) failed,
  }) {
    return pending(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult? Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult? Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult? Function(String originalFileHash, MediaFile originalFile)? failed,
  }) {
    return pending?.call(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult Function(String originalFileHash, MediaFile originalFile)? failed,
    required TResult orElse(),
  }) {
    if (pending != null) {
      return pending(originalFileHash, originalFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileDownloadPending value) pending,
    required TResult Function(MediaFileDownloadInProgress value) downloading,
    required TResult Function(MediaFileDownloaded value) downloaded,
    required TResult Function(MediaFileDownloadFailed value) failed,
  }) {
    return pending(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileDownloadPending value)? pending,
    TResult? Function(MediaFileDownloadInProgress value)? downloading,
    TResult? Function(MediaFileDownloaded value)? downloaded,
    TResult? Function(MediaFileDownloadFailed value)? failed,
  }) {
    return pending?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileDownloadPending value)? pending,
    TResult Function(MediaFileDownloadInProgress value)? downloading,
    TResult Function(MediaFileDownloaded value)? downloaded,
    TResult Function(MediaFileDownloadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (pending != null) {
      return pending(this);
    }
    return orElse();
  }
}

abstract class MediaFileDownloadPending implements MediaFileDownload {
  const factory MediaFileDownloadPending({
    required final String originalFileHash,
    required final MediaFile originalFile,
  }) = _$MediaFileDownloadPendingImpl;

  @override
  String get originalFileHash;
  MediaFile get originalFile;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileDownloadPendingImplCopyWith<_$MediaFileDownloadPendingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaFileDownloadInProgressImplCopyWith<$Res>
    implements $MediaFileDownloadCopyWith<$Res> {
  factory _$$MediaFileDownloadInProgressImplCopyWith(
    _$MediaFileDownloadInProgressImpl value,
    $Res Function(_$MediaFileDownloadInProgressImpl) then,
  ) = __$$MediaFileDownloadInProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String originalFileHash, MediaFile originalFile});
}

/// @nodoc
class __$$MediaFileDownloadInProgressImplCopyWithImpl<$Res>
    extends _$MediaFileDownloadCopyWithImpl<$Res, _$MediaFileDownloadInProgressImpl>
    implements _$$MediaFileDownloadInProgressImplCopyWith<$Res> {
  __$$MediaFileDownloadInProgressImplCopyWithImpl(
    _$MediaFileDownloadInProgressImpl _value,
    $Res Function(_$MediaFileDownloadInProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? originalFileHash = null, Object? originalFile = null}) {
    return _then(
      _$MediaFileDownloadInProgressImpl(
        originalFileHash:
            null == originalFileHash
                ? _value.originalFileHash
                : originalFileHash // ignore: cast_nullable_to_non_nullable
                    as String,
        originalFile:
            null == originalFile
                ? _value.originalFile
                : originalFile // ignore: cast_nullable_to_non_nullable
                    as MediaFile,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileDownloadInProgressImpl implements MediaFileDownloadInProgress {
  const _$MediaFileDownloadInProgressImpl({
    required this.originalFileHash,
    required this.originalFile,
  });

  @override
  final String originalFileHash;
  @override
  final MediaFile originalFile;

  @override
  String toString() {
    return 'MediaFileDownload.downloading(originalFileHash: $originalFileHash, originalFile: $originalFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileDownloadInProgressImpl &&
            (identical(other.originalFileHash, originalFileHash) ||
                other.originalFileHash == originalFileHash) &&
            (identical(other.originalFile, originalFile) || other.originalFile == originalFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, originalFileHash, originalFile);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileDownloadInProgressImplCopyWith<_$MediaFileDownloadInProgressImpl> get copyWith =>
      __$$MediaFileDownloadInProgressImplCopyWithImpl<_$MediaFileDownloadInProgressImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String originalFileHash, MediaFile originalFile) pending,
    required TResult Function(String originalFileHash, MediaFile originalFile) downloading,
    required TResult Function(String originalFileHash, MediaFile downloadedFile) downloaded,
    required TResult Function(String originalFileHash, MediaFile originalFile) failed,
  }) {
    return downloading(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult? Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult? Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult? Function(String originalFileHash, MediaFile originalFile)? failed,
  }) {
    return downloading?.call(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult Function(String originalFileHash, MediaFile originalFile)? failed,
    required TResult orElse(),
  }) {
    if (downloading != null) {
      return downloading(originalFileHash, originalFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileDownloadPending value) pending,
    required TResult Function(MediaFileDownloadInProgress value) downloading,
    required TResult Function(MediaFileDownloaded value) downloaded,
    required TResult Function(MediaFileDownloadFailed value) failed,
  }) {
    return downloading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileDownloadPending value)? pending,
    TResult? Function(MediaFileDownloadInProgress value)? downloading,
    TResult? Function(MediaFileDownloaded value)? downloaded,
    TResult? Function(MediaFileDownloadFailed value)? failed,
  }) {
    return downloading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileDownloadPending value)? pending,
    TResult Function(MediaFileDownloadInProgress value)? downloading,
    TResult Function(MediaFileDownloaded value)? downloaded,
    TResult Function(MediaFileDownloadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (downloading != null) {
      return downloading(this);
    }
    return orElse();
  }
}

abstract class MediaFileDownloadInProgress implements MediaFileDownload {
  const factory MediaFileDownloadInProgress({
    required final String originalFileHash,
    required final MediaFile originalFile,
  }) = _$MediaFileDownloadInProgressImpl;

  @override
  String get originalFileHash;
  MediaFile get originalFile;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileDownloadInProgressImplCopyWith<_$MediaFileDownloadInProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaFileDownloadedImplCopyWith<$Res>
    implements $MediaFileDownloadCopyWith<$Res> {
  factory _$$MediaFileDownloadedImplCopyWith(
    _$MediaFileDownloadedImpl value,
    $Res Function(_$MediaFileDownloadedImpl) then,
  ) = __$$MediaFileDownloadedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String originalFileHash, MediaFile downloadedFile});
}

/// @nodoc
class __$$MediaFileDownloadedImplCopyWithImpl<$Res>
    extends _$MediaFileDownloadCopyWithImpl<$Res, _$MediaFileDownloadedImpl>
    implements _$$MediaFileDownloadedImplCopyWith<$Res> {
  __$$MediaFileDownloadedImplCopyWithImpl(
    _$MediaFileDownloadedImpl _value,
    $Res Function(_$MediaFileDownloadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? originalFileHash = null, Object? downloadedFile = null}) {
    return _then(
      _$MediaFileDownloadedImpl(
        originalFileHash:
            null == originalFileHash
                ? _value.originalFileHash
                : originalFileHash // ignore: cast_nullable_to_non_nullable
                    as String,
        downloadedFile:
            null == downloadedFile
                ? _value.downloadedFile
                : downloadedFile // ignore: cast_nullable_to_non_nullable
                    as MediaFile,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileDownloadedImpl implements MediaFileDownloaded {
  const _$MediaFileDownloadedImpl({
    required this.originalFileHash,
    required this.downloadedFile,
  });

  @override
  final String originalFileHash;
  @override
  final MediaFile downloadedFile;

  @override
  String toString() {
    return 'MediaFileDownload.downloaded(originalFileHash: $originalFileHash, downloadedFile: $downloadedFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileDownloadedImpl &&
            (identical(other.originalFileHash, originalFileHash) ||
                other.originalFileHash == originalFileHash) &&
            (identical(other.downloadedFile, downloadedFile) ||
                other.downloadedFile == downloadedFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, originalFileHash, downloadedFile);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileDownloadedImplCopyWith<_$MediaFileDownloadedImpl> get copyWith =>
      __$$MediaFileDownloadedImplCopyWithImpl<_$MediaFileDownloadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String originalFileHash, MediaFile originalFile) pending,
    required TResult Function(String originalFileHash, MediaFile originalFile) downloading,
    required TResult Function(String originalFileHash, MediaFile downloadedFile) downloaded,
    required TResult Function(String originalFileHash, MediaFile originalFile) failed,
  }) {
    return downloaded(originalFileHash, downloadedFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult? Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult? Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult? Function(String originalFileHash, MediaFile originalFile)? failed,
  }) {
    return downloaded?.call(originalFileHash, downloadedFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult Function(String originalFileHash, MediaFile originalFile)? failed,
    required TResult orElse(),
  }) {
    if (downloaded != null) {
      return downloaded(originalFileHash, downloadedFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileDownloadPending value) pending,
    required TResult Function(MediaFileDownloadInProgress value) downloading,
    required TResult Function(MediaFileDownloaded value) downloaded,
    required TResult Function(MediaFileDownloadFailed value) failed,
  }) {
    return downloaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileDownloadPending value)? pending,
    TResult? Function(MediaFileDownloadInProgress value)? downloading,
    TResult? Function(MediaFileDownloaded value)? downloaded,
    TResult? Function(MediaFileDownloadFailed value)? failed,
  }) {
    return downloaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileDownloadPending value)? pending,
    TResult Function(MediaFileDownloadInProgress value)? downloading,
    TResult Function(MediaFileDownloaded value)? downloaded,
    TResult Function(MediaFileDownloadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (downloaded != null) {
      return downloaded(this);
    }
    return orElse();
  }
}

abstract class MediaFileDownloaded implements MediaFileDownload {
  const factory MediaFileDownloaded({
    required final String originalFileHash,
    required final MediaFile downloadedFile,
  }) = _$MediaFileDownloadedImpl;

  @override
  String get originalFileHash;
  MediaFile get downloadedFile;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileDownloadedImplCopyWith<_$MediaFileDownloadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaFileDownloadFailedImplCopyWith<$Res>
    implements $MediaFileDownloadCopyWith<$Res> {
  factory _$$MediaFileDownloadFailedImplCopyWith(
    _$MediaFileDownloadFailedImpl value,
    $Res Function(_$MediaFileDownloadFailedImpl) then,
  ) = __$$MediaFileDownloadFailedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String originalFileHash, MediaFile originalFile});
}

/// @nodoc
class __$$MediaFileDownloadFailedImplCopyWithImpl<$Res>
    extends _$MediaFileDownloadCopyWithImpl<$Res, _$MediaFileDownloadFailedImpl>
    implements _$$MediaFileDownloadFailedImplCopyWith<$Res> {
  __$$MediaFileDownloadFailedImplCopyWithImpl(
    _$MediaFileDownloadFailedImpl _value,
    $Res Function(_$MediaFileDownloadFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? originalFileHash = null, Object? originalFile = null}) {
    return _then(
      _$MediaFileDownloadFailedImpl(
        originalFileHash:
            null == originalFileHash
                ? _value.originalFileHash
                : originalFileHash // ignore: cast_nullable_to_non_nullable
                    as String,
        originalFile:
            null == originalFile
                ? _value.originalFile
                : originalFile // ignore: cast_nullable_to_non_nullable
                    as MediaFile,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileDownloadFailedImpl implements MediaFileDownloadFailed {
  const _$MediaFileDownloadFailedImpl({
    required this.originalFileHash,
    required this.originalFile,
  });

  @override
  final String originalFileHash;
  @override
  final MediaFile originalFile;

  @override
  String toString() {
    return 'MediaFileDownload.failed(originalFileHash: $originalFileHash, originalFile: $originalFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileDownloadFailedImpl &&
            (identical(other.originalFileHash, originalFileHash) ||
                other.originalFileHash == originalFileHash) &&
            (identical(other.originalFile, originalFile) || other.originalFile == originalFile));
  }

  @override
  int get hashCode => Object.hash(runtimeType, originalFileHash, originalFile);

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileDownloadFailedImplCopyWith<_$MediaFileDownloadFailedImpl> get copyWith =>
      __$$MediaFileDownloadFailedImplCopyWithImpl<_$MediaFileDownloadFailedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String originalFileHash, MediaFile originalFile) pending,
    required TResult Function(String originalFileHash, MediaFile originalFile) downloading,
    required TResult Function(String originalFileHash, MediaFile downloadedFile) downloaded,
    required TResult Function(String originalFileHash, MediaFile originalFile) failed,
  }) {
    return failed(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult? Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult? Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult? Function(String originalFileHash, MediaFile originalFile)? failed,
  }) {
    return failed?.call(originalFileHash, originalFile);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String originalFileHash, MediaFile originalFile)? pending,
    TResult Function(String originalFileHash, MediaFile originalFile)? downloading,
    TResult Function(String originalFileHash, MediaFile downloadedFile)? downloaded,
    TResult Function(String originalFileHash, MediaFile originalFile)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(originalFileHash, originalFile);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileDownloadPending value) pending,
    required TResult Function(MediaFileDownloadInProgress value) downloading,
    required TResult Function(MediaFileDownloaded value) downloaded,
    required TResult Function(MediaFileDownloadFailed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileDownloadPending value)? pending,
    TResult? Function(MediaFileDownloadInProgress value)? downloading,
    TResult? Function(MediaFileDownloaded value)? downloaded,
    TResult? Function(MediaFileDownloadFailed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileDownloadPending value)? pending,
    TResult Function(MediaFileDownloadInProgress value)? downloading,
    TResult Function(MediaFileDownloaded value)? downloaded,
    TResult Function(MediaFileDownloadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class MediaFileDownloadFailed implements MediaFileDownload {
  const factory MediaFileDownloadFailed({
    required final String originalFileHash,
    required final MediaFile originalFile,
  }) = _$MediaFileDownloadFailedImpl;

  @override
  String get originalFileHash;
  MediaFile get originalFile;

  /// Create a copy of MediaFileDownload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileDownloadFailedImplCopyWith<_$MediaFileDownloadFailedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
