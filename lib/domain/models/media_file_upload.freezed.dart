// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_file_upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MediaFileUpload {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String filePath) uploading,
    required TResult Function(MediaFile file, String originalFilePath) uploaded,
    required TResult Function(String filePath, String error) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String filePath)? uploading,
    TResult? Function(MediaFile file, String originalFilePath)? uploaded,
    TResult? Function(String filePath, String error)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String filePath)? uploading,
    TResult Function(MediaFile file, String originalFilePath)? uploaded,
    TResult Function(String filePath, String error)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileUploading value) uploading,
    required TResult Function(MediaFileUploaded value) uploaded,
    required TResult Function(MediaFileUploadFailed value) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileUploading value)? uploading,
    TResult? Function(MediaFileUploaded value)? uploaded,
    TResult? Function(MediaFileUploadFailed value)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileUploading value)? uploading,
    TResult Function(MediaFileUploaded value)? uploaded,
    TResult Function(MediaFileUploadFailed value)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaFileUploadCopyWith<$Res> {
  factory $MediaFileUploadCopyWith(
    MediaFileUpload value,
    $Res Function(MediaFileUpload) then,
  ) = _$MediaFileUploadCopyWithImpl<$Res, MediaFileUpload>;
}

/// @nodoc
class _$MediaFileUploadCopyWithImpl<$Res, $Val extends MediaFileUpload>
    implements $MediaFileUploadCopyWith<$Res> {
  _$MediaFileUploadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MediaFileUploadingImplCopyWith<$Res> {
  factory _$$MediaFileUploadingImplCopyWith(
    _$MediaFileUploadingImpl value,
    $Res Function(_$MediaFileUploadingImpl) then,
  ) = __$$MediaFileUploadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath});
}

/// @nodoc
class __$$MediaFileUploadingImplCopyWithImpl<$Res>
    extends _$MediaFileUploadCopyWithImpl<$Res, _$MediaFileUploadingImpl>
    implements _$$MediaFileUploadingImplCopyWith<$Res> {
  __$$MediaFileUploadingImplCopyWithImpl(
    _$MediaFileUploadingImpl _value,
    $Res Function(_$MediaFileUploadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null}) {
    return _then(
      _$MediaFileUploadingImpl(
        filePath:
            null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileUploadingImpl implements MediaFileUploading {
  const _$MediaFileUploadingImpl({required this.filePath});

  @override
  final String filePath;

  @override
  String toString() {
    return 'MediaFileUpload.uploading(filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileUploadingImpl &&
            (identical(other.filePath, filePath) || other.filePath == filePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filePath);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileUploadingImplCopyWith<_$MediaFileUploadingImpl> get copyWith =>
      __$$MediaFileUploadingImplCopyWithImpl<_$MediaFileUploadingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String filePath) uploading,
    required TResult Function(MediaFile file, String originalFilePath) uploaded,
    required TResult Function(String filePath, String error) failed,
  }) {
    return uploading(filePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String filePath)? uploading,
    TResult? Function(MediaFile file, String originalFilePath)? uploaded,
    TResult? Function(String filePath, String error)? failed,
  }) {
    return uploading?.call(filePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String filePath)? uploading,
    TResult Function(MediaFile file, String originalFilePath)? uploaded,
    TResult Function(String filePath, String error)? failed,
    required TResult orElse(),
  }) {
    if (uploading != null) {
      return uploading(filePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileUploading value) uploading,
    required TResult Function(MediaFileUploaded value) uploaded,
    required TResult Function(MediaFileUploadFailed value) failed,
  }) {
    return uploading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileUploading value)? uploading,
    TResult? Function(MediaFileUploaded value)? uploaded,
    TResult? Function(MediaFileUploadFailed value)? failed,
  }) {
    return uploading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileUploading value)? uploading,
    TResult Function(MediaFileUploaded value)? uploaded,
    TResult Function(MediaFileUploadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (uploading != null) {
      return uploading(this);
    }
    return orElse();
  }
}

abstract class MediaFileUploading implements MediaFileUpload {
  const factory MediaFileUploading({required final String filePath}) = _$MediaFileUploadingImpl;

  String get filePath;

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileUploadingImplCopyWith<_$MediaFileUploadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaFileUploadedImplCopyWith<$Res> {
  factory _$$MediaFileUploadedImplCopyWith(
    _$MediaFileUploadedImpl value,
    $Res Function(_$MediaFileUploadedImpl) then,
  ) = __$$MediaFileUploadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MediaFile file, String originalFilePath});
}

/// @nodoc
class __$$MediaFileUploadedImplCopyWithImpl<$Res>
    extends _$MediaFileUploadCopyWithImpl<$Res, _$MediaFileUploadedImpl>
    implements _$$MediaFileUploadedImplCopyWith<$Res> {
  __$$MediaFileUploadedImplCopyWithImpl(
    _$MediaFileUploadedImpl _value,
    $Res Function(_$MediaFileUploadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? file = null, Object? originalFilePath = null}) {
    return _then(
      _$MediaFileUploadedImpl(
        file:
            null == file
                ? _value.file
                : file // ignore: cast_nullable_to_non_nullable
                    as MediaFile,
        originalFilePath:
            null == originalFilePath
                ? _value.originalFilePath
                : originalFilePath // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileUploadedImpl implements MediaFileUploaded {
  const _$MediaFileUploadedImpl({
    required this.file,
    required this.originalFilePath,
  });

  @override
  final MediaFile file;
  @override
  final String originalFilePath;

  @override
  String toString() {
    return 'MediaFileUpload.uploaded(file: $file, originalFilePath: $originalFilePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileUploadedImpl &&
            (identical(other.file, file) || other.file == file) &&
            (identical(other.originalFilePath, originalFilePath) ||
                other.originalFilePath == originalFilePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, file, originalFilePath);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileUploadedImplCopyWith<_$MediaFileUploadedImpl> get copyWith =>
      __$$MediaFileUploadedImplCopyWithImpl<_$MediaFileUploadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String filePath) uploading,
    required TResult Function(MediaFile file, String originalFilePath) uploaded,
    required TResult Function(String filePath, String error) failed,
  }) {
    return uploaded(file, originalFilePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String filePath)? uploading,
    TResult? Function(MediaFile file, String originalFilePath)? uploaded,
    TResult? Function(String filePath, String error)? failed,
  }) {
    return uploaded?.call(file, originalFilePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String filePath)? uploading,
    TResult Function(MediaFile file, String originalFilePath)? uploaded,
    TResult Function(String filePath, String error)? failed,
    required TResult orElse(),
  }) {
    if (uploaded != null) {
      return uploaded(file, originalFilePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileUploading value) uploading,
    required TResult Function(MediaFileUploaded value) uploaded,
    required TResult Function(MediaFileUploadFailed value) failed,
  }) {
    return uploaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileUploading value)? uploading,
    TResult? Function(MediaFileUploaded value)? uploaded,
    TResult? Function(MediaFileUploadFailed value)? failed,
  }) {
    return uploaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileUploading value)? uploading,
    TResult Function(MediaFileUploaded value)? uploaded,
    TResult Function(MediaFileUploadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (uploaded != null) {
      return uploaded(this);
    }
    return orElse();
  }
}

abstract class MediaFileUploaded implements MediaFileUpload {
  const factory MediaFileUploaded({
    required final MediaFile file,
    required final String originalFilePath,
  }) = _$MediaFileUploadedImpl;

  MediaFile get file;
  String get originalFilePath;

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileUploadedImplCopyWith<_$MediaFileUploadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaFileUploadFailedImplCopyWith<$Res> {
  factory _$$MediaFileUploadFailedImplCopyWith(
    _$MediaFileUploadFailedImpl value,
    $Res Function(_$MediaFileUploadFailedImpl) then,
  ) = __$$MediaFileUploadFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String filePath, String error});
}

/// @nodoc
class __$$MediaFileUploadFailedImplCopyWithImpl<$Res>
    extends _$MediaFileUploadCopyWithImpl<$Res, _$MediaFileUploadFailedImpl>
    implements _$$MediaFileUploadFailedImplCopyWith<$Res> {
  __$$MediaFileUploadFailedImplCopyWithImpl(
    _$MediaFileUploadFailedImpl _value,
    $Res Function(_$MediaFileUploadFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? filePath = null, Object? error = null}) {
    return _then(
      _$MediaFileUploadFailedImpl(
        filePath:
            null == filePath
                ? _value.filePath
                : filePath // ignore: cast_nullable_to_non_nullable
                    as String,
        error:
            null == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$MediaFileUploadFailedImpl implements MediaFileUploadFailed {
  const _$MediaFileUploadFailedImpl({
    required this.filePath,
    required this.error,
  });

  @override
  final String filePath;
  @override
  final String error;

  @override
  String toString() {
    return 'MediaFileUpload.failed(filePath: $filePath, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileUploadFailedImpl &&
            (identical(other.filePath, filePath) || other.filePath == filePath) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, filePath, error);

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileUploadFailedImplCopyWith<_$MediaFileUploadFailedImpl> get copyWith =>
      __$$MediaFileUploadFailedImplCopyWithImpl<_$MediaFileUploadFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String filePath) uploading,
    required TResult Function(MediaFile file, String originalFilePath) uploaded,
    required TResult Function(String filePath, String error) failed,
  }) {
    return failed(filePath, error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String filePath)? uploading,
    TResult? Function(MediaFile file, String originalFilePath)? uploaded,
    TResult? Function(String filePath, String error)? failed,
  }) {
    return failed?.call(filePath, error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String filePath)? uploading,
    TResult Function(MediaFile file, String originalFilePath)? uploaded,
    TResult Function(String filePath, String error)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(filePath, error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MediaFileUploading value) uploading,
    required TResult Function(MediaFileUploaded value) uploaded,
    required TResult Function(MediaFileUploadFailed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MediaFileUploading value)? uploading,
    TResult? Function(MediaFileUploaded value)? uploaded,
    TResult? Function(MediaFileUploadFailed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MediaFileUploading value)? uploading,
    TResult Function(MediaFileUploaded value)? uploaded,
    TResult Function(MediaFileUploadFailed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class MediaFileUploadFailed implements MediaFileUpload {
  const factory MediaFileUploadFailed({
    required final String filePath,
    required final String error,
  }) = _$MediaFileUploadFailedImpl;

  String get filePath;
  String get error;

  /// Create a copy of MediaFileUpload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileUploadFailedImplCopyWith<_$MediaFileUploadFailedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
