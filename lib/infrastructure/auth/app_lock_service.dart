import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/infrastructure/storage/secure_storage_service.dart';
import 'package:dartz/dartz.dart';

class AppLockService {
  final SecureStorageService _secureStorageService;

  AppLockService(this._secureStorageService);

  Future<bool> isAppLockEnabled() async {
    final result = await _secureStorageService.read(SecureStorageService.keyAppLockEnabled);
    return result.fold(
      (l) => false,
      (r) => r == 'true',
    );
  }

  Future<Either<Failure, Unit>> setAppLockEnabled(bool enabled) async {
    if (!enabled) {
      return _secureStorageService.write(SecureStorageService.keyAppLockEnabled, 'false');
    } else {
      return _secureStorageService.write(SecureStorageService.keyAppLockEnabled, 'true');
    }
  }

  Future<bool> hasPin() async {
    final result = await _secureStorageService.read(SecureStorageService.keyAppLockPin);
    return result.fold(
      (l) => false,
      (r) => r != null && r.isNotEmpty,
    );
  }

  Future<Either<Failure, Unit>> setPin(String pin) async {
    return _secureStorageService.write(SecureStorageService.keyAppLockPin, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final result = await _secureStorageService.read(SecureStorageService.keyAppLockPin);
    return result.fold(
      (l) => false,
      (storedPin) => storedPin == pin,
    );
  }
}
