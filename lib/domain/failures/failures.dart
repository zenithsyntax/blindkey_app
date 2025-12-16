import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.databaseError(String message) = _DatabaseError;
  const factory Failure.fileSystemError(String message) = _FileSystemError;
  const factory Failure.encryptionError(String message) = _EncryptionError;
  const factory Failure.invalidPassword() = _InvalidPassword;
  const factory Failure.fileExpired() = _FileExpired;
  const factory Failure.permissionDenied() = _PermissionDenied;
  const factory Failure.unexpected(String message) = _Unexpected;
}
