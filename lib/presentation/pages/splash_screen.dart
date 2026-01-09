import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/presentation/pages/home_page.dart';
import 'package:blindkey_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Main Animation Controller
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    // Staggered Animations
    final fadeAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
        ),
      ),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
        ),
      ),
    );

    final textSlideAnimation = useAnimation(
      Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.3, 0.6, curve: Curves.easeOutBack),
        ),
      ),
    );

    final textFadeAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
        ),
      ),
    );

    useEffect(() {
      controller.forward().then((_) async {
        // Hold for a moment
        await Future.delayed(const Duration(milliseconds: 500));
        // Reverse smoothly
        await controller.reverse().then((_) {
          // Update state and navigate
          ref.read(splashFinishedProvider.notifier).state = true;
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomePage(),
                transitionDuration: const Duration(milliseconds: 600),
                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
              ),
            );
          }
        });
      });
      return null;
    }, []);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A), // Dark Grey
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              Opacity(
                opacity: fadeAnimation,
                child: Transform.scale(
                  scale: scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1), // Slightly more visible
                          blurRadius: 60, // Much wider blur
                          spreadRadius: 20, // More spread
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/blindkey_logo.png',
                      width: 130, // Smaller logo
                      height: 130,
                    ),
                  ),
                ),
              ),
              
              // Animated Text
              Transform.translate(
                offset: textSlideAnimation,
                child: Opacity(
                  opacity: textFadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        "BlindKey",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24, // Smaller text
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontFamily: 'Roboto', 
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "SECURE  •  PRIVATE  •  VAULT",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10, // Smaller tagline
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
