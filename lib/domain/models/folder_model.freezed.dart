// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FolderModel _$FolderModelFromJson(Map<String, dynamic> json) {
  return _FolderModel.fromJson(json);
}

/// @nodoc
mixin _$FolderModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get salt =>
      throw _privateConstructorUsedError; // Base64 encoded salt for key derivation
  String get verificationHash =>
      throw _privateConstructorUsedError; // Base64 encoded hash to verify password
  DateTime get createdAt => throw _privateConstructorUsedError;
  bool get allowSave => throw _privateConstructorUsedError;
  DateTime? get expiryDate => throw _privateConstructorUsedError;

  /// Serializes this FolderModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FolderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FolderModelCopyWith<FolderModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FolderModelCopyWith<$Res> {
  factory $FolderModelCopyWith(
    FolderModel value,
    $Res Function(FolderModel) then,
  ) = _$FolderModelCopyWithImpl<$Res, FolderModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String salt,
    String verificationHash,
    DateTime createdAt,
    bool allowSave,
    DateTime? expiryDate,
  });
}

/// @nodoc
class _$FolderModelCopyWithImpl<$Res, $Val extends FolderModel>
    implements $FolderModelCopyWith<$Res> {
  _$FolderModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FolderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? salt = null,
    Object? verificationHash = null,
    Object? createdAt = null,
    Object? allowSave = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            salt: null == salt
                ? _value.salt
                : salt // ignore: cast_nullable_to_non_nullable
                      as String,
            verificationHash: null == verificationHash
                ? _value.verificationHash
                : verificationHash // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            allowSave: null == allowSave
                ? _value.allowSave
                : allowSave // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FolderModelImplCopyWith<$Res>
    implements $FolderModelCopyWith<$Res> {
  factory _$$FolderModelImplCopyWith(
    _$FolderModelImpl value,
    $Res Function(_$FolderModelImpl) then,
  ) = __$$FolderModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String salt,
    String verificationHash,
    DateTime createdAt,
    bool allowSave,
    DateTime? expiryDate,
  });
}

/// @nodoc
class __$$FolderModelImplCopyWithImpl<$Res>
    extends _$FolderModelCopyWithImpl<$Res, _$FolderModelImpl>
    implements _$$FolderModelImplCopyWith<$Res> {
  __$$FolderModelImplCopyWithImpl(
    _$FolderModelImpl _value,
    $Res Function(_$FolderModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FolderModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? salt = null,
    Object? verificationHash = null,
    Object? createdAt = null,
    Object? allowSave = null,
    Object? expiryDate = freezed,
  }) {
    return _then(
      _$FolderModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        salt: null == salt
            ? _value.salt
            : salt // ignore: cast_nullable_to_non_nullable
                  as String,
        verificationHash: null == verificationHash
            ? _value.verificationHash
            : verificationHash // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        allowSave: null == allowSave
            ? _value.allowSave
            : allowSave // ignore: cast_nullable_to_non_nullable
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
class _$FolderModelImpl implements _FolderModel {
  const _$FolderModelImpl({
    required this.id,
    required this.name,
    required this.salt,
    required this.verificationHash,
    required this.createdAt,
    this.allowSave = true,
    this.expiryDate,
  });

  factory _$FolderModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FolderModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String salt;
  // Base64 encoded salt for key derivation
  @override
  final String verificationHash;
  // Base64 encoded hash to verify password
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final bool allowSave;
  @override
  final DateTime? expiryDate;

  @override
  String toString() {
    return 'FolderModel(id: $id, name: $name, salt: $salt, verificationHash: $verificationHash, createdAt: $createdAt, allowSave: $allowSave, expiryDate: $expiryDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FolderModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.salt, salt) || other.salt == salt) &&
            (identical(other.verificationHash, verificationHash) ||
                other.verificationHash == verificationHash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.allowSave, allowSave) ||
                other.allowSave == allowSave) &&
            (identical(other.expiryDate, expiryDate) ||
                other.expiryDate == expiryDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    salt,
    verificationHash,
    createdAt,
    allowSave,
    expiryDate,
  );

  /// Create a copy of FolderModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FolderModelImplCopyWith<_$FolderModelImpl> get copyWith =>
      __$$FolderModelImplCopyWithImpl<_$FolderModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FolderModelImplToJson(this);
  }
}

abstract class _FolderModel implements FolderModel {
  const factory _FolderModel({
    required final String id,
    required final String name,
    required final String salt,
    required final String verificationHash,
    required final DateTime createdAt,
    final bool allowSave,
    final DateTime? expiryDate,
  }) = _$FolderModelImpl;

  factory _FolderModel.fromJson(Map<String, dynamic> json) =
      _$FolderModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get salt; // Base64 encoded salt for key derivation
  @override
  String get verificationHash; // Base64 encoded hash to verify password
  @override
  DateTime get createdAt;
  @override
  bool get allowSave;
  @override
  DateTime? get expiryDate;

  /// Create a copy of FolderModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FolderModelImplCopyWith<_$FolderModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
