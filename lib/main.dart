import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
import 'package:flutter/services.dart';
import 'package:blindkey_app/application/onboarding/terms_notifier.dart';
import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/presentation/pages/auth/app_lock_screen.dart';
import 'package:blindkey_app/presentation/pages/home_page.dart';
import 'package:blindkey_app/presentation/pages/splash_screen.dart';
import 'package:blindkey_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:screen_protector/screen_protector.dart';
import 'package:safe_device/safe_device.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AdMob
  await MobileAds.instance.initialize();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Security Hardening: Secure Screen (Prevent Screenshots/Recording)
  // Only available on Android. iOS handles this differently (usually via specific event listeners or blanking screens).
  if (Platform.isAndroid) {
    try {
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      debugPrint('Specific security flag failed: $e');
    }
  }

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

    // Root/Jailbreak Detection Check
    useEffect(() {
      Future<void> checkSecurity() async {
        try {
          bool isJailBroken = await SafeDevice.isJailBroken;
          bool isRealDevice = await SafeDevice.isRealDevice;
          // Note: Emulators are often used for dev, so strict 'isRealDevice' might block you if testing on emulator.
          // For production "Maximum Security", we might want to warn or close.
          // For now, let's just log or maybe show a warning dialog if strictly requested.
          // User asked for "Maximum Secure".
          if (isJailBroken) {
             // We can redirect to a "Security Violation" page or just exit.
             // But let's be careful not to brick users abruptly. 
             // Ideally: Show a blocking dialog.
             // Since we are in `build`, we can't easily push a dialog immediately without context/scheduler.
             // We will handle this by checking a provider state? 
             // Or simplified: just run it.
          }
        } catch (_) {}
      }
      checkSecurity();
      return null;
    }, []);

    final isLocked = ref.watch(appLockNotifierProvider);
    final termsState = ref.watch(termsNotifierProvider);
    final hasAcceptedTerms = termsState.valueOrNull ?? false;
    final splashFinished = ref.watch(splashFinishedProvider); // Watch splash state
    
    // Security Check Provider (Simplified for this file)
    // We could make a dedicated SecurityNotifier but inline is faster for now.
    final securityCheck = useFuture(useMemoized(() async {
      if (Platform.isAndroid || Platform.isIOS) {
         return await SafeDevice.isJailBroken;
      }
      return false;
    }));

    if (securityCheck.hasData && securityCheck.data == true) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security_rounded, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Security Violation",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "This device appears to be rooted or jailbroken. For security reasons, BlindKey cannot run on compromised devices.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'BlindKey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkRedTheme,
      home: const SplashScreen(),
      builder: (context, child) {
        // Only apply lock screen if terms are accepted AND splash is finished
        final showLock = isLocked && hasAcceptedTerms && splashFinished;
        
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
