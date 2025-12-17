import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/folder_notifier.dart';
import 'package:blindkey_app/presentation/dialogs/create_folder_dialog.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
import 'package:blindkey_app/presentation/pages/folder_view_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:ui';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderNotifierProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLargeScreen = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep matte black
      body: Stack(
        children: [
          // Subtle professional gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF141414),
                    const Color(0xFF0F0F0F),
                    const Color(0xFF0F0505), // Deep red tint at the bottom
                  ],
                ),
              ),
            ),
          ),
          
          // Noise texture overlay (optional, simulated with opacity)
          // For a cleaner look, we'll stick to a smooth gradient but added a very subtle top shimmer
          Positioned(
            top: -200,
            left: -100,
            right: -100,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    const Color(0xFFE53935).withOpacity(0.08), // Professional Red Glint
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom header
                _buildHeader(context, ref, isTablet, isLargeScreen),

                // Content
                Expanded(
                  child: foldersAsync.when(
                    data: (folders) {
                      if (folders.isEmpty) {
                        return _buildEmptyState(
                          context,
                          isTablet,
                          isLargeScreen,
                        );
                      }
                      return _buildVaultsList(
                        context,
                        ref,
                        folders,
                        isTablet,
                        isLargeScreen,
                      );
                    },
                    error: (e, s) => _buildErrorState(e.toString(), isTablet),
                    loading: () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          Text(
                            'Loading Vaults...',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildModernFAB(context, isTablet),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 40 : 24,
        vertical: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1), // Red accent container
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE53935).withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFEF5350), // Lighter professional red for icon
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BlindKey',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Secure Storage',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Import Button (Minimalist)
          IconButton(
            onPressed: () => _importVault(context, ref),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(12),
            ),
            icon: const Icon(
              Icons.upload_file_outlined,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Import Vault',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Vaults found',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your secure vaults will appear here.\nCreate one to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            _buildGlassButton(
              onPressed: () => _showCreateFolderDialog(context),
              icon: Icons.add,
              label: 'Create New Vault',
              isPrimary: true,
              isTablet: isTablet,
              isLargeScreen: isLargeScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultsList(
    BuildContext context,
    WidgetRef ref,
    List folders,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 40 : 24,
              vertical: 16,
            ),
            child: Row(
              children: [
                Text(
                  'Your Vaults',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${folders.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 40 : 24,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isLargeScreen ? 3 : (isTablet ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isLargeScreen ? 1.6 : 1.8,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final folder = folders[index];
              return _buildModernVaultCard(
                context,
                ref,
                folder,
                isTablet,
                isLargeScreen,
              );
            }, childCount: folders.length),
          ),
        ),
        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildModernVaultCard(
    BuildContext context,
    WidgetRef ref,
    dynamic folder,
    bool isTablet,
    bool isLargeScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: Colors.white.withOpacity(0.03),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFolder(context, ref, folder),
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withOpacity(0.05),
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFFEF5350), // Red accent
                        size: 20,
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white24,
                        size: 20,
                      ),
                      color: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          _showRenameDialog(context, ref, folder);
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, folder);
                        }
                      },
                      itemBuilder: (context) => [
                         PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'Rename',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                         PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: GoogleFonts.inter(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, child) {
                        final statsAsync = ref.watch(folderStatsProvider(folder.id));
                        return statsAsync.when(
                          data: (stats) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.fileCount} Files',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stats.sizeString} / 500 MB',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: stats.totalSize > 500 * 1024 * 1024 
                                      ? Colors.red.shade300 
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          loading: () => Text(
                            'Loading...',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white24),
                          ),
                          error: (_, __) => Text(
                            '--',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white24),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isTablet,
    required bool isLargeScreen,
  }) {
    return SizedBox(
      height: 52,
      width: isTablet || isLargeScreen ? 300 : double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.white.withOpacity(0.05),
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isTablet) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load vaults',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFAB(BuildContext context, bool isTablet) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateFolderDialog(context),

      backgroundColor: const Color(0xFFC62828), // Professional Deep Red
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'New Vault',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const CreateFolderDialog());
  }

  Future<void> _importVault(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => HookConsumer(
          builder: (context, ref, child) {
            final passwordController = useTextEditingController();
            final isLoading = useState(false);
            final errorText = useState<String?>(null);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Unlock Vault',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the password to access this vault file',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        enabled: !isLoading.value,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: GoogleFonts.inter(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          errorText: errorText.value,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white30),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading.value ? null : () async {
                            isLoading.value = true;
                            errorText.value = null;
                            
                            await Future.delayed(const Duration(milliseconds: 50));
                            
                            try {
                              await ref
                                  .read(folderNotifierProvider.notifier)
                                  .importFolder(path, passwordController.text);
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Vault imported successfully',
                                      style: GoogleFonts.inter(),
                                    ),
                                    backgroundColor: Colors.green.shade800,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                isLoading.value = false;
                                // Can show error in text field or snackbar. Keeps snackbar for now but clears loading
                                // Actually, let's use errorText for better UX
                                errorText.value = 'Import failed: Incorrect password or corrupted file';
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.white24,
                            disabledForegroundColor: Colors.white38,
                          ),
                          child: isLoading.value 
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)
                              )
                            : Text(
                                'Unlock & Import',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                      if (isLoading.value) ...[
                         const SizedBox(height: 16),
                         TextButton(
                           onPressed: null, // Cannot cancel easily during import if it's atomic
                           child: Text("Importing...", style: GoogleFonts.inter(color: Colors.white30)),
                         )
                      ] else ...[
                         const SizedBox(height: 16),
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: Text("Cancel", style: GoogleFonts.inter(color: Colors.white54)),
                         )
                      ]
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  void _openFolder(BuildContext context, WidgetRef ref, dynamic folder) {
    // Always ask for password as we don't store keys in memory for security
    // or we haven't implemented a session key cache yet.
    _showUnlockDialog(context, ref, folder);
  }

  void _showUnlockDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic folder,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while loading if we want, but let's allow if not loading
      builder: (context) => HookConsumer(
        builder: (context, ref, child) {
          final passwordController = useTextEditingController();
          final isLoading = useState(false);
          final errorText = useState<String?>(null);

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Dialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Unlock Vault',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      folder.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      enabled: !isLoading.value,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
                        hintStyle: GoogleFonts.inter(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        errorText: errorText.value,
                        errorMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        prefixIcon: const Icon(Icons.key_rounded, color: Colors.white30),
                      ),
                      onSubmitted: (_) {
                         // Trigger unlock on enter
                         if (!isLoading.value) {
                            // ... duplicate logic or call function
                         }
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading.value ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white60,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading.value ? null : () async {
                              isLoading.value = true;
                              errorText.value = null;
                              
                              // Slight delay to ensure UI updates to loading state before potential heavy crypto work
                              await Future.delayed(const Duration(milliseconds: 50));
                              
                              try {
                                final result = await ref
                                    .read(folderNotifierProvider.notifier)
                                    .unlockFolder(folder.id, passwordController.text);
                                
                                if (context.mounted) {
                                  if (result != null && result is SecretKey) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FolderViewPage(
                                          folder: folder,
                                          folderKey: result,
                                        ),
                                      ),
                                    );
                                  } else {
                                    isLoading.value = false;
                                    errorText.value = 'Incorrect password';
                                    passwordController.clear();
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  isLoading.value = false;
                                  errorText.value = 'An error occurred: $e';
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
                              disabledBackgroundColor: Colors.white24,
                              disabledForegroundColor: Colors.white38,
                            ),
                            child: isLoading.value 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, 
                                    color: Colors.white70
                                  )
                                )
                              : Text(
                                  'Unlock',
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
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, dynamic folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rename Vault',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Vault Name',
                    hintStyle: GoogleFonts.inter(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            await ref.read(folderNotifierProvider.notifier).renameFolder(folder.id, controller.text);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic folder) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text('Delete Vault?', style: GoogleFonts.inter(color: Colors.white)),
          content: Text(
            'This will permanently delete "${folder.name}" and all its contents. This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(folderNotifierProvider.notifier).deleteFolder(folder.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
