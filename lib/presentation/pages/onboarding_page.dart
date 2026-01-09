import 'package:flutter_tilt/flutter_tilt.dart';
import 'dart:ui';
import 'dart:math' as math; // Added import
import 'package:blindkey_app/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Your Private Vault',
      description: 'Store your files in a secure, password-protected space that only you can access.',
      mockWidget: const _MockHomeWidget(),
      color: const Color(0xFFD32F2F), // Red 700
    ),
    OnboardingItem(
      title: 'Store Files Securely',
      description: 'Keep photos, videos, and documents safely organized and easy to view.',
      mockWidget: const _MockFolderWidget(),
      color: const Color(0xFFC62828), // Red 800
    ),
    OnboardingItem(
      title: 'Share with Full Control',
      description: 'Decide how files are shared, set permissions, and apply an expiry when needed.',
      mockWidget: const _MockShareWidget(),
      color: const Color(0xFFB71C1C), // Red 900
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient (Deep & Premium)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF140505), // Subtle red undertone
                    const Color(0xFF000000),
                  ],
                ),
              ),
            ),
          ),
          
          // Animated Background Orb
           AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            top: _currentPage.isEven ? -100 : -50,
            right: _currentPage.isEven ? -100 : null,
            left: _currentPage.isEven ? null : -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _items[_currentPage].color.withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    color: _items[_currentPage].color.withOpacity(0.06),
                    blurRadius: 180,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Page View
                SizedBox(
                  height: 600, // Fixed height for carousel area
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(_items[index]);
                    },
                  ),
                ),

                const Spacer(),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 32 : 12,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFD32F2F)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Main Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _items.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuart,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mock Widget Container with 3D Tilt and Auto-Sway
          Expanded(
            child: Center(
              child: _AutoTiltWrapper(
                child: Tilt(
                  borderRadius: BorderRadius.circular(32),
                  tiltConfig: const TiltConfig(angle: 15),
                  lightConfig: const LightConfig(
                    disable: true,
                  ),
                  shadowConfig: const ShadowConfig(
                    disable: true,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320, maxHeight: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.15),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                          spreadRadius: -10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: item.mockWidget,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),

          
          // Typography
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              item.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final Widget mockWidget;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.mockWidget,
    required this.color,
  });
}

// ---------------------- HIGH FIDELITY MOCK WIDGETS ----------------------

class _MockHomeWidget extends StatelessWidget {
  const _MockHomeWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
         color: const Color(0xFF0F0F0F),
         // Optional: Add the subtle red noise gradient from Home Page for extra polish
      ),
      child: Stack(
        children: [
          // Background Gradient (Professional Red Tint)
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
          
          Column(
            children: [
              // Header (Simplified - Removing Logo/Name as requested)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Row(
                  children: [
                    Text(
                      "Your Vaults",
                      style: GoogleFonts.inter(
                         fontSize: 18, // Slightly larger to act as main header
                         fontWeight: FontWeight.w600,
                         color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "4",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Settings Icon Mock
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
              ),

              // Grid Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85, 
                    padding: const EdgeInsets.only(bottom: 80), 
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                       _buildRealMockVaultCard("Personal", "128 Files", "240 MB", const Color(0xFFE53935)), // Red 600
                       _buildRealMockVaultCard("Work Docs", "64 Files", "850 MB", Colors.white),
                       _buildRealMockVaultCard("Photos", "342 Files", "1.2 GB", const Color(0xFFB71C1C)), // Red 900
                       _buildRealMockVaultCard("Finance", "12 Files", "45 MB", Colors.white54),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // FAB
          Positioned(
             right: 20,
             bottom: 30,
             child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                   color: const Color(0xFFC62828),
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                      BoxShadow(
                         color: const Color(0xFFC62828).withOpacity(0.4),
                         blurRadius: 12,
                         offset: const Offset(0, 6),
                      ),
                   ],
                ),
                child: Row(
                   children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                         "New Vault",
                         style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                         ),
                      ),
                   ],
                ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealMockVaultCard(String title, String count, String size, Color accent) {
     return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.03),
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Container(
                       padding: const EdgeInsets.all(10),
                       decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                       ),
                       child: Icon(Icons.shield_outlined, color: accent, size: 20),
                    ),
                    Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
                 ],
              ),
              const Spacer(),
              Text(
                 title,
                 style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                 ),
              ),
              const SizedBox(height: 4),
              Text(
                 count,
                 style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
              Text(
                 size,
                 style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
              ),
           ],
        ),
     );
  }
}

class _MockFolderWidget extends StatelessWidget {
  const _MockFolderWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Stack(
        children: [
          Column(
            children: [
              // Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                color: const Color(0xFF0F0F0F),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 16),
                    Text(
                      "My Photos",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.search_rounded, color: Colors.white70, size: 22),
                    const SizedBox(width: 16),
                    const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
                  ],
                ),
              ),

              // Files Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            index % 4 == 0 ? Icons.description_rounded : Icons.image_rounded,
                            color: Colors.white.withOpacity(0.2),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 6,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Upload FAB
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: const Color(0xFFC62828),
              elevation: 4,
              icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 20),
              label: Text(
                'Upload',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MockShareWidget extends StatelessWidget {
  const _MockShareWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Matching background of FolderViewPage
      color: const Color(0xFF0F0F0F),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred background elements to simulate depth (optional, keeping consistent with previous mock idea but using new UI)
          Positioned.fill(
             child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: List.generate(12, (index) => Container(
                   decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                   ),
                )),
             ),
          ),
          
          // Original BackdropFilter logic from _ShareDialog
          Positioned.fill(
             child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.5)), // Added slight dim
            ),
          ),

          // Exact UI from _ShareDialog (Scaled Down)
          Container(
             constraints: const BoxConstraints(maxWidth: 280), // Reduced width constraint
             child: Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16), // Reduced padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Export Vault",
                      style: GoogleFonts.inter(
                        fontSize: 18, // Reduced font
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced spacing
                    // Allow Download Switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Tighter tile
                        dense: true, // Compact mode
                        title: Text(
                          "Allow Extraction",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                        subtitle: Text(
                          "Recipients can download",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white30,
                          ),
                        ),
                        value: true, 
                        activeColor: const Color(0xFFEF5350),
                        onChanged: (v) {},
                      ),
                    ),
                    const SizedBox(height: 8), // Reduced spacing
                    // Expiry Date (Simulating a selected date)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        dense: true,
                        title: Text(
                          "Expires: 2026-12-31",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white30,
                          size: 16,
                        ),
                        onTap: () {},
                      ),
                    ),
                    
                    // Clear Expiry Button Mock
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Clear Expiry",
                          style: GoogleFonts.inter(
                            color: Colors.white30,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    

                    
                    const SizedBox(height: 16), // Reduced spacing

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10), // Reduced button height
                            ),
                            child: Text(
                              "Export",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoTiltWrapper extends StatefulWidget {
  final Widget child;
  const _AutoTiltWrapper({required this.child});

  @override
  State<_AutoTiltWrapper> createState() => _AutoTiltWrapperState();
}

class _AutoTiltWrapperState extends State<_AutoTiltWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        // Gentle sway math - Creates a figure-8 sway pattern
        final double tiltX = (math.sin(value * math.pi * 2) * 0.05); 
        final double tiltY = (math.cos(value * math.pi) * 0.05);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective
            ..rotateX(tiltX)
            ..rotateY(tiltY),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}



