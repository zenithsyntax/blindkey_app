import 'package:blindkey_app/presentation/pages/home_page.dart';
import 'package:blindkey_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BlindKeyApp()));
}

class BlindKeyApp extends StatelessWidget {
  const BlindKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlindKey',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkRedTheme,
      home: const HomePage(),
    );
  }
}
