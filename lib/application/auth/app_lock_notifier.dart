import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/infrastructure/auth/app_lock_service.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lock_notifier.g.dart';

@Riverpod(keepAlive: true)
class AppLockNotifier extends _$AppLockNotifier {
  
  AppLockService get _appLockService => ref.read(appLockServiceProvider);

  @override
  bool build() {
    return false; // Initial state: isLocked = false
  }

  // Remove setService

  Future<void> initialize() async {
    // Check if lock is enabled
    final isEnabled = await _appLockService.isAppLockEnabled();
    if (isEnabled) {
      state = true; // Lock the app immediately if enabled
    }
  }

  void lockApp() {
     // Only lock if enabled? Ideally yes, but the UI calling this should know or we check here.
     // We can check async but we can't await in a synchronous void method easily without side effects.
     // Better pattern: The caller (Lifecycle listener) checks if enabled.
     // OR update state to locked, and if it turns out disabled, unlock immediately.
     // Let's assume the listener checks.
     state = true;
  }

  void unlockApp() {
    state = false;
  }

  Future<bool> verifyPin(String pin) async {
    final isValid = await _appLockService.verifyPin(pin);
    if (isValid) {
      unlockApp();
    }
    return isValid;
  }
  
  Future<bool> isEnabled() => _appLockService.isAppLockEnabled();
  
  Future<void> setEnabled(bool enabled) async {
      await _appLockService.setAppLockEnabled(enabled);
  }
  
  Future<void> setPin(String pin) async {
      await _appLockService.setPin(pin);
  }
  
  Future<bool> hasPin() => _appLockService.hasPin();
}
