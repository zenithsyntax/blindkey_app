import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const String keyAppLockEnabled = 'app_lock_enabled';
  static const String keyAppLockPin = 'app_lock_pin';

  Future<Either<Failure, Unit>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return right(unit);
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Future<Either<Failure, String?>> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return right(value);
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return right(unit);
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
