import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
import 'package:blindkey_app/application/onboarding/terms_notifier.dart';
import 'package:blindkey_app/presentation/pages/auth/app_lock_screen.dart';
import 'package:blindkey_app/presentation/pages/home_page.dart';
import 'package:blindkey_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BlindKeyApp()));
}

class BlindKeyApp extends HookConsumerWidget {
  const BlindKeyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize App Lock
    useEffect(() {
       ref.read(appLockNotifierProvider.notifier).initialize();
       return null;
    }, []);

    final isLocked = ref.watch(appLockNotifierProvider);
    final termsState = ref.watch(termsNotifierProvider);
    final hasAcceptedTerms = termsState.valueOrNull ?? false;

    return MaterialApp(
      title: 'BlindKey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkRedTheme,
      home: const HomePage(),
      builder: (context, child) {
        // Only apply lock screen if terms are accepted (or if we want to lock before terms? usually after)
        // Actually, if terms are NOT accepted, the HomePage shows the Terms Dialog overlay.
        // We probably don't want the Lock Screen covering the Terms Dialog.
        final showLock = isLocked && hasAcceptedTerms;
        
        return Stack(
          children: [
            if (child != null) child,
            if (showLock)
              const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: AppLockScreen(),
              ),
          ],
        );
      },
    );
  }
}
