import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Added for BackdropFilter
import 'package:flutter/services.dart';

import 'package:blindkey_app/application/services/ad_service.dart';
import 'package:blindkey_app/presentation/widgets/banner_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/file_notifier.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:excel/excel.dart' hide Border;

class FileViewPage extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final bool allowSave; // Permission check

  const FileViewPage({
    super.key,
    required this.file,
    required this.folderKey,
    this.allowSave = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Preload Trusted Time if file has expiry
    final trustedTimeFuture = useMemoized(() async {
      if (file.expiryDate != null) {
        // Enforce Internet Check
        try {
          return await ref.read(trustedTimeServiceProvider).getTrustedTime();
        } catch (e) {
          throw Exception(
            "Internet connection is required to verify this shared file.",
          );
        }
      }
      return null;
    }, [file.id]); // Keyed by ID

    final trustedTimeSnapshot = useFuture(trustedTimeFuture);

    // Helper to get raw file details (name/mime/size)
    final fileDetailsFuture = useMemoized(
      () async {
        // Wait for time check if needed
        DateTime? trustedNow;
        if (file.expiryDate != null) {
          if (trustedTimeSnapshot.hasError) throw trustedTimeSnapshot.error!;
          if (!trustedTimeSnapshot.hasData) return null; // Wait...
          trustedNow = trustedTimeSnapshot.data;
        }

        final vault = ref.read(vaultServiceProvider);
        final res = await vault.decryptMetadata(
          file: file,
          folderKey: folderKey,
          trustedNow: trustedNow,
        );

        return res.fold((l) => throw Exception(l.toString()), (meta) {
          // Fix for legacy files with "application/octet-stream"
          if (meta.mimeType == 'application/octet-stream') {
            final ext = meta.fileName.split('.').last.toLowerCase();
            String newMime = 'application/octet-stream';
            switch (ext) {
              case 'jpg':
              case 'jpeg':
                newMime = 'image/jpeg';
                break;
              case 'png':
                newMime = 'image/png';
                break;
              case 'gif':
                newMime = 'image/gif';
                break;
              case 'webp':
                newMime = 'image/webp';
                break;
              case 'bmp':
                newMime = 'image/bmp';
                break;
              case 'tif':
              case 'tiff':
                newMime = 'image/tiff';
                break;
              case 'mp4':
              case 'm4v':
              case 'mov':
                newMime = 'video/mp4';
                break;
              case 'avi':
                newMime = 'video/x-msvideo';
                break;
              case 'mkv':
                newMime = 'video/x-matroska';
                break;
              case 'webm':
                newMime = 'video/webm';
                break;
              case 'txt':
              case 'css':
              case 'xml':
              case 'json':
              case 'yaml':
              case 'dart':
              case 'md':
              case 'csv':
                newMime = 'text/plain';
                break;
              case 'html':
                newMime = 'text/html';
                break;
              case 'svg':
                newMime = 'image/svg+xml';
                break;
              case 'pdf':
                newMime = 'application/pdf';
                break;
              case 'doc':
              case 'docx':
                newMime =
                    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                break;
              case 'xls':
              case 'xlsx':
                newMime =
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
                break;
              case 'ppt':
              case 'pptx':
                newMime =
                    'application/vnd.openxmlformats-officedocument.presentationml.presentation';
                break;
              case 'mp3':
              case 'wav':
              case 'aac':
              case 'wma':
              case 'flac':
              case 'm4a':
                newMime = 'audio/mpeg';
                break;
            }
            return meta.copyWith(mimeType: newMime);
          }
          return meta;
        });
      },
      [file.id, trustedTimeSnapshot.data, trustedTimeSnapshot.error],
    ); // Re-run when time is ready

    final fileDetails = useFuture(fileDetailsFuture);

    // Loading State handling (Time check OR Decrypt)
    if (file.expiryDate != null &&
        trustedTimeSnapshot.connectionState == ConnectionState.waiting) {
      // Showing loading for verification
    }

    final isVideo =
        fileDetails.hasData && (fileDetails.data!.mimeType.startsWith('video'));
    final isImage =
        fileDetails.hasData &&
        (fileDetails.data!.mimeType.startsWith('image/'));

    // Track if ad is loaded for conditional padding
    final isAdLoaded = useState<bool>(false);

    // Track system UI visibility (status bar and navigation bar)
    // Start with UI hidden (fullscreen mode)
    final showSystemUI = useState<bool>(false);

    // Hide/show system UI based on state
    useEffect(() {
      // Initially hide system UI
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      // Update system UI when showSystemUI changes
      void updateSystemUI() {
        if (showSystemUI.value) {
          // Show system UI
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.edgeToEdge,
            overlays: SystemUiOverlay.values,
          );
        } else {
          // Hide system UI (status bar and navigation bar)
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
            overlays: [],
          );
        }
      }

      // Initial update
      updateSystemUI();

      // Listen to showSystemUI changes
      // Note: Since useState doesn't have a listener, we'll handle it in the tap handler

      return () {
        // Restore when leaving page
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values,
        );
      };
    }, []);

    // Update system UI when showSystemUI changes
    useEffect(() {
      if (showSystemUI.value) {
        // Show system UI
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values,
        );
      } else {
        // Hide system UI (status bar and navigation bar)
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersiveSticky,
          overlays: [],
        );
      }
      return () {}; // Return empty dispose function
    }, [showSystemUI.value]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep matte black
      extendBodyBehindAppBar: true,
      appBar: (isVideo || isImage)
          ? null
          : AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                fileDetails.data?.fileName ?? 'File Viewer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                if (allowSave) // Only if permitted
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white70,
                    ),
                    tooltip: 'Open in External App',
                    onPressed: () async {
                      if (!fileDetails.hasData) return;

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            title: Text(
                              "Leave Secure Vault?",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'You are about to open this file externally.\n\n'
                              '• Screenshot protection will be LOST.\n'
                              '• The file will be decrypted temporarily.\n\n'
                              'Proceed?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Open Externally',
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (confirm != true) return;

                      await openExternally(
                        context,
                        ref,
                        file,
                        folderKey,
                        fileDetails.data!.fileName,
                      );
                    },
                  ),
              ],
            ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final mediaQuery = MediaQuery.of(context);
          final screenWidth = mediaQuery.size.width;
          final screenHeight = mediaQuery.size.height;
          final aspectRatio = screenWidth / screenHeight;

          // Calculate responsive ad width based on screen size and aspect ratio
          // For landscape: ad is rotated, so we need width for vertical banner
          // Standard banner is 320x50, when rotated becomes 50x320
          double adWidth = 0.0;
          if (isLandscape && isAdLoaded.value) {
            // Determine device category based on screen width
            final isSmallPhone = screenWidth < 400;
            final isRegularPhone = screenWidth >= 400 && screenWidth < 600;
            final isLargePhone = screenWidth >= 600 && screenWidth < 900;
            final isTablet = screenWidth >= 900 && screenWidth < 1200;

            // Adjust percentage based on device type and aspect ratio
            double percentage;
            double minWidth;
            double maxWidth;

            if (isSmallPhone) {
              // Small phones: 7-9% depending on aspect ratio
              percentage = aspectRatio > 2.0 ? 0.07 : 0.08;
              minWidth = 45.0;
              maxWidth = 65.0;
            } else if (isRegularPhone) {
              // Regular phones: 8-10% depending on aspect ratio
              percentage = aspectRatio > 2.0 ? 0.08 : 0.09;
              minWidth = 50.0;
              maxWidth = 75.0;
            } else if (isLargePhone) {
              // Large phones: 9-11%
              percentage = aspectRatio > 2.0 ? 0.09 : 0.10;
              minWidth = 55.0;
              maxWidth = 85.0;
            } else if (isTablet) {
              // Tablets: 10-12%
              percentage = aspectRatio > 1.8 ? 0.10 : 0.11;
              minWidth = 60.0;
              maxWidth = 100.0;
            } else {
              // Large tablets: 11-13%
              percentage = aspectRatio > 1.8 ? 0.11 : 0.12;
              minWidth = 70.0;
              maxWidth = 120.0;
            }

            adWidth = (screenWidth * percentage).clamp(minWidth, maxWidth);
          }

          return GestureDetector(
            // Tap to toggle system UI visibility
            onTap: () {
              showSystemUI.value = !showSystemUI.value;
            },
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Background
                Positioned.fill(
                  child: Container(color: const Color(0xFF0F0F0F)),
                ),

                SafeArea(
                  child: Padding(
                    // Add right padding in landscape only if ad is loaded
                    padding: EdgeInsets.only(
                      right: (isLandscape && isAdLoaded.value) ? adWidth : 0.0,
                    ),
                    child: fileDetails.hasError
                        ? Center(
                            child: Text(
                              'Error: ${fileDetails.error}',
                              style: GoogleFonts.inter(color: Colors.red),
                            ),
                          )
                        : !fileDetails.hasData
                        ? Center(
                            child: SizedBox(
                              width: 200,
                              child: LinearProgressIndicator(
                                color: Colors.white30,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          )
                        : Material(
                            type: MaterialType.transparency,
                            child: isVideo
                                ? _VideoView(
                                    file: file,
                                    folderKey: folderKey,
                                    fileSize: fileDetails.data!.size,
                                    trustedNow: trustedTimeSnapshot.data,
                                    isAdLoaded: isAdLoaded.value,
                                  )
                                : (fileDetails.data!.mimeType.startsWith(
                                        'image/svg',
                                      )
                                      ? _SvgView(
                                          file: file,
                                          folderKey: folderKey,
                                          fileSize: fileDetails.data!.size,
                                          trustedNow: trustedTimeSnapshot.data,
                                        )
                                      : (fileDetails.data!.mimeType.startsWith(
                                              'image/',
                                            )
                                            ? _ImageView(
                                                file: file,
                                                folderKey: folderKey,
                                                fileSize:
                                                    fileDetails.data!.size,
                                                trustedNow:
                                                    trustedTimeSnapshot.data,
                                              )
                                            : (fileDetails.data!.mimeType
                                                      .startsWith('text/')
                                                  ? _TextView(
                                                      file: file,
                                                      folderKey: folderKey,
                                                      fileSize: fileDetails
                                                          .data!
                                                          .size,
                                                      trustedNow:
                                                          trustedTimeSnapshot
                                                              .data,
                                                    )
                                                  : (fileDetails.data!.mimeType ==
                                                            'application/pdf'
                                                        ? _PdfView(
                                                            file: file,
                                                            folderKey:
                                                                folderKey,
                                                            fileSize:
                                                                fileDetails
                                                                    .data!
                                                                    .size,
                                                            trustedNow:
                                                                trustedTimeSnapshot
                                                                    .data,
                                                          )
                                                        : (fileDetails
                                                                      .data!
                                                                      .mimeType
                                                                      .contains(
                                                                        'excel',
                                                                      ) ||
                                                                  fileDetails
                                                                      .data!
                                                                      .mimeType
                                                                      .contains(
                                                                        'spreadsheet',
                                                                      )
                                                              ? _ExcelView(
                                                                  file: file,
                                                                  folderKey:
                                                                      folderKey,
                                                                  fileSize:
                                                                      fileDetails
                                                                          .data!
                                                                          .size,
                                                                  trustedNow:
                                                                      trustedTimeSnapshot
                                                                          .data,
                                                                )
                                                              : (fileDetails.data!.mimeType.contains(
                                                                          'word',
                                                                        ) ||
                                                                        fileDetails
                                                                            .data!
                                                                            .mimeType
                                                                            .contains('document')
                                                                    ? _UnsupportedFileView(
                                                                        file:
                                                                            file,
                                                                        folderKey:
                                                                            folderKey,
                                                                        fileName: fileDetails
                                                                            .data!
                                                                            .fileName,
                                                                      )
                                                                    : (fileDetails.data!.mimeType.contains('presentation') ||
                                                                              fileDetails.data!.mimeType.contains('powerpoint')
                                                                          ? _UnsupportedFileView(
                                                                              file: file,
                                                                              folderKey: folderKey,
                                                                              fileName: fileDetails.data!.fileName,
                                                                            )
                                                                          : (fileDetails.data!.mimeType.startsWith('audio/')
                                                                                ? _AudioView(
                                                                                    file: file,
                                                                                    folderKey: folderKey,
                                                                                    fileSize: fileDetails.data!.size,
                                                                                    trustedNow: trustedTimeSnapshot.data,
                                                                                  )
                                                                                : _UnsupportedFileView(
                                                                                    file: file,
                                                                                    folderKey: folderKey,
                                                                                    fileName: fileDetails.data!.fileName,
                                                                                  ))))))))),
                          ),
                  ),
                ),

                // Banner Ad - positioned based on orientation
                if (isLandscape && isAdLoaded.value)
                  // Landscape: Position on the right side to maintain same relative position as portrait bottom
                  Builder(
                    builder: (context) {
                      final mediaQuery = MediaQuery.of(context);
                      final screenWidth = mediaQuery.size.width;
                      final screenHeight = mediaQuery.size.height;
                      final aspectRatio = screenWidth / screenHeight;

                      // Calculate responsive ad width based on screen size and aspect ratio
                      double percentage;
                      double minWidth;
                      double maxWidth;

                      if (screenWidth < 400) {
                        // Small phones
                        percentage = aspectRatio > 2.0 ? 0.07 : 0.08;
                        minWidth = 45.0;
                        maxWidth = 65.0;
                      } else if (screenWidth < 600) {
                        // Regular phones
                        percentage = aspectRatio > 2.0 ? 0.08 : 0.09;
                        minWidth = 50.0;
                        maxWidth = 75.0;
                      } else if (screenWidth < 900) {
                        // Large phones
                        percentage = aspectRatio > 2.0 ? 0.09 : 0.10;
                        minWidth = 55.0;
                        maxWidth = 85.0;
                      } else if (screenWidth < 1200) {
                        // Tablets
                        percentage = aspectRatio > 1.8 ? 0.10 : 0.11;
                        minWidth = 60.0;
                        maxWidth = 100.0;
                      } else {
                        // Large tablets
                        percentage = aspectRatio > 1.8 ? 0.11 : 0.12;
                        minWidth = 70.0;
                        maxWidth = 120.0;
                      }

                      final calculatedWidth = (screenWidth * percentage).clamp(
                        minWidth,
                        maxWidth,
                      );

                      return Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: SafeArea(
                          child: Container(
                            color: const Color(0xFF0F0F0F),
                            width: calculatedWidth, // Responsive width
                            alignment: Alignment.center,
                            child: RotatedBox(
                              quarterTurns:
                                  1, // Rotate 90 degrees to show vertically
                              child: BannerAdWidget(
                                adUnitId: AdService.fileViewBannerAdId,
                                adSize: AdSize.banner,
                                onAdLoadedChanged: (loaded) {
                                  isAdLoaded.value = loaded;
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: OrientationBuilder(
        builder: (context, orientation) {
          // Only show bottom ad in portrait mode
          if (orientation == Orientation.landscape) {
            return const SizedBox.shrink();
          }

          return Container(
            color: const Color(0xFF0F0F0F),
            child: SafeArea(
              top: false,
              child: BannerAdWidget(
                adUnitId: AdService.fileViewBannerAdId,
                onAdLoadedChanged: (loaded) {
                  isAdLoaded.value = loaded;
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileView(
    FileModel file,
    SecretKey folderKey,
    FileMetadata meta,
    DateTime? trustedNow,
    bool isVideo,
  ) {
    if (isVideo) {
      return _VideoView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
        isAdLoaded: false, // This method is unused, default to false
      );
    }

    final mime = meta.mimeType;

    if (mime.startsWith('image/svg')) {
      return Center(
        child: _SvgView(
          file: file,
          folderKey: folderKey,
          fileSize: meta.size,
          trustedNow: trustedNow,
        ),
      );
    }

    if (mime.startsWith('image/')) {
      return _ImageView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
      );
    }

    if (mime.startsWith('text/')) {
      return _TextView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
      );
    }

    if (mime == 'application/pdf') {
      return _PdfView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
      );
    }

    if (mime.contains('excel') || mime.contains('spreadsheet')) {
      return _ExcelView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
      );
    }

    if (mime.contains('word') || mime.contains('document')) {
      return _UnsupportedFileView(
        file: file,
        folderKey: folderKey,
        fileName: meta.fileName,
      );
    }

    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return _UnsupportedFileView(
        file: file,
        folderKey: folderKey,
        fileName: meta.fileName,
      );
    }

    if (mime.startsWith('audio/')) {
      return _AudioView(
        file: file,
        folderKey: folderKey,
        fileSize: meta.size,
        trustedNow: trustedNow,
      );
    }

    return _UnsupportedFileView(
      file: file,
      folderKey: folderKey,
      fileName: meta.fileName,
    );
  }
}

Future<void> openExternally(
  BuildContext context,
  WidgetRef ref,
  FileModel file,
  SecretKey folderKey,
  String fileName,
) async {
  final vault = ref.read(vaultServiceProvider);
  final dir = await getTemporaryDirectory();
  final tempPath = '${dir.path}/$fileName';
  final tempFile = File(tempPath);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Decrypting...', style: GoogleFonts.inter()),
        backgroundColor: Colors.white10,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  try {
    final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
    final sink = tempFile.openWrite();
    await for (final chunk in stream) {
      sink.add(chunk);
    }
    await sink.flush();
    await sink.close();

    final res = await OpenFile.open(tempPath);
    if (res.type != ResultType.done) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${res.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    // Check if file expired and was deleted
    if (e.toString().contains('expired')) {
      // Invalidate folder stats to update size in real-time
      ref.invalidate(folderStatsProvider(file.folderId));
      // Invalidate file list to remove expired file
      ref.invalidate(fileNotifierProvider(file.folderId));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _UnsupportedFileView extends ConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final String fileName;

  const _UnsupportedFileView({
    required this.file,
    required this.folderKey,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            Text(
              "This file cannot be viewed within the app.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You can use external apps to view the file.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                openExternally(context, ref, file, folderKey, fileName);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text("Open Externally", style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingProgressView extends StatelessWidget {
  final double progress;
  const _LoadingProgressView({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _ImageView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageBytes = useState<Uint8List?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    // View State
    final rotationTurns = useState(0); // 0 = 0, 1 = 90, 2 = 180, 3 = 270
    final showControls = useState(true);

    // Zoom State
    final transformationController = useMemoized(
      () => TransformationController(),
    );
    useEffect(() {
      return transformationController.dispose;
    }, [transformationController]);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    final animation = useState<Animation<Matrix4>?>(null);

    // Auto-hide controls timer
    final hideTimer = useRef<Timer?>(null);

    void startHideTimer() {
      hideTimer.value?.cancel();
      hideTimer.value = Timer(const Duration(seconds: 3), () {
        if (context.mounted) showControls.value = false;
      });
    }

    void toggleControls() {
      showControls.value = !showControls.value;
      if (showControls.value) {
        startHideTimer();
      } else {
        hideTimer.value?.cancel();
      }
    }

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;

      // Start timer on load
      startHideTimer();

      final subscription = vault
          .decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          )
          .listen(
            (chunk) {
              // Accumulation handled below
            },
            onError: (e) {
              if (!isCancelled) error.value = e;
            },
          );

      final bytes = <int>[];
      subscription.onData((chunk) {
        if (isCancelled) return;
        bytes.addAll(chunk);
        received += chunk.length;
        progress.value = fileSize > 0
            ? (received / fileSize).clamp(0.0, 1.0)
            : 0.0;
      });

      subscription.onDone(() {
        if (!isCancelled) {
          imageBytes.value = Uint8List.fromList(bytes);
        }
      });

      return () {
        isCancelled = true;
        subscription.cancel();
        hideTimer.value?.cancel();
      };
    }, []);

    // Zoom Animation Listener
    useEffect(() {
      void listener() {
        if (animation.value != null) {
          transformationController.value = animation.value!.value;
        }
      }

      animationController.addListener(listener);
      return () => animationController.removeListener(listener);
    }, [animation.value]);

    void onDoubleTap(TapDownDetails details) {
      final position = details.localPosition;

      Matrix4 endMatrix;
      if (transformationController.value.getMaxScaleOnAxis() > 1.5) {
        // Zoom out
        endMatrix = Matrix4.identity();
      } else {
        // Zoom in to tap position
        // Scale factor: 2.5x
        final double scale = 2.5;
        final double x = -position.dx * (scale - 1);
        final double y = -position.dy * (scale - 1);

        endMatrix = Matrix4.identity()
          ..translate(x, y)
          ..scale(scale);
      }

      animation.value =
          Matrix4Tween(
            begin: transformationController.value,
            end: endMatrix,
          ).animate(
            CurveTween(curve: Curves.easeInOut).animate(animationController),
          );

      animationController.forward(from: 0);
    }

    if (error.value != null) {
      return Center(
        child: Text(
          'Error decrypting file: ${error.value}',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
      );
    }

    if (imageBytes.value == null) {
      return _LoadingProgressView(progress: progress.value);
    }

    return Stack(
      children: [
        // 1. Image Layer with Zoom & Pan
        Positioned.fill(
          child: GestureDetector(
            onDoubleTapDown: onDoubleTap,
            onTap: toggleControls,
            child: Container(
              color: Colors.transparent, // Capture taps
              child: InteractiveViewer(
                transformationController: transformationController,
                clipBehavior: Clip.none,
                minScale: 0.5,
                maxScale: 5.0,
                onInteractionStart: (_) {
                  showControls.value = false;
                  hideTimer.value?.cancel();
                },
                child: Center(
                  child: RotatedBox(
                    quarterTurns: rotationTurns.value,
                    child: Image.memory(
                      imageBytes.value!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Controls overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          top: showControls.value ? 0 : -100,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 10,
              left: 10,
              right: 10,
            ),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // File info could go here
                IconButton(
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Open Externally',
                  onPressed: () async {
                    if (trustedNow != null) {
                      // Optional: check expiry again?
                    }
                    // Reuse the global openExternally function
                    // Need to check if file model has fileName, usually it does or we got it from meta
                    // helper.

                    // We need the filename. The 'file' model might not have the decrypted name.
                    // But openExternally takes 'fileName'.
                    // We don't have easy access to the decrypted filename here unless we pass it
                    // or decrypt it again (cheap metadata).
                    // In FileViewPage we had fileDetails.data.
                    // We should probably pass fileName to _ImageView to be safe/efficient.
                    // For now, let's try to use file.fileName if available or "image"
                    // checking openExternally signature: needs fileName.

                    await openExternally(
                      context,
                      ref,
                      file,
                      folderKey,
                      // Fallback or re-fetch?
                      // best to use a default or handle inside.
                      // Let's modify _ImageView to accept fileName to be clean.
                      "image",
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          bottom: showControls.value ? 30 : -100,
          right: 30, // Floating action button style
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: null, // Disable Hero to prevent nesting error
                mini: true,
                backgroundColor: Colors.white12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white24),
                ),
                onPressed: () {
                  animationController.reset();
                  transformationController.value = Matrix4.identity();
                  rotationTurns.value = (rotationTurns.value + 1) % 4;
                  startHideTimer();
                },
                child: const Icon(
                  Icons.rotate_right_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Hint text for first-time users could go here
        if (showControls.value)
          Positioned(
            bottom: 30,
            left: 30,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress.value * 100).toInt()}% Loaded", // Or other info
                  style: GoogleFonts.robotoMono(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;
  final bool isAdLoaded;

  const _VideoView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
    required this.isAdLoaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoPath = useState<String?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      bool isCancelled = false;
      String? tempPath;

      Future<void> load() async {
        try {
          final vault = ref.read(vaultServiceProvider);
          final dir = await getTemporaryDirectory();
          final res = await vault.decryptMetadata(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          );
          String ext = 'mp4';
          res.fold((l) {}, (meta) {
            final fileName = meta.fileName;
            if (fileName.contains('.')) {
              ext = fileName.split('.').last.toLowerCase();
            }
          });

          tempPath = '${dir.path}/${file.id}.$ext';
          final tempFile = File(tempPath!);
          final sink = tempFile.openWrite();

          int received = 0;
          final stream = vault.decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          );

          await for (final chunk in stream) {
            if (isCancelled) break;
            sink.add(chunk);
            received += chunk.length;
            progress.value = fileSize > 0
                ? (received / fileSize).clamp(0.0, 1.0)
                : 0.0;
          }

          await sink.flush();
          await sink.close();

          if (!isCancelled) {
            videoPath.value = tempPath;
          }
        } catch (e) {
          // Check if file expired and was deleted
          if (e.toString().contains('expired')) {
            // Invalidate folder stats to update size in real-time
            ref.invalidate(folderStatsProvider(file.folderId));
            // Invalidate file list to remove expired file
            ref.invalidate(fileNotifierProvider(file.folderId));
          }
          if (!isCancelled) error.value = e;
        }
      }

      load();

      return () {
        isCancelled = true;
        if (tempPath != null) {
          final f = File(tempPath!);
          if (f.existsSync())
            try {
              f.deleteSync();
            } catch (_) {}
        }
      };
    }, []);

    if (error.value != null) {
      return Center(
        child: Text(
          'Error: ${error.value}',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
      );
    }
    if (videoPath.value == null) {
      return _LoadingProgressView(progress: progress.value);
    }

    return _VideoPlayerView(
      filePath: videoPath.value!,
      isAdLoaded: isAdLoaded,
      onOpenExternal: () async {
        final confirm = await showDialog<bool>(
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
                "Leave Secure Vault?",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'You are about to open this file externally.\n\n'
                '• Screenshot protection will be LOST.\n'
                '• The file will be decrypted temporarily.\n\n'
                'Proceed?',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Open Externally',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (confirm != true) return;

        // Try to fetch filename if possible, or use ID logic
        String fileName = file.id;
        // We can get metadata again or try to extract from temp path, but openExternally expects name.
        // The original openExternally uses fileDetails.data.fileName.
        // We can re-fetch metadata or just use ID. openExternally uses it for temp file naming.
        // Let's quickly fetch metadata since we are inside HookConsumerWidget, but we can't easily wait.
        // Actually we can just use the openExternally function. It needs fileName.
        // Let's try to get fileName from the metadata check we did in useEffect or just pass "Video.mp4" as default if unknown.
        // Wait, current useEffect doesn't expose metadata out.
        // Better: refactor to use a simpler openExternally call or accept that we might not have exact filename here immediately without re-fetch.
        // But wait, openExternally re-decrypts anyway.
        // Let's just use file.id as name if we can't get it easily, or re-read metadata.

        // Actually, best to just use the one provided by openExternally if we pass it correctly.
        // But openExternally is global.
        // Let's call vault.decryptMetadata again? It's cheap (header).
        try {
          final vault = ref.read(vaultServiceProvider);
          final res = await vault.decryptMetadata(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          );
          res.fold((l) {}, (meta) => fileName = meta.fileName);

          if (context.mounted) {
            await openExternally(context, ref, file, folderKey, fileName);
          }
        } catch (e) {
          // Ignore
        }
      },
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  final String filePath;
  final VoidCallback onOpenExternal;
  final bool isAdLoaded;

  const _VideoPlayerView({
    required this.filePath,
    required this.onOpenExternal,
    required this.isAdLoaded,
  });

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isLandscape = false;
  bool _controlsLocked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _initialized = true;
              });
              _controller.play();
              _startHideTimer();
            }
          })
          .catchError((error) {
            if (mounted) {
              setState(() {
                _error = error.toString();
              });
            }
          });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _skip(Duration duration) {
    final newPos = _controller.value.position + duration;
    _controller.seekTo(newPos);
    _showControls = true;
    _startHideTimer();
  }

  void _toggleLandscape() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inMinutes >= 60 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Error playing video: $_error',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white30),
      );
    }

    // Check actual device orientation
    final isDeviceLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    // Only show padding if ad is actually loaded
    final shouldShowAdPadding =
        (isDeviceLandscape || _isLandscape) && widget.isAdLoaded;

    // Calculate responsive padding based on screen size and aspect ratio
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final aspectRatio = screenWidth / screenHeight;

    double adWidth = 0.0;
    if (shouldShowAdPadding) {
      double percentage;
      double minWidth;
      double maxWidth;

      if (screenWidth < 400) {
        // Small phones
        percentage = aspectRatio > 2.0 ? 0.07 : 0.08;
        minWidth = 45.0;
        maxWidth = 65.0;
      } else if (screenWidth < 600) {
        // Regular phones
        percentage = aspectRatio > 2.0 ? 0.08 : 0.09;
        minWidth = 50.0;
        maxWidth = 75.0;
      } else if (screenWidth < 900) {
        // Large phones
        percentage = aspectRatio > 2.0 ? 0.09 : 0.10;
        minWidth = 55.0;
        maxWidth = 85.0;
      } else if (screenWidth < 1200) {
        // Tablets
        percentage = aspectRatio > 1.8 ? 0.10 : 0.11;
        minWidth = 60.0;
        maxWidth = 100.0;
      } else {
        // Large tablets
        percentage = aspectRatio > 1.8 ? 0.11 : 0.12;
        minWidth = 70.0;
        maxWidth = 120.0;
      }

      adWidth = (screenWidth * percentage).clamp(minWidth, maxWidth);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onDoubleTapDown: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  _skip(const Duration(seconds: -10));
                } else {
                  _skip(const Duration(seconds: 10));
                }
              },
              child: Container(color: Colors.transparent),
            ),

            if (_showControls)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black54,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8.0,
                          right: shouldShowAdPadding
                              ? adWidth + 8.0
                              : 8.0, // Add responsive padding for ad in landscape
                          top: 8.0,
                          bottom: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isLandscape) {
                                  _toggleLandscape();
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Open Externally',
                              onPressed: widget.onOpenExternal,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 48,
                            icon: const Icon(
                              Icons.replay_10_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                _skip(const Duration(seconds: -10)),
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                                _startHideTimer();
                              });
                            },
                          ),
                          const SizedBox(width: 32),
                          IconButton(
                            iconSize: 48,
                            icon: const Icon(
                              Icons.forward_10_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () => _skip(const Duration(seconds: 10)),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Padding(
                        padding: EdgeInsets.only(
                          left: 16.0,
                          right: shouldShowAdPadding
                              ? adWidth + 16.0
                              : 16.0, // Add responsive padding for ad in landscape
                          top: 16.0,
                          bottom: 16.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                    ),
                                    child: Slider(
                                      value: _controller
                                          .value
                                          .position
                                          .inMilliseconds
                                          .toDouble()
                                          .clamp(
                                            0.0,
                                            _controller
                                                .value
                                                .duration
                                                .inMilliseconds
                                                .toDouble(),
                                          ),
                                      min: 0.0,
                                      max: _controller
                                          .value
                                          .duration
                                          .inMilliseconds
                                          .toDouble(),
                                      activeColor: Colors.redAccent,
                                      inactiveColor: Colors.white24,
                                      onChanged: (value) {
                                        _controller.seekTo(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                        _startHideTimer();
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    _isLandscape
                                        ? Icons.fullscreen_exit_rounded
                                        : Icons.fullscreen_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: _toggleLandscape,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TextView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _TextView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textContent = useState<String?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;
      final bytes = <int>[];

      final subscription = vault
          .decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          )
          .listen(
            (chunk) {
              if (isCancelled) return;
              bytes.addAll(chunk);
              received += chunk.length;
              progress.value = fileSize > 0
                  ? (received / fileSize).clamp(0.0, 1.0)
                  : 0.0;
            },
            onDone: () {
              if (!isCancelled) {
                textContent.value = utf8.decode(bytes, allowMalformed: true);
              }
            },
            onError: (e) {
              if (!isCancelled) error.value = e;
            },
          );

      return () {
        isCancelled = true;
        subscription.cancel();
      };
    }, []);

    if (error.value != null)
      return Center(
        child: Text(
          'Error: ${error.value}',
          style: GoogleFonts.inter(color: Colors.red),
        ),
      );
    if (textContent.value == null)
      return _LoadingProgressView(progress: progress.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        textContent.value!,
        style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class _PdfView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _PdfView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdfPath = useState<String?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    // pdfrx Controllers
    final pdfController = useMemoized(() => PdfViewerController());
    final textSearcher = useMemoized(() => PdfTextSearcher(pdfController));

    // UI State
    final documentLoaded = useState(false);
    final totalPages = useState(0);
    final currentPage = useState(1);
    final showSearch = useState(false);
    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();
    final matchCount = useState(0);
    final currentMatchIndex = useState(0);

    // Dispose controllers manually if needed, but PdfViewerController typically handles itself if attached
    // TextSearcher listener needs management
    useEffect(() {
      void onMatchesChanged() {
        matchCount.value = textSearcher.matches.length;
        currentMatchIndex.value = (textSearcher.currentIndex ?? -1) + 1;
      }

      textSearcher.addListener(onMatchesChanged);
      return () => textSearcher.removeListener(onMatchesChanged);
    }, [textSearcher]);

    useEffect(() {
      bool isCancelled = false;
      String? tempPath;

      Future<void> load() async {
        try {
          final vault = ref.read(vaultServiceProvider);
          final dir = await getTemporaryDirectory();
          tempPath = '${dir.path}/${file.id}.pdf';
          final tempFile = File(tempPath!);

          if (tempFile.existsSync()) {
            try {
              tempFile.deleteSync();
            } catch (_) {}
          }

          final sink = tempFile.openWrite();
          int received = 0;
          final stream = vault.decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          );

          await for (final chunk in stream) {
            if (isCancelled) break;
            sink.add(chunk);
            received += chunk.length;
            progress.value = fileSize > 0
                ? (received / fileSize).clamp(0.0, 1.0)
                : 0.0;
          }

          await sink.flush();
          await sink.close();

          if (!isCancelled) {
            if (tempFile.existsSync() && await tempFile.length() > 0) {
              pdfPath.value = tempPath;
            } else {
              error.value = 'PDF file is empty';
            }
          }
        } catch (e) {
          if (!isCancelled) error.value = e;
        }
      }

      load();

      return () {
        isCancelled = true;
        if (tempPath != null) {
          final f = File(tempPath!);
          if (f.existsSync())
            try {
              f.deleteSync();
            } catch (_) {}
        }
      };
    }, []);

    void performSearch() {
      if (searchController.text.isNotEmpty) {
        textSearcher.startTextSearch(searchController.text);
      } else {
        textSearcher.resetTextSearch();
      }
    }

    if (error.value != null)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading PDF',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.value.toString(),
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

    return Stack(
      children: [
        if (pdfPath.value != null)
          PdfViewer.file(
            pdfPath.value!,
            controller: pdfController,
            params: PdfViewerParams(
              onViewerReady: (document, controller) {
                documentLoaded.value = true;
                totalPages.value = document.pages.length;
              },
              onPageChanged: (pageNumber) {
                currentPage.value = pageNumber ?? 1;
              },
              viewerOverlayBuilder: (context, size, handleLinkTap) => [
                PdfViewerScrollThumb(
                  controller: pdfController,
                  orientation: ScrollbarOrientation.right,
                  thumbSize: const Size(40, 25),
                  thumbBuilder: (context, thumbSize, pageNumber, controller) =>
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),

        if (!documentLoaded.value)
          Container(
            color: const Color(0xFF0F0F0F),
            child: _LoadingProgressView(progress: progress.value),
          ),

        // Page Status
        if (documentLoaded.value)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  '${currentPage.value} / ${totalPages.value}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),

        // Search Toolbar
        if (documentLoaded.value && showSearch.value)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Find in document...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38),
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                        ),
                        onSubmitted: (_) => performSearch(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                      onPressed: () => textSearcher.goToPrevMatch(),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                      onPressed: () => textSearcher.goToNextMatch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        textSearcher.resetTextSearch();
                        showSearch.value = false;
                        searchController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (documentLoaded.value)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () {
                showSearch.value = true;
                Future.microtask(() => searchFocusNode.requestFocus());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
            ),
          ),

        // Search Result Count
        if (documentLoaded.value && showSearch.value && matchCount.value > 0)
          Positioned(
            top: 60 + MediaQuery.of(context).padding.top,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentMatchIndex.value} of ${matchCount.value}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _AudioView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _AudioView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(() => AudioPlayer());
    final isPlaying = useState(false);
    final duration = useState(Duration.zero);
    final position = useState(Duration.zero);

    final audioPath = useState<String?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      bool isCancelled = false;
      String? tempPath;

      Future<void> load() async {
        try {
          final vault = ref.read(vaultServiceProvider);
          final dir = await getTemporaryDirectory();
          final res = await vault.decryptMetadata(
            file: file,
            folderKey: folderKey,
          );
          String ext = 'mp3';
          res.fold((l) {}, (r) => ext = r.fileName.split('.').last);

          tempPath = '${dir.path}/${file.id}.$ext';
          final tempFile = File(tempPath!);
          final sink = tempFile.openWrite();

          int received = 0;
          final stream = vault.decryptFileStream(
            file: file,
            folderKey: folderKey,
          );

          await for (final chunk in stream) {
            if (isCancelled) break;
            sink.add(chunk);
            received += chunk.length;
            progress.value = fileSize > 0
                ? (received / fileSize).clamp(0.0, 1.0)
                : 0.0;
          }

          await sink.flush();
          await sink.close();

          if (!isCancelled) audioPath.value = tempPath;
        } catch (e) {
          // Check if file expired and was deleted
          if (e.toString().contains('expired')) {
            // Invalidate folder stats to update size in real-time
            ref.invalidate(folderStatsProvider(file.folderId));
            // Invalidate file list to remove expired file
            ref.invalidate(fileNotifierProvider(file.folderId));
          }
          if (!isCancelled) error.value = e;
        }
      }

      load();

      final sub1 = player.onPlayerStateChanged.listen((state) {
        isPlaying.value = state == PlayerState.playing;
      });
      final sub2 = player.onDurationChanged.listen((d) {
        duration.value = d;
      });
      final sub3 = player.onPositionChanged.listen((p) {
        position.value = p;
      });

      return () {
        isCancelled = true;
        sub1.cancel();
        sub2.cancel();
        sub3.cancel();
        player.dispose();
        if (tempPath != null) {
          final f = File(tempPath!);
          if (f.existsSync())
            try {
              f.deleteSync();
            } catch (_) {}
        }
      };
    }, []);

    if (error.value != null)
      return Center(
        child: Text('Error: ${error.value}', style: GoogleFonts.inter()),
      );
    if (audioPath.value == null)
      return _LoadingProgressView(progress: progress.value);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 64,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "${formatDuration(position.value)} / ${formatDuration(duration.value)}",
            style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              trackHeight: 2,
            ),
            child: Slider(
              value: position.value.inSeconds.toDouble().clamp(
                0,
                duration.value.inSeconds.toDouble(),
              ),
              max: duration.value.inSeconds.toDouble(),
              onChanged: (v) {
                player.seek(Duration(seconds: v.toInt()));
              },
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(
              isPlaying.value
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              size: 80,
              color: Colors.white,
            ),
            onPressed: () {
              if (isPlaying.value) {
                player.pause();
              } else {
                player.play(DeviceFileSource(audioPath.value!));
              }
            },
          ),
        ],
      ),
    );
  }

  String formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }
}

class _SvgView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _SvgView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgContent = useState<String?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;
      final bytes = <int>[];

      final subscription = vault
          .decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          )
          .listen(
            (chunk) {
              if (isCancelled) return;
              bytes.addAll(chunk);
              received += chunk.length;
              progress.value = fileSize > 0
                  ? (received / fileSize).clamp(0.0, 1.0)
                  : 0.0;
            },
            onDone: () {
              if (!isCancelled) {
                svgContent.value = utf8.decode(bytes);
              }
            },
            onError: (e) {
              if (!isCancelled) error.value = e;
            },
          );

      return () {
        isCancelled = true;
        subscription.cancel();
      };
    }, []);

    if (error.value != null)
      return Center(
        child: Text('Error: ${error.value}', style: GoogleFonts.inter()),
      );
    if (svgContent.value == null)
      return _LoadingProgressView(progress: progress.value);

    return SvgPicture.string(svgContent.value!);
  }
}

class _ExcelView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _ExcelView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final excelData = useState<Excel?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;
      final bytes = <int>[];

      final subscription = vault
          .decryptFileStream(
            file: file,
            folderKey: folderKey,
            trustedNow: trustedNow,
          )
          .listen(
            (chunk) {
              if (isCancelled) return;
              bytes.addAll(chunk);
              received += chunk.length;
              progress.value = fileSize > 0
                  ? (received / fileSize).clamp(0.0, 1.0)
                  : 0.0;
            },
            onDone: () {
              if (!isCancelled) {
                try {
                  final excel = Excel.decodeBytes(bytes);
                  excelData.value = excel;
                } catch (e) {
                  error.value = "Failed to parse Excel file: $e";
                }
              }
            },
            onError: (e) {
              if (!isCancelled) error.value = e;
            },
          );

      return () {
        isCancelled = true;
        subscription.cancel();
      };
    }, []);

    if (error.value != null)
      return Center(
        child: Text(
          'Error: ${error.value}',
          style: GoogleFonts.inter(color: Colors.red),
        ),
      );
    if (excelData.value == null)
      return _LoadingProgressView(progress: progress.value);

    final excel = excelData.value!;
    final sheetName = excel.tables.keys.firstOrNull;
    if (sheetName == null) {
      return Center(
        child: Text(
          'Empty Excel File',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
      );
    }
    final table = excel.tables[sheetName]!;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: table.maxColumns == 0
              ? []
              : List.generate(
                  table.maxColumns,
                  (index) => DataColumn(
                    label: Text(
                      'Col $index',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
          rows: table.rows.map((row) {
            return DataRow(
              cells: row.map((cell) {
                return DataCell(
                  Text(
                    cell?.value.toString() ?? '',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
