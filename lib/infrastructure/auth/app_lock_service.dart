import 'dart:convert';
import 'dart:math';

import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/infrastructure/storage/secure_storage_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dartz/dartz.dart';

class AppLockService {
  final SecureStorageService _secureStorageService;

  AppLockService(this._secureStorageService);

  Future<String> _hashPin(String pin, String salt) async {
    final algorithm = Sha256();
    final hash = await algorithm.hash(utf8.encode(pin + salt));
    return base64Encode(hash.bytes);
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Encode(bytes);
  }

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
    try {
      final salt = _generateSalt();
      final hash = await _hashPin(pin, salt);
      await _secureStorageService.write('app_lock_pin_salt', salt);
      return await _secureStorageService.write(SecureStorageService.keyAppLockPin, hash);
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Future<bool> verifyPin(String pin) async {
    final saltResult = await _secureStorageService.read('app_lock_pin_salt');
    final salt = saltResult.fold((l) => null, (r) => r);

    final storedResult = await _secureStorageService.read(SecureStorageService.keyAppLockPin);
    return await storedResult.fold(
      (l) async => false,
      (storedValue) async {
        if (storedValue == null) return false;

        // Backward compatibility: If no salt exists, verify as plaintext and migrate
        if (salt == null || salt.isEmpty) {
          if (storedValue == pin) {
            await setPin(pin); // Auto-migrate to hashed version
            return true;
          }
          return false;
        }

        final computedHash = await _hashPin(pin, salt);
        return computedHash == storedValue;
      },
    );
  }
}
