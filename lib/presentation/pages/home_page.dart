import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/services/ad_service.dart';
import 'package:blindkey_app/application/services/file_intent_service.dart';
import 'package:blindkey_app/application/services/file_intent_service.dart';
import 'package:blindkey_app/application/store/folder_notifier.dart';
import 'package:blindkey_app/presentation/dialogs/create_folder_dialog.dart';
import 'package:blindkey_app/presentation/dialogs/terms_dialog.dart';
import 'package:blindkey_app/presentation/pages/settings/security_settings_page.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
import 'package:blindkey_app/presentation/pages/folder_view_page.dart';
import 'package:blindkey_app/application/onboarding/terms_notifier.dart';
import 'package:blindkey_app/presentation/widgets/banner_ad_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:ui';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // Added import
import 'package:blindkey_app/presentation/utils/error_mapper.dart';
import 'package:blindkey_app/presentation/utils/custom_snackbar.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImporting = useState(false);
    final foldersAsync = ref.watch(folderNotifierProvider);
    final termsState = ref.watch(termsNotifierProvider);
    final termsAccepted =
        termsState.valueOrNull ??
        true; // Default to true while loading to avoid flash, or false?
    // Actually if loading, it defaults to null. If null, we assume valid until loaded?
    // User wants it to POPUP. If it is not accepted, it should be false.
    // If loading, AsyncValue.loading has no value.
    // Let's assume false if we know for sure it's false.
    // But if we default to true, it won't show. If default to false, it shows then hides.
    // Ideally we wait for loading in main, BUT we moved to HomePage.
    // Let's check: prefs is fast.

    final shouldShowTerms = !termsAccepted && !termsState.isLoading;

    // Listen for external file intents (Open With)
    ref.listen(fileIntentServiceProvider, (previous, path) {
      if (path != null) {
        // Clear the intent so we don't handle it again
        ref.read(fileIntentServiceProvider.notifier).clearIntent();
        // Handle the import
        _handleImportIntent(context, ref, isImporting, path);
      }
    });

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLargeScreen = size.width > 900;

    return Stack(
      children: [
        Scaffold(
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

              // Noise texture overlay (responsive)
              Positioned(
                top: -size.height * 0.2, // Relative to screen height
                left: -size.width * 0.2, // Relative to screen width
                right: -size.width * 0.2,
                height: size.height * 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        const Color(
                          0xFFE53935,
                        ).withOpacity(0.08), // Professional Red Glint
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                minimum: const EdgeInsets.only(
                  top: 30,
                ), // Fix for camera overlap
                child: Column(
                  children: [
                    // Custom header - with responsive padding
                    _buildHeader(
                      context,
                      ref,
                      isTablet,
                      isLargeScreen,
                      isImporting,
                    ),

                    // Content - flexible to prevent overflow
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
                        error: (e, s) => _buildErrorState(
                          ErrorMapper.getUserFriendlyError(e),
                          isTablet,
                        ),
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

                    // Banner Ad at bottom
                    Container(
                      color: const Color(0xFF0F0F0F),
                      child: BannerAdWidget(adUnitId: AdService.homeBannerAdId),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _ExpandableVaultFAB(
            onCreateVault: () => _showCreateFolderDialog(context),
            onImportFolder: () => _importFolder(context, ref, isImporting),
          ),
        ),

        // Terms Overlay
        if (shouldShowTerms) const Positioned.fill(child: TermsDialog()),

        // Import Loader
        // Import Loader
        if (isImporting.value)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Processing file...",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool isTablet,
    bool isLargeScreen,
    ValueNotifier<bool> isImporting,
  ) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;
    final isSmallHeight = size.height < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : (isLargeScreen ? 40 : 24),
        vertical: isSmallHeight ? 16 : (isSmallScreen ? 20 : 24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/blindkey_logo.png',
                    width: isSmallScreen ? 48 : (isLargeScreen ? 60 : 54),
                    height: isSmallScreen ? 48 : (isLargeScreen ? 60 : 54),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BlindKey',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Secure Storage',
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Icons aligned to the right
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              IconButton(
                onPressed: () => _importVault(context, ref, isImporting),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  minimumSize: Size(
                    isSmallScreen ? 36 : 40,
                    isSmallScreen ? 36 : 40,
                  ),
                ),
                icon: Icon(
                  Icons.upload_file_outlined,
                  color: Colors.white70,
                  size: isSmallScreen ? 18 : 20,
                ),
                tooltip: 'Import Vault',
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              IconButton(
                onPressed: () {
                  // Navigation to settings
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SecuritySettingsPage(),
                    ),
                  );
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  minimumSize: Size(
                    isSmallScreen ? 36 : 40,
                    isSmallScreen ? 36 : 40,
                  ),
                ),
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white70,
                  size: isSmallScreen ? 18 : 20,
                ),
                tooltip: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _importFolder(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isImporting,
  ) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (!status.isGranted) {
          if (context.mounted) {
            CustomSnackbar.showError(
              context,
              "Storage permission required to import folders.",
            );
          }
          return;
        }
      }

      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) return;

      // 1. Check size
      isImporting.value = true;
      final dir = Directory(path);
      int totalSize = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      // 2GB Limit
      if (totalSize > 2 * 1024 * 1024 * 1024) {
        isImporting.value = false;
        if (context.mounted) {
          CustomSnackbar.showError(
            context,
            'Folder size exceeds 2GB limit. Please select a smaller folder.',
          );
        }
        return;
      }

      isImporting.value = false;

      // 2. Show Dialog to get Vault Name and Password
      if (context.mounted) {
        _showImportFolderDialog(
          context,
          ref,
          path,
          dir.path.split(Platform.pathSeparator).last,
        );
      }
    } catch (e) {
      isImporting.value = false;
      if (context.mounted) {
        CustomSnackbar.showError(context, 'Failed to read folder: $e');
      }
    }
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
    // We use a LayoutBuilder to get the exact available width for the grid.
    // This allows us to calculate the precise aspect ratio required to maintain
    // a consistent card height, regardless of the screen width or grid column count.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmallScreen = width < 600;

        // Determine column count based on available width
        // We want cards to be roughly 160-200px wide on phones, and larger on tablets
        int crossAxisCount;
        if (width > 1200) {
          crossAxisCount = 5;
        } else if (width > 900) {
          crossAxisCount = 4;
        } else if (width > 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2; // Always at least 2 columns for grid look
        }

        // Standardized spacing
        final double spacing = isSmallScreen ? 12.0 : 20.0;
        final double padding = isSmallScreen ? 16.0 : 32.0;

        // Calculate item width
        // width = padding*2 + itemWidth*count + spacing*(count-1)
        // itemWidth = (width - padding*2 - spacing*(count-1)) / count
        final double totalHorizontalPadding = padding * 2;
        final double totalSpacing = spacing * (crossAxisCount - 1);
        final double itemWidth =
            (width - totalHorizontalPadding - totalSpacing) / crossAxisCount;

        // FIXED HEIGHT STRATEGY
        // We define a fixed height that safely accommodates all content.
        // Base height 200 + adjustments for text scale.
        final textScale = MediaQuery.textScaleFactorOf(context);
        final double baseHeight =
            200.0; // Sufficient for Icon + Texts + Spacing
        final double scaledHeight =
            baseHeight *
            (textScale > 1.0 ? (1.0 + (textScale - 1.0) * 0.5) : 1.0);

        // Calculate Aspect Ratio: ratio = width / height
        final double childAspectRatio = (itemWidth / scaledHeight).clamp(
          0.5,
          2.0,
        );

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding / 2,
                  padding,
                  padding / 2,
                ),
                child: Row(
                  children: [
                    Text(
                      'Your Vaults',
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 16 : 18,
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
              padding: EdgeInsets.symmetric(horizontal: padding),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final folder = folders[index];
                  return _buildModernVaultCard(context, ref, folder);
                }, childCount: folders.length),
              ),
            ),
            // Bottom padding to avoid FAB overlap
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildModernVaultCard(
    BuildContext context,
    WidgetRef ref,
    dynamic folder,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openFolder(context, ref, folder),
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withOpacity(0.05),
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon and Menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(
                        2,
                      ), // Optional inner padding
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Image.asset(
                        'assets/vault_icon.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white24,
                          size: 20,
                        ),
                        color: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
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
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
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
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Folder Name
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

                const SizedBox(height: 4),

                // Stats
                Consumer(
                  builder: (context, ref, child) {
                    final statsAsync = ref.watch(
                      folderStatsProvider(folder.id),
                    );
                    return statsAsync.when(
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.fileCount} Files',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${stats.sizeString} / 2 GB',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: stats.totalSize > 2 * 1024 * 1024 * 1024
                                  ? Colors.red.shade300
                                  : Colors.white38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                      error: (_, __) => Text(
                        '--',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white24,
                        ),
                      ),
                    );
                  },
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
          backgroundColor: isPrimary
              ? Colors.white
              : Colors.white.withOpacity(0.05),
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
            AutoSizeText(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
              maxLines: 4,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const CreateFolderDialog());
  }


  Future<void> _importVault(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isImporting,
  ) async {
    isImporting.value = true;
    try {
      // Using a small delay to allow the loading indicator to render before the platform channel hangs (if it does)
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;

        if (!path.toLowerCase().endsWith('.blindkey')) {
          isImporting.value = false;
          if (context.mounted) {
            CustomSnackbar.showError(
              context,
              'Only .blindkey files can be uploaded. This file format is not supported.',
            );
          }
          return;
        }

        if (!context.mounted) return;

        isImporting.value = false;

        await _showImportPasswordDialog(context, ref, path);
      }
    } catch (e) {
      debugPrint("Import Error: $e");
    } finally {
      isImporting.value = false;
    }
  }

  void _openFolder(BuildContext context, WidgetRef ref, dynamic folder) {
    // Always ask for password as we don't store keys in memory for security
    // or we haven't implemented a session key cache yet.
    _showUnlockDialog(context, ref, folder);
  }

  void _showUnlockDialog(BuildContext context, WidgetRef ref, dynamic folder) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing while loading if we want, but let's allow if not loading
      builder: (context) => HookConsumer(
        builder: (context, ref, child) {
          final passwordController = useTextEditingController();
          final isLoading = useState(false);
          final errorText = useState<String?>(null);
          final isObscured = useState(true);

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
                child: SingleChildScrollView(
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
                        obscureText: isObscured.value,
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
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.key_rounded,
                            color: Colors.white30,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isObscured.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white30,
                            ),
                            onPressed: () {
                              isObscured.value = !isObscured.value;
                            },
                          ),
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
                              onPressed: isLoading.value
                                  ? null
                                  : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white60,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading.value
                                  ? null
                                  : () async {
                                      isLoading.value = true;
                                      errorText.value = null;

                                      // Slight delay to ensure UI updates to loading state before potential heavy crypto work
                                      await Future.delayed(
                                        const Duration(milliseconds: 50),
                                      );

                                      try {
                                        final result = await ref
                                            .read(
                                              folderNotifierProvider.notifier,
                                            )
                                            .unlockFolder(
                                              folder.id,
                                              passwordController.text,
                                            );

                                        if (context.mounted) {
                                          if (result != null &&
                                              result is SecretKey) {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FolderViewPage(
                                                      folder: folder,
                                                      folderKey: result,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            isLoading.value = false;
                                            errorText.value =
                                                'Incorrect password';
                                            passwordController.clear();
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          isLoading.value = false;
                                          errorText.value =
                                              ErrorMapper.getUserFriendlyError(
                                                e,
                                              );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                        color: Colors.white70,
                                      ),
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
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(color: Colors.white60),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            try {
                              await ref
                                  .read(folderNotifierProvider.notifier)
                                  .renameFolder(folder.id, controller.text);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                CustomSnackbar.showError(
                                  context,
                                  ErrorMapper.getUserFriendlyError(e),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
          title: Text(
            'Delete Vault?',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Text(
            'This will permanently delete "${folder.name}" and all its contents. This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(folderNotifierProvider.notifier)
                      .deleteFolder(folder.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    CustomSnackbar.showError(
                      context,
                      ErrorMapper.getUserFriendlyError(e),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: const Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Future<void> _handleImportIntent(
  BuildContext context,
  WidgetRef ref,
  ValueNotifier<bool> isImporting,
  String path,
) async {
  isImporting.value = true;
  try {
    // Small delay for UI stability
    await Future.delayed(const Duration(milliseconds: 300));

    if (!path.toLowerCase().endsWith('.blindkey')) {
      isImporting.value = false;
      if (context.mounted) {
        CustomSnackbar.showError(
          context,
          'Invalid file type. Only .blindkey files are supported.',
        );
      }
      return;
    }

    if (context.mounted) {
      isImporting.value = false;
      _showImportPasswordDialog(context, ref, path);
    }
  } catch (e) {
    isImporting.value = false;
    debugPrint("Intent Import Error: $e");
  }
}

Future<void> _showImportPasswordDialog(
  BuildContext context,
  WidgetRef ref,
  String path,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => HookConsumer(
      builder: (context, ref, child) {
        final passwordController = useTextEditingController();
        final isLoading = useState(false);
        final errorText = useState<String?>(null);
        final isObscured = useState(true);

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
              child: SingleChildScrollView(
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
                      obscureText: isObscured.value,
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
                        errorMaxLines: 3,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white30,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscured.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white30,
                          ),
                          onPressed: () {
                            isObscured.value = !isObscured.value;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                isLoading.value = true;
                                errorText.value = null;

                                await Future.delayed(
                                  const Duration(milliseconds: 50),
                                );

                                try {
                                  // Show interstitial ad before importing
                                  final adService = ref.read(adServiceProvider);
                                  adService.showImportBlindKeyInterstitialAd();

                                  await ref
                                      .read(folderNotifierProvider.notifier)
                                      .importFolder(
                                        path,
                                        passwordController.text,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    CustomSnackbar.showSuccess(
                                      context,
                                      'Vault imported successfully',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    isLoading.value = false;

                                    errorText.value =
                                        ErrorMapper.getUserFriendlyError(e);

                                    // Ensure provider state is refreshed to clear any error state
                                    // This prevents "unable to load vaults" error from persisting
                                    ref.invalidate(folderNotifierProvider);
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
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
                        onPressed:
                            null, // Cannot cancel easily during import if it's atomic
                        child: Text(
                          "Importing...",
                          style: GoogleFonts.inter(color: Colors.white30),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Refresh provider state when canceling to ensure no error state persists
                          ref.invalidate(folderNotifierProvider);
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _showImportFolderDialog(
  BuildContext context,
  WidgetRef ref,
  String path,
  String defaultName,
) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => HookConsumer(
      builder: (context, ref, child) {
        final nameController = useTextEditingController(text: defaultName);
        final passwordController = useTextEditingController();
        final confirmPasswordController = useTextEditingController(); // Added
        final isLoading = useState(false);
        final errorText = useState<String?>(null);
        final isObscured = useState(true);
        final isConfirmObscured = useState(true); // Added
        final progress = useState(0.0);

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Import Folder',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new vault from this folder',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      enabled: !isLoading.value,
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
                        prefixIcon: const Icon(
                          Icons.folder_outlined,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: isObscured.value,
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
                        errorMaxLines: 3,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white30,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscured.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white30,
                          ),
                          onPressed: () {
                            isObscured.value = !isObscured.value;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: isConfirmObscured.value,
                      enabled: !isLoading.value,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: GoogleFonts.inter(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white30,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmObscured.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white30,
                          ),
                          onPressed: () {
                            isConfirmObscured.value = !isConfirmObscured.value;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isLoading.value) ...[
                      LinearProgressIndicator(
                        value: progress.value,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Importing... ${(progress.value * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading.value
                            ? null
                            : () async {
                                if (nameController.text.isEmpty) {
                                  errorText.value = "Please enter a vault name";
                                  return;
                                }
                                if (passwordController.text.isEmpty) {
                                  errorText.value = "Please enter a password";
                                  return;
                                }
                                if (passwordController.text !=
                                    confirmPasswordController.text) {
                                  errorText.value = "Passwords do not match";
                                  return;
                                }

                                isLoading.value = true;
                                errorText.value = null;

                                await Future.delayed(
                                  const Duration(milliseconds: 50),
                                );

                                try {
                                  final count = await ref
                                      .read(folderNotifierProvider.notifier)
                                      .importLocalFolder(
                                        folderPath: path,
                                        vaultName: nameController.text,
                                        password: passwordController.text,
                                        onProgress: (p) {
                                          progress.value = p;
                                        },
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    CustomSnackbar.showSuccess(
                                      context,
                                      'Imported $count files successfully',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    isLoading.value = false;
                                    errorText.value =
                                        ErrorMapper.getUserFriendlyError(e);
                                    ref.invalidate(folderNotifierProvider);
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : Text(
                                'Import',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    if (!isLoading.value) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(color: Colors.white54),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _ExpandableVaultFAB extends HookConsumerWidget {
  final VoidCallback onCreateVault;
  final VoidCallback onImportFolder;

  const _ExpandableVaultFAB({
    required this.onCreateVault,
    required this.onImportFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    useEffect(() {
      if (isExpanded.value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isExpanded.value]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded.value || animationController.isAnimating)
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animationController,
                curve: Curves.easeOutBack,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildFabOption(
                    context,
                    icon: Icons.drive_folder_upload_outlined, // Changed icon for import folder
                    label: "Upload Folder",
                    onPressed: () {
                      isExpanded.value = false;
                      onImportFolder();
                    },
                    delay: 0,
                  ),
                  const SizedBox(height: 16),
                  _buildFabOption(
                    context,
                    icon: Icons.create_new_folder_outlined, // Changed icon for create new vault
                    label: "Create New Vault", // Changed label to match prompt better
                    onPressed: () {
                      isExpanded.value = false;
                      onCreateVault();
                    },
                    delay: 100,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        
        FloatingActionButton(
          onPressed: () {
            isExpanded.value = !isExpanded.value;
          },
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 0.125).animate(CurvedAnimation(
              parent: animationController,
              curve: Curves.easeInOut,
            )),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required int delay,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: const Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}
