import 'package:blindkey_app/presentation/constants/terms_data.dart';
import 'package:blindkey_app/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsContentPage extends StatelessWidget {
  const TermsContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Match other pages
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient (Generic app BG)
           Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF141414),
                    const Color(0xFF0F0F0F),
                    const Color(0xFF0F0505),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Markdown(
              data: termsAndConditionsData,
              padding: const EdgeInsets.all(24),
              styleSheet: MarkdownStyleSheet(
                h1: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                h2: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 2),
                p: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                listBullet: GoogleFonts.inter(color: Colors.white70),
                strong: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
