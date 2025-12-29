import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'terms_notifier.g.dart';

@Riverpod(keepAlive: true)
class TermsNotifier extends _$TermsNotifier {
  static const _keyTermsAccepted = 'accepted_terms_v1';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTermsAccepted) ?? false;
  }

  Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTermsAccepted, true);
    state = const AsyncValue.data(true);
  }
}
