import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
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

    // Listen to lifecycle
    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.paused) {
         // App is backgrounded
         // We should lock if enabled.
         // Calling lockApp() on notifier.
         // It's safe to read notifier here? Yes.
         ref.read(appLockNotifierProvider.notifier).lockApp();
      }
    });

    final isLocked = ref.watch(appLockNotifierProvider);

    return MaterialApp(
      title: 'BlindKey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkRedTheme,
      home: const HomePage(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            if (isLocked)
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
