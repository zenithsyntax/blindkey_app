import 'dart:ui';

import 'package:blindkey_app/application/store/folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateFolderDialog extends HookConsumerWidget {
  const CreateFolderDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isMatching = useState(true);
    final isLoading = useState(false);

    // Common Input Decoration
    InputDecoration buildInputDecoration(String label, {String? errorText}) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white54),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Secure Vault',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: Colors.blueAccent,
                    decoration: buildInputDecoration('Vault Name'),
                    validator: (v) => v!.isEmpty ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: Colors.blueAccent,
                    decoration: buildInputDecoration('Password'),
                    obscureText: true,
                    validator: (v) => v!.length < 4 ? 'Min 4 chars' : null,
                    onChanged: (_) {
                      isMatching.value =
                          passwordController.text == confirmPasswordController.text;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: confirmPasswordController,
                    style: GoogleFonts.inter(color: Colors.white),
                    cursorColor: Colors.blueAccent,
                    decoration: buildInputDecoration(
                      'Confirm Password',
                      errorText: isMatching.value ? null : 'Passwords do not match',
                    ),
                    obscureText: true,
                    onChanged: (_) {
                      isMatching.value =
                          passwordController.text == confirmPasswordController.text;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isLoading.value ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading.value
                              ? () {}
                              : () async {
                                  if (formKey.currentState!.validate() &&
                                      isMatching.value) {
                                    isLoading.value = true;
                                    try {
                                      // Artificial delay for better UX if operation is too fast?
                                      // Optional, but usually nice to see the spinner.
                                      // await Future.delayed(const Duration(milliseconds: 500));
                                      
                                      await ref
                                          .read(folderNotifierProvider.notifier)
                                          .createFolder(
                                            nameController.text,
                                            passwordController.text,
                                          );
                                      if (context.mounted) Navigator.pop(context);
                                    } catch (e) {
                                      // Handle error?
                                      isLoading.value = false;
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  'Create',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
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
      ),
    );
  }
}
