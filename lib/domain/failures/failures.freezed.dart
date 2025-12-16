// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Failure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$DatabaseErrorImplCopyWith<$Res> {
  factory _$$DatabaseErrorImplCopyWith(
    _$DatabaseErrorImpl value,
    $Res Function(_$DatabaseErrorImpl) then,
  ) = __$$DatabaseErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$DatabaseErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$DatabaseErrorImpl>
    implements _$$DatabaseErrorImplCopyWith<$Res> {
  __$$DatabaseErrorImplCopyWithImpl(
    _$DatabaseErrorImpl _value,
    $Res Function(_$DatabaseErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$DatabaseErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DatabaseErrorImpl implements _DatabaseError {
  const _$DatabaseErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.databaseError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DatabaseErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DatabaseErrorImplCopyWith<_$DatabaseErrorImpl> get copyWith =>
      __$$DatabaseErrorImplCopyWithImpl<_$DatabaseErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return databaseError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return databaseError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (databaseError != null) {
      return databaseError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return databaseError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return databaseError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (databaseError != null) {
      return databaseError(this);
    }
    return orElse();
  }
}

abstract class _DatabaseError implements Failure {
  const factory _DatabaseError(final String message) = _$DatabaseErrorImpl;

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DatabaseErrorImplCopyWith<_$DatabaseErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FileSystemErrorImplCopyWith<$Res> {
  factory _$$FileSystemErrorImplCopyWith(
    _$FileSystemErrorImpl value,
    $Res Function(_$FileSystemErrorImpl) then,
  ) = __$$FileSystemErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$FileSystemErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$FileSystemErrorImpl>
    implements _$$FileSystemErrorImplCopyWith<$Res> {
  __$$FileSystemErrorImplCopyWithImpl(
    _$FileSystemErrorImpl _value,
    $Res Function(_$FileSystemErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$FileSystemErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$FileSystemErrorImpl implements _FileSystemError {
  const _$FileSystemErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.fileSystemError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileSystemErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileSystemErrorImplCopyWith<_$FileSystemErrorImpl> get copyWith =>
      __$$FileSystemErrorImplCopyWithImpl<_$FileSystemErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return fileSystemError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return fileSystemError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (fileSystemError != null) {
      return fileSystemError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return fileSystemError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return fileSystemError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (fileSystemError != null) {
      return fileSystemError(this);
    }
    return orElse();
  }
}

abstract class _FileSystemError implements Failure {
  const factory _FileSystemError(final String message) = _$FileSystemErrorImpl;

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileSystemErrorImplCopyWith<_$FileSystemErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$EncryptionErrorImplCopyWith<$Res> {
  factory _$$EncryptionErrorImplCopyWith(
    _$EncryptionErrorImpl value,
    $Res Function(_$EncryptionErrorImpl) then,
  ) = __$$EncryptionErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$EncryptionErrorImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$EncryptionErrorImpl>
    implements _$$EncryptionErrorImplCopyWith<$Res> {
  __$$EncryptionErrorImplCopyWithImpl(
    _$EncryptionErrorImpl _value,
    $Res Function(_$EncryptionErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$EncryptionErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$EncryptionErrorImpl implements _EncryptionError {
  const _$EncryptionErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.encryptionError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EncryptionErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EncryptionErrorImplCopyWith<_$EncryptionErrorImpl> get copyWith =>
      __$$EncryptionErrorImplCopyWithImpl<_$EncryptionErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return encryptionError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return encryptionError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (encryptionError != null) {
      return encryptionError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return encryptionError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return encryptionError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (encryptionError != null) {
      return encryptionError(this);
    }
    return orElse();
  }
}

abstract class _EncryptionError implements Failure {
  const factory _EncryptionError(final String message) = _$EncryptionErrorImpl;

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EncryptionErrorImplCopyWith<_$EncryptionErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvalidPasswordImplCopyWith<$Res> {
  factory _$$InvalidPasswordImplCopyWith(
    _$InvalidPasswordImpl value,
    $Res Function(_$InvalidPasswordImpl) then,
  ) = __$$InvalidPasswordImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InvalidPasswordImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$InvalidPasswordImpl>
    implements _$$InvalidPasswordImplCopyWith<$Res> {
  __$$InvalidPasswordImplCopyWithImpl(
    _$InvalidPasswordImpl _value,
    $Res Function(_$InvalidPasswordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InvalidPasswordImpl implements _InvalidPassword {
  const _$InvalidPasswordImpl();

  @override
  String toString() {
    return 'Failure.invalidPassword()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InvalidPasswordImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return invalidPassword();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return invalidPassword?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidPassword != null) {
      return invalidPassword();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return invalidPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return invalidPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (invalidPassword != null) {
      return invalidPassword(this);
    }
    return orElse();
  }
}

abstract class _InvalidPassword implements Failure {
  const factory _InvalidPassword() = _$InvalidPasswordImpl;
}

/// @nodoc
abstract class _$$FileExpiredImplCopyWith<$Res> {
  factory _$$FileExpiredImplCopyWith(
    _$FileExpiredImpl value,
    $Res Function(_$FileExpiredImpl) then,
  ) = __$$FileExpiredImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$FileExpiredImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$FileExpiredImpl>
    implements _$$FileExpiredImplCopyWith<$Res> {
  __$$FileExpiredImplCopyWithImpl(
    _$FileExpiredImpl _value,
    $Res Function(_$FileExpiredImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$FileExpiredImpl implements _FileExpired {
  const _$FileExpiredImpl();

  @override
  String toString() {
    return 'Failure.fileExpired()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$FileExpiredImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return fileExpired();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return fileExpired?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (fileExpired != null) {
      return fileExpired();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return fileExpired(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return fileExpired?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (fileExpired != null) {
      return fileExpired(this);
    }
    return orElse();
  }
}

abstract class _FileExpired implements Failure {
  const factory _FileExpired() = _$FileExpiredImpl;
}

/// @nodoc
abstract class _$$PermissionDeniedImplCopyWith<$Res> {
  factory _$$PermissionDeniedImplCopyWith(
    _$PermissionDeniedImpl value,
    $Res Function(_$PermissionDeniedImpl) then,
  ) = __$$PermissionDeniedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PermissionDeniedImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$PermissionDeniedImpl>
    implements _$$PermissionDeniedImplCopyWith<$Res> {
  __$$PermissionDeniedImplCopyWithImpl(
    _$PermissionDeniedImpl _value,
    $Res Function(_$PermissionDeniedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PermissionDeniedImpl implements _PermissionDenied {
  const _$PermissionDeniedImpl();

  @override
  String toString() {
    return 'Failure.permissionDenied()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PermissionDeniedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return permissionDenied();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return permissionDenied?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return permissionDenied(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return permissionDenied?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied(this);
    }
    return orElse();
  }
}

abstract class _PermissionDenied implements Failure {
  const factory _PermissionDenied() = _$PermissionDeniedImpl;
}

/// @nodoc
abstract class _$$UnexpectedImplCopyWith<$Res> {
  factory _$$UnexpectedImplCopyWith(
    _$UnexpectedImpl value,
    $Res Function(_$UnexpectedImpl) then,
  ) = __$$UnexpectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$UnexpectedImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnexpectedImpl>
    implements _$$UnexpectedImplCopyWith<$Res> {
  __$$UnexpectedImplCopyWithImpl(
    _$UnexpectedImpl _value,
    $Res Function(_$UnexpectedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$UnexpectedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UnexpectedImpl implements _Unexpected {
  const _$UnexpectedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unexpected(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnexpectedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      __$$UnexpectedImplCopyWithImpl<_$UnexpectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) databaseError,
    required TResult Function(String message) fileSystemError,
    required TResult Function(String message) encryptionError,
    required TResult Function() invalidPassword,
    required TResult Function() fileExpired,
    required TResult Function() permissionDenied,
    required TResult Function(String message) unexpected,
  }) {
    return unexpected(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? databaseError,
    TResult? Function(String message)? fileSystemError,
    TResult? Function(String message)? encryptionError,
    TResult? Function()? invalidPassword,
    TResult? Function()? fileExpired,
    TResult? Function()? permissionDenied,
    TResult? Function(String message)? unexpected,
  }) {
    return unexpected?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? databaseError,
    TResult Function(String message)? fileSystemError,
    TResult Function(String message)? encryptionError,
    TResult Function()? invalidPassword,
    TResult Function()? fileExpired,
    TResult Function()? permissionDenied,
    TResult Function(String message)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_DatabaseError value) databaseError,
    required TResult Function(_FileSystemError value) fileSystemError,
    required TResult Function(_EncryptionError value) encryptionError,
    required TResult Function(_InvalidPassword value) invalidPassword,
    required TResult Function(_FileExpired value) fileExpired,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return unexpected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_DatabaseError value)? databaseError,
    TResult? Function(_FileSystemError value)? fileSystemError,
    TResult? Function(_EncryptionError value)? encryptionError,
    TResult? Function(_InvalidPassword value)? invalidPassword,
    TResult? Function(_FileExpired value)? fileExpired,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return unexpected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_DatabaseError value)? databaseError,
    TResult Function(_FileSystemError value)? fileSystemError,
    TResult Function(_EncryptionError value)? encryptionError,
    TResult Function(_InvalidPassword value)? invalidPassword,
    TResult Function(_FileExpired value)? fileExpired,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(this);
    }
    return orElse();
  }
}

abstract class _Unexpected implements Failure {
  const factory _Unexpected(final String message) = _$UnexpectedImpl;

  String get message;

  /// Create a copy of Failure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
