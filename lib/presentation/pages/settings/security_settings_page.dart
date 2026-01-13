import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:blindkey_app/presentation/pages/settings/privacy_policy_page.dart';
import 'package:blindkey_app/presentation/pages/settings/terms_content_page.dart';
import 'package:blindkey_app/presentation/pages/settings/user_guide_page.dart';
import 'package:blindkey_app/presentation/utils/custom_snackbar.dart';
import 'package:google_fonts/google_fonts.dart';

class SecuritySettingsPage extends HookConsumerWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appLockNotifierProvider.notifier);
    final isEnabled = useState<bool?>(null);

    useEffect(() {
      notifier.isEnabled().then((value) => isEnabled.value = value);
      return null;
    }, []);

    if (isEnabled.value == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Dark background
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Security Section
          _buildSectionHeader('Security'),
          _buildAppLockCard(
            isEnabled: isEnabled.value!,
            onTap: () async {
              if (!isEnabled.value!) {
                // Enable
                final hasPin = await notifier.hasPin();
                if (!context.mounted) return;
                
                if (!hasPin) {
                   final pin = await _showSetPinDialog(context);
                   if (pin != null) {
                     await notifier.setPin(pin);
                     await notifier.setEnabled(true);
                     isEnabled.value = true;
                   }
                } else {
                   await notifier.setEnabled(true);
                   isEnabled.value = true;
                }
              } else {
                // Disable
                final confirmed = await _showConfirmPinDialog(context, notifier);
                if (confirmed) {
                  await notifier.setEnabled(false);
                  isEnabled.value = false;
                }
              }
            },
          ),
          
          if (isEnabled.value!) ...[
            const SizedBox(height: 16),
            _buildChangePinButton(
              onTap: () async {
                final confirmed = await _showConfirmPinDialog(context, notifier);
                if (confirmed && context.mounted) {
                   final newPin = await _showSetPinDialog(context);
                   if (newPin != null) {
                     await notifier.setPin(newPin);
                     if (context.mounted) {
                       CustomSnackbar.showSuccess(
                         context,
                         'PIN updated successfully',
                       );
                     }
                   }
                }
              },
            ),
          ],

          const SizedBox(height: 32),

          // Support Section
          _buildSectionHeader('Support'),
          _buildGlassTile(
            child: ListTile(
              title: Text(
                'User Guide',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserGuidePage(autoPlay: false),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Legal Section
          _buildSectionHeader('Legal'),
          
          // Terms and Conditions
          _buildGlassTile(
            child: ListTile(
              title: Text(
                'Terms and Conditions',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TermsContentPage(),
                  ),
                );
              },
            ),
          ),

          // Privacy Policy
          _buildGlassTile(
            child: ListTile(
              title: Text(
                'Privacy Policy',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 48),
          
          // App Version
          _buildVersionFooter(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGlassTile({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Future<String?> _showSetPinDialog(BuildContext context) async {
     String pin = '';
     String confirmPin = '';
     
     return showDialog<String>(
       context: context,
       barrierDismissible: false,
       builder: (context) {
         String? errorText;
         bool obscurePin = true;
         bool obscureConfirm = true;
         
         return StatefulBuilder(
           builder: (context, setState) {
             return _buildPremiumDialog(
               context: context,
               title: 'Set Security PIN',
               icon: Icons.lock_outline_rounded,
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                      'Create a 4-digit PIN to secure your vaults.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                   ),
                   const SizedBox(height: 24),
                   _buildPremiumTextField(
                     label: 'Enter PIN',
                     onChanged: (v) {
                       pin = v;
                       if (errorText != null) setState(() => errorText = null);
                     },
                     autoFocus: true,
                     obscureText: obscurePin,
                     onToggleObscure: () => setState(() => obscurePin = !obscurePin),
                   ),
                   const SizedBox(height: 16),
                   _buildPremiumTextField(
                     label: 'Confirm PIN',
                     onChanged: (v) {
                       confirmPin = v;
                       if (errorText != null) setState(() => errorText = null);
                     },
                     errorText: errorText,
                     obscureText: obscureConfirm,
                     onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
                   ),
                 ],
               ),
               actions: [
                 Row(
                   children: [
                     Expanded(
                       child: TextButton(
                         onPressed: () => Navigator.pop(context), 
                         style: TextButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w500)),
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: ElevatedButton(
                         onPressed: () {
                           if (pin.length != 4) {
                              setState(() => errorText = 'PIN must be 4 digits');
                              return;
                           }
                           
                           if (pin != confirmPin) {
                             setState(() => errorText = 'PINs do not match');
                           } else {
                             Navigator.pop(context, pin);
                           }
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFD32F2F),
                           foregroundColor: Colors.white,
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: Text('Save PIN', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                       ),
                     ),
                   ],
                 ),
               ],
             );
           }
         );
       },
     );
  }

  Future<bool> _showConfirmPinDialog(BuildContext context, AppLockNotifier notifier) async {
      String pin = '';
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          String? errorText;
          bool obscurePin = true;

          return StatefulBuilder(
            builder: (context, setState) {
              return _buildPremiumDialog(
                context: context,
                title: 'Verify Identity',
                icon: Icons.shield_rounded,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Please enter your current PIN to continue.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _buildPremiumTextField(
                      label: 'Enter Current PIN',
                      onChanged: (v) {
                        pin = v;
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                      errorText: errorText,
                      autoFocus: true,
                      obscureText: obscurePin,
                      onToggleObscure: () => setState(() => obscurePin = !obscurePin),
                    ),
                  ],
                ),
                actions: [
                   Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (pin.length == 4) {
                              final valid = await notifier.verifyPin(pin);
                              if (context.mounted) {
                                if (valid) {
                                  Navigator.pop(context, true);
                                } else {
                                  setState(() {
                                    errorText = 'Incorrect PIN';
                                  });
                                }
                              }
                            }
                          }, 
                          style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFD32F2F),
                           foregroundColor: Colors.white,
                           elevation: 0,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                          child: Text('Confirm', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
     return result ?? false;
  }

  Widget _buildPremiumDialog({
    required BuildContext context,
    required String title,
    required IconData icon, // Kept in signature to avoid breaking callers, but unused in UI
    required Widget content,
    required List<Widget> actions,
  }) {
    final size = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        // Responsive width: max 340px, or screen width minus padding
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon removed as requested
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 20),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required Function(String) onChanged,
    String? errorText,
    bool autoFocus = false,
    bool obscureText = true,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorText != null)
           Padding(
             padding: const EdgeInsets.only(bottom: 6.0, left: 4),
             child: Text(
               errorText,
               style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 11),
             ),
           ),
        TextField(
          onChanged: onChanged,
          autofocus: autoFocus,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: obscureText,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20, // Reduced from 24
            fontWeight: FontWeight.w600,
            letterSpacing: 6, // Reduced from 8
          ),
          cursorColor: const Color(0xFFEF5350),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            hintText: '••••',
            hintStyle: GoogleFonts.inter(
              color: Colors.white12,
              fontSize: 20, // Reduced from 24
              letterSpacing: 6, // Reduced from 8
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Reduced padding
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Reduced radius slightly
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFEF5350).withOpacity(0.5)),
            ),
            errorText: null, // Handled manually above
            suffixIcon: onToggleObscure != null 
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  ) 
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAppLockCard({
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    // Professional color palette for active state
    final activeColor = const Color(0xFFD32F2F); // Premium red
    final activeBgColor = const Color(0xFFD32F2F).withOpacity(0.12);
    
    // Light red border color as requested
    final borderColor = const Color(0xFFEF5350).withOpacity(0.3); // Light red

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(24), 
        decoration: BoxDecoration(
          color: isEnabled ? activeBgColor : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEnabled ? borderColor.withOpacity(0.6) : borderColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: activeColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            )
          ] : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isEnabled ? activeColor.withOpacity(0.9) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isEnabled ? [
                   BoxShadow(
                     color: activeColor.withOpacity(0.3), 
                     blurRadius: 12, 
                     offset: const Offset(0, 4),
                   ),
                ] : [],
              ),
              child: Icon(
                isEnabled ? Icons.shield_rounded : Icons.lock_open_rounded,
                color: isEnabled ? Colors.white : Colors.white54,
                size: 26,
              ),
            ),
            const SizedBox(width: 20),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnabled ? 'App Lock Enabled' : 'App Lock',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEnabled 
                      ? 'Great! You need to enter your PIN every time you open the app.'
                      : 'Secure the app by requiring a PIN when it is opened',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isEnabled ? Colors.white70 : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),

            // Premium Toggle Switch
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: isEnabled ? activeColor : Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: isEnabled ? Colors.transparent : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                     AnimatedAlign(
                       duration: const Duration(milliseconds: 300),
                       curve: Curves.easeOutBack,
                       alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                       child: Container(
                         margin: const EdgeInsets.all(3),
                         width: 24,
                         height: 24,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2), 
                               blurRadius: 4,
                               offset: const Offset(0, 2),
                             ),
                           ],
                         ),
                         child: isEnabled 
                            ? Center(
                                child: Icon(Icons.check, size: 14, color: activeColor),
                              )
                            : null,
                       ),
                     ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildChangePinButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sync_lock_rounded, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Change PIN',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return Center(
      child: Column(
        children: [
          Text(
            'Version 1.0.1',
            style: GoogleFonts.inter(
              color: Colors.white30,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 ZenithSyntax',
            style: GoogleFonts.inter(
              color: Colors.white24,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
