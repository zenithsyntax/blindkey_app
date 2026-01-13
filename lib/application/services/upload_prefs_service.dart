import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'upload_prefs_service.g.dart';

@riverpod
class UploadPrefsService extends _$UploadPrefsService {
  static const _keyUploadInfoShown = 'upload_info_shown_v1';

  @override
  FutureOr<void> build() {
    // No initialization needed for now, methods handle prefs directly
    // or we could load state here. For simplicity in a simple boolean check,
    // we can just use async methods or load state.
    // Let's keep it simple: just provide methods to check/set.
  }

  Future<bool> shouldShowUploadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // defaulting to false implies we show it if it's NOT true.
    // wait, "should show" means (shown == false)
    return !(prefs.getBool(_keyUploadInfoShown) ?? false);
  }

  Future<void> setUploadInfoShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUploadInfoShown, true);
  }
}
