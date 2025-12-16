// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FileModel _$FileModelFromJson(Map<String, dynamic> json) {
  return _FileModel.fromJson(json);
}

/// @nodoc
mixin _$FileModel {
  String get id => throw _privateConstructorUsedError;
  String get folderId => throw _privateConstructorUsedError;
  String get encryptedMetadata =>
      throw _privateConstructorUsedError; // Base64 encoded encrypted JSON of FileMetadata
  String get encryptedPreviewPath =>
      throw _privateConstructorUsedError; // Path to encrypted thumbnail (optional)
  DateTime? get expiryDate => throw _privateConstructorUsedError;

  /// Serializes this FileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileModelCopyWith<FileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileModelCopyWith<$Res> {
  factory $FileModelCopyWith(FileModel value, $Res Function(FileModel) then) =
      _$FileModelCopyWithImpl<$Res, FileModel>;
  @useResult
  $Res call({
    String id,
    String folderId,
    String encryptedMetadata,
    String encryptedPreviewPath,
    DateTime? expiryDate,
  });
}

/// @nodoc
class _$FileModelCopyWithImpl<$Res, $Val extends FileModel>
    implements $FileModelCopyWith<$Res> {
  _$FileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? folderId = null,
    Object? encryptedMetadata = null,
    Object? encryptedPreviewPath = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            folderId: null == folderId
                ? _value.folderId
                : folderId // ignore: cast_nullable_to_non_nullable
                      as String,
            encryptedMetadata: null == encryptedMetadata
                ? _value.encryptedMetadata
                : encryptedMetadata // ignore: cast_nullable_to_non_nullable
                      as String,
            encryptedPreviewPath: null == encryptedPreviewPath
                ? _value.encryptedPreviewPath
                : encryptedPreviewPath // ignore: cast_nullable_to_non_nullable
                      as String,
            expiryDate: freezed == expiryDate
                ? _value.expiryDate
                : expiryDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FileModelImplCopyWith<$Res>
    implements $FileModelCopyWith<$Res> {
  factory _$$FileModelImplCopyWith(
    _$FileModelImpl value,
    $Res Function(_$FileModelImpl) then,
  ) = __$$FileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String folderId,
    String encryptedMetadata,
    String encryptedPreviewPath,
    DateTime? expiryDate,
  });
}

/// @nodoc
class __$$FileModelImplCopyWithImpl<$Res>
    extends _$FileModelCopyWithImpl<$Res, _$FileModelImpl>
    implements _$$FileModelImplCopyWith<$Res> {
  __$$FileModelImplCopyWithImpl(
    _$FileModelImpl _value,
    $Res Function(_$FileModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? folderId = null,
    Object? encryptedMetadata = null,
    Object? encryptedPreviewPath = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _$FileModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        folderId: null == folderId
            ? _value.folderId
            : folderId // ignore: cast_nullable_to_non_nullable
                  as String,
        encryptedMetadata: null == encryptedMetadata
            ? _value.encryptedMetadata
            : encryptedMetadata // ignore: cast_nullable_to_non_nullable
                  as String,
        encryptedPreviewPath: null == encryptedPreviewPath
            ? _value.encryptedPreviewPath
            : encryptedPreviewPath // ignore: cast_nullable_to_non_nullable
                  as String,
        expiryDate: freezed == expiryDate
            ? _value.expiryDate
            : expiryDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FileModelImpl implements _FileModel {
  const _$FileModelImpl({
    required this.id,
    required this.folderId,
    required this.encryptedMetadata,
    required this.encryptedPreviewPath,
    this.expiryDate,
  });

  factory _$FileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileModelImplFromJson(json);

  @override
  final String id;
  @override
  final String folderId;
  @override
  final String encryptedMetadata;
  // Base64 encoded encrypted JSON of FileMetadata
  @override
  final String encryptedPreviewPath;
  // Path to encrypted thumbnail (optional)
  @override
  final DateTime? expiryDate;

  @override
  String toString() {
    return 'FileModel(id: $id, folderId: $folderId, encryptedMetadata: $encryptedMetadata, encryptedPreviewPath: $encryptedPreviewPath, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.encryptedMetadata, encryptedMetadata) ||
                other.encryptedMetadata == encryptedMetadata) &&
            (identical(other.encryptedPreviewPath, encryptedPreviewPath) ||
                other.encryptedPreviewPath == encryptedPreviewPath) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    folderId,
    encryptedMetadata,
    encryptedPreviewPath,
    expiryDate,
  );

  /// Create a copy of FileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileModelImplCopyWith<_$FileModelImpl> get copyWith =>
      __$$FileModelImplCopyWithImpl<_$FileModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileModelImplToJson(this);
  }
}

abstract class _FileModel implements FileModel {
  const factory _FileModel({
    required final String id,
    required final String folderId,
    required final String encryptedMetadata,
    required final String encryptedPreviewPath,
    final DateTime? expiryDate,
  }) = _$FileModelImpl;

  factory _FileModel.fromJson(Map<String, dynamic> json) =
      _$FileModelImpl.fromJson;

  @override
  String get id;
  @override
  String get folderId;
  @override
  String get encryptedMetadata; // Base64 encoded encrypted JSON of FileMetadata
  @override
  String get encryptedPreviewPath; // Path to encrypted thumbnail (optional)
  @override
  DateTime? get expiryDate;

  /// Create a copy of FileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileModelImplCopyWith<_$FileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) {
  return _FileMetadata.fromJson(json);
}

/// @nodoc
mixin _$FileMetadata {
  String get id => throw _privateConstructorUsedError;
  String get fileName => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  String get encryptedFilePath =>
      throw _privateConstructorUsedError; // Path to the actual encrypted content file on disk
  String get fileKey =>
      throw _privateConstructorUsedError; // Base64 encoded random key for this file
  String get nonce =>
      throw _privateConstructorUsedError; // Base64 encoded IV/Nonce for the file content encryption
  bool get allowSaveToDownloads => throw _privateConstructorUsedError;
  DateTime? get expiryDate => throw _privateConstructorUsedError;

  /// Serializes this FileMetadata to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FileMetadataCopyWith<FileMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileMetadataCopyWith<$Res> {
  factory $FileMetadataCopyWith(
    FileMetadata value,
    $Res Function(FileMetadata) then,
  ) = _$FileMetadataCopyWithImpl<$Res, FileMetadata>;
  @useResult
  $Res call({
    String id,
    String fileName,
    int size,
    String mimeType,
    String encryptedFilePath,
    String fileKey,
    String nonce,
    bool allowSaveToDownloads,
    DateTime? expiryDate,
  });
}

/// @nodoc
class _$FileMetadataCopyWithImpl<$Res, $Val extends FileMetadata>
    implements $FileMetadataCopyWith<$Res> {
  _$FileMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? size = null,
    Object? mimeType = null,
    Object? encryptedFilePath = null,
    Object? fileKey = null,
    Object? nonce = null,
    Object? allowSaveToDownloads = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fileName: null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                      as String,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
            mimeType: null == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                      as String,
            encryptedFilePath: null == encryptedFilePath
                ? _value.encryptedFilePath
                : encryptedFilePath // ignore: cast_nullable_to_non_nullable
                      as String,
            fileKey: null == fileKey
                ? _value.fileKey
                : fileKey // ignore: cast_nullable_to_non_nullable
                      as String,
            nonce: null == nonce
                ? _value.nonce
                : nonce // ignore: cast_nullable_to_non_nullable
                      as String,
            allowSaveToDownloads: null == allowSaveToDownloads
                ? _value.allowSaveToDownloads
                : allowSaveToDownloads // ignore: cast_nullable_to_non_nullable
                      as bool,
            expiryDate: freezed == expiryDate
                ? _value.expiryDate
                : expiryDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FileMetadataImplCopyWith<$Res>
    implements $FileMetadataCopyWith<$Res> {
  factory _$$FileMetadataImplCopyWith(
    _$FileMetadataImpl value,
    $Res Function(_$FileMetadataImpl) then,
  ) = __$$FileMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String fileName,
    int size,
    String mimeType,
    String encryptedFilePath,
    String fileKey,
    String nonce,
    bool allowSaveToDownloads,
    DateTime? expiryDate,
  });
}

/// @nodoc
class __$$FileMetadataImplCopyWithImpl<$Res>
    extends _$FileMetadataCopyWithImpl<$Res, _$FileMetadataImpl>
    implements _$$FileMetadataImplCopyWith<$Res> {
  __$$FileMetadataImplCopyWithImpl(
    _$FileMetadataImpl _value,
    $Res Function(_$FileMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fileName = null,
    Object? size = null,
    Object? mimeType = null,
    Object? encryptedFilePath = null,
    Object? fileKey = null,
    Object? nonce = null,
    Object? allowSaveToDownloads = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _$FileMetadataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        mimeType: null == mimeType
            ? _value.mimeType
            : mimeType // ignore: cast_nullable_to_non_nullable
                  as String,
        encryptedFilePath: null == encryptedFilePath
            ? _value.encryptedFilePath
            : encryptedFilePath // ignore: cast_nullable_to_non_nullable
                  as String,
        fileKey: null == fileKey
            ? _value.fileKey
            : fileKey // ignore: cast_nullable_to_non_nullable
                  as String,
        nonce: null == nonce
            ? _value.nonce
            : nonce // ignore: cast_nullable_to_non_nullable
                  as String,
        allowSaveToDownloads: null == allowSaveToDownloads
            ? _value.allowSaveToDownloads
            : allowSaveToDownloads // ignore: cast_nullable_to_non_nullable
                  as bool,
        expiryDate: freezed == expiryDate
            ? _value.expiryDate
            : expiryDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FileMetadataImpl implements _FileMetadata {
  const _$FileMetadataImpl({
    required this.id,
    required this.fileName,
    required this.size,
    required this.mimeType,
    required this.encryptedFilePath,
    required this.fileKey,
    required this.nonce,
    required this.allowSaveToDownloads,
    this.expiryDate,
  });

  factory _$FileMetadataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FileMetadataImplFromJson(json);

  @override
  final String id;
  @override
  final String fileName;
  @override
  final int size;
  @override
  final String mimeType;
  @override
  final String encryptedFilePath;
  // Path to the actual encrypted content file on disk
  @override
  final String fileKey;
  // Base64 encoded random key for this file
  @override
  final String nonce;
  // Base64 encoded IV/Nonce for the file content encryption
  @override
  final bool allowSaveToDownloads;
  @override
  final DateTime? expiryDate;

  @override
  String toString() {
    return 'FileMetadata(id: $id, fileName: $fileName, size: $size, mimeType: $mimeType, encryptedFilePath: $encryptedFilePath, fileKey: $fileKey, nonce: $nonce, allowSaveToDownloads: $allowSaveToDownloads, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileMetadataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.encryptedFilePath, encryptedFilePath) ||
                other.encryptedFilePath == encryptedFilePath) &&
            (identical(other.fileKey, fileKey) || other.fileKey == fileKey) &&
            (identical(other.nonce, nonce) || other.nonce == nonce) &&
            (identical(other.allowSaveToDownloads, allowSaveToDownloads) ||
                other.allowSaveToDownloads == allowSaveToDownloads) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fileName,
    size,
    mimeType,
    encryptedFilePath,
    fileKey,
    nonce,
    allowSaveToDownloads,
    expiryDate,
  );

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      __$$FileMetadataImplCopyWithImpl<_$FileMetadataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FileMetadataImplToJson(this);
  }
}

abstract class _FileMetadata implements FileMetadata {
  const factory _FileMetadata({
    required final String id,
    required final String fileName,
    required final int size,
    required final String mimeType,
    required final String encryptedFilePath,
    required final String fileKey,
    required final String nonce,
    required final bool allowSaveToDownloads,
    final DateTime? expiryDate,
  }) = _$FileMetadataImpl;

  factory _FileMetadata.fromJson(Map<String, dynamic> json) =
      _$FileMetadataImpl.fromJson;

  @override
  String get id;
  @override
  String get fileName;
  @override
  int get size;
  @override
  String get mimeType;
  @override
  String get encryptedFilePath; // Path to the actual encrypted content file on disk
  @override
  String get fileKey; // Base64 encoded random key for this file
  @override
  String get nonce; // Base64 encoded IV/Nonce for the file content encryption
  @override
  bool get allowSaveToDownloads;
  @override
  DateTime? get expiryDate;

  /// Create a copy of FileMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileMetadataImplCopyWith<_$FileMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
