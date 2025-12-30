import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:blindkey_app/presentation/pages/settings/privacy_policy_page.dart';
import 'package:blindkey_app/presentation/pages/settings/terms_content_page.dart';
import 'package:blindkey_app/presentation/pages/settings/user_guide_page.dart';
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
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Security',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient (Matches HomePage)
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
            child: ListView(
              padding: const EdgeInsets.only(top: 24),
              children: [
                _buildGlassTile(
                  child: SwitchListTile(
                    title: Text(
                      'App Lock',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Secure app with PIN',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    value: isEnabled.value!,
                    activeColor: const Color(0xFFEF5350), // Red accent
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    onChanged: (value) async {
                      if (value) {
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
                ),
                
                if (isEnabled.value!)
                  _buildGlassTile(
                    child: ListTile(
                      title: Text(
                        'Change PIN',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () async {
                        final confirmed = await _showConfirmPinDialog(context, notifier);
                        if (confirmed && context.mounted) {
                           final newPin = await _showSetPinDialog(context);
                           if (newPin != null) {
                             await notifier.setPin(newPin);
                             if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'PIN updated successfully', 
                                      style: GoogleFonts.inter(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green.shade800,
                                  ),
                                );
                             }
                           }
                        }
                      },
                    ),
                  ),

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

                // User Guide
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

                // Open Source Licenses
                // _buildGlassTile(
                //   child: ListTile(
                //     title: Text(
                //       'Open Source Licenses',
                //       style: GoogleFonts.inter(
                //         color: Colors.white,
                //         fontSize: 16,
                //         fontWeight: FontWeight.w500,
                //       ),
                //     ),
                //     trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                //     contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                //     onTap: () {
                //       showLicensePage(
                //         context: context,
                //         applicationName: 'BlindKey',
                //         applicationLegalese: 'Copyright © 2025 ZenithSyntax',
                //          applicationIcon: Image.asset(
                //           'assets/blindkey_logo.png',
                //           width: 48,
                //           height: 48,
                //         ),
                //       );
                //     },
                //   ),
                // ),
              ],
            ),
          ),
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
         
         return StatefulBuilder(
           builder: (context, setState) {
             return _buildGlassDialog(
               title: 'Set PIN',
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   TextField(
                     keyboardType: TextInputType.number,
                     maxLength: 4,
                     obscureText: true,
                     onChanged: (v) {
                       pin = v;
                       if (errorText != null) setState(() => errorText = null);
                     },
                     style: GoogleFonts.inter(color: Colors.white),
                     decoration: InputDecoration(
                       labelText: 'Enter 4-digit PIN',
                       labelStyle: GoogleFonts.inter(color: Colors.white54),
                       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                       counterStyle: GoogleFonts.inter(color: Colors.white24),
                     ),
                   ),
                   const SizedBox(height: 16),
                   TextField(
                     keyboardType: TextInputType.number,
                     maxLength: 4,
                     obscureText: true,
                     onChanged: (v) {
                       confirmPin = v;
                       if (errorText != null) setState(() => errorText = null);
                     },
                     style: GoogleFonts.inter(color: Colors.white),
                     decoration: InputDecoration(
                       labelText: 'Confirm PIN',
                       labelStyle: GoogleFonts.inter(color: Colors.white54),
                       errorText: errorText,
                       errorStyle: GoogleFonts.inter(color: Colors.redAccent),
                       enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                       focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                       counterStyle: GoogleFonts.inter(color: Colors.white24),
                     ),
                   ),
                 ],
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context), 
                   child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                 ),
                 TextButton(
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
                   child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFEF5350))),
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

          return StatefulBuilder(
            builder: (context, setState) {
              return _buildGlassDialog(
                title: 'Confirm PIN',
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      onChanged: (v) {
                        pin = v;
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter current PIN',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        errorText: errorText,
                        errorStyle: GoogleFonts.inter(color: Colors.redAccent),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                        counterStyle: GoogleFonts.inter(color: Colors.white24),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                  TextButton(
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
                    child: Text('Confirm', style: GoogleFonts.inter(color: const Color(0xFFEF5350))),
                  ),
                ],
              );
            },
          );
        },
      );
     return result ?? false;
  }

  Widget _buildGlassDialog({required String title, required Widget content, required List<Widget> actions}) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: content,
      ),
      actions: actions,
    );
  }
}
