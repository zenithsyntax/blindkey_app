import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Added for BackdropFilter

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/file_notifier.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
import 'package:blindkey_app/application/services/vault_service.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:blindkey_app/presentation/pages/file_view_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cryptography/cryptography.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts
import 'package:path_provider/path_provider.dart';

class FolderViewPage extends HookConsumerWidget {
  final FolderModel folder;
  final SecretKey folderKey;

  const FolderViewPage({
    super.key,
    required this.folder,
    required this.folderKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(fileNotifierProvider(folder.id));
    final uploadProgress = ref.watch(uploadProgressProvider);

    final scrollController = useScrollController();

    // Check if folder has any expired files
    final hasExpiredFiles =
        filesAsync.valueOrNull?.any(
          (file) =>
              file.expiryDate != null &&
              DateTime.now().toUtc().isAfter(file.expiryDate!.toUtc()),
        ) ??
        false;

    // Check if folder is empty
    final isEmpty = filesAsync.valueOrNull?.isEmpty ?? true;

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
          ref.read(fileNotifierProvider(folder.id).notifier).loadMore();
        }
      });
      return null;
    }, [scrollController]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep black background
      body: Stack(
        children: [
          CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                expandedHeight: 120,
                backgroundColor: const Color(0xFF0F0F0F),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  folder.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: false,
                actions: [
                  // Hide export/share button if folder has expired files or is empty
                  if (!hasExpiredFiles && !isEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white70,
                      ),
                      tooltip: 'Share Folder',
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => _ShareDialog(
                            onExport: (expiry, allowSave) async {
                              await showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => _ExportProgressDialog(
                                  folder: folder,
                                  folderKey: folderKey,
                                  expiry: expiry,
                                  allowSave: allowSave,
                                ),
                              );
                              // Refresh files in case any were expired/deleted by export process
                              ref.invalidate(fileNotifierProvider(folder.id));
                            },
                          ),
                        );
                      },
                    ),
                  if (!hasExpiredFiles && !isEmpty) const SizedBox(width: 8),
                ],
              ),

              filesAsync.when(
                data: (files) {
                  if (files.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.05),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No encrypted files yet',
                              style: GoogleFonts.inter(
                                color: Colors.white30,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85, // Taller cards
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == files.length) {
                          // This is tricky inside a Grid. Usually, loading spinner is a separate sliver at bottom.
                          // For simplicity in Grid, we might just not show it or show a placeholder.
                          // Better approach: Use a SliverToBoxAdapter below the grid for the loader.
                          return const SizedBox.shrink();
                        }
                        final file = files[index];
                        return _FileThumbnail(
                          key: ValueKey(file.id),
                          file: file,
                          folderKey: folderKey,
                          allowSave: folder.allowSave,
                        );
                      }, childCount: files.length),
                    ),
                  );
                },
                error: (e, s) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white24),
                  ),
                ),
              ),

              // Bottom loader if loading more
              if (filesAsync.valueOrNull != null &&
                  ref.read(fileNotifierProvider(folder.id).notifier).hasMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),

              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
              ), // Bottom spacing for FAB
            ],
          ),

          // Upload Progress Overlay
          if (uploadProgress.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.9),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: uploadProgress.entries.map((e) {
                        return Row(
                          children: [
                            const Icon(
                              Icons.cloud_upload_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: e.value,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.blueAccent,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(e.value * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: uploadProgress.isNotEmpty || hasExpiredFiles
          ? null
          : FloatingActionButton.extended(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Upload',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  withReadStream: false,
                );

                if (result != null) {
                  final files = result.paths
                      .whereType<String>()
                      .map((e) => File(e))
                      .toList();
                  if (files.isEmpty) return;

                  await _handleUpload(context, ref, files);
                }
              },
            ),
    );
  }

  Future<void> _handleUpload(
    BuildContext context,
    WidgetRef ref,
    List<File> files,
  ) async {
    // 1. Check Max Files per Batch
    if (files.length > 10) {
      _showError(context, 'You can only select up to 10 files at a time.');
      return;
    }

    // 2. Check each file size (Max 100MB)
    int newBatchSize = 0;
    for (final f in files) {
      final len = await f.length();
      if (len > 100 * 1024 * 1024) {
        _showError(
          context,
          'File ${f.path.split(Platform.pathSeparator).last} is too large (>100MB).',
        );
        return;
      }
      newBatchSize += len;
    }

    // 3. Check Folder Capacity (Max 500MB)
    final repo = ref.read(fileRepositoryProvider);
    final sizeRes = await repo.getFolderTotalSize(folder.id);

    bool canUpload = false;
    await sizeRes.fold(
      (l) async {
        _showError(context, 'Could not verify folder quota.');
      },
      (currentSize) async {
        if (currentSize + newBatchSize > 500 * 1024 * 1024) {
          _showError(context, 'Folder capacity reached (500MB).');
        } else {
          canUpload = true;
        }
      },
    );

    if (canUpload) {
      ref
          .read(fileNotifierProvider(folder.id).notifier)
          .uploadFiles(files, folder, folderKey);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 48,
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'This vault is empty',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload files to secure them.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _ShareDialog extends HookWidget {
  final Function(DateTime?, bool) onExport;

  const _ShareDialog({required this.onExport});

  @override
  Widget build(BuildContext context) {
    final expiry = useState<DateTime?>(null);
    final allowSave = useState(true);

    return BackdropFilter(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Export Vault",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Allow Download Switch
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(
                    "Allow Extraction",
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  subtitle: Text(
                    "Recipients can save files externally",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white30,
                    ),
                  ),
                  value: allowSave.value,
                  activeColor: const Color(0xFFEF5350),
                  onChanged: (v) => allowSave.value = v,
                ),
              ),
              const SizedBox(height: 12),
              // Expiry Date
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    expiry.value == null
                        ? "No Expiry Date"
                        : "Expires: ${expiry.value!.year}-${expiry.value!.month.toString().padLeft(2, '0')}-${expiry.value!.day.toString().padLeft(2, '0')} ${expiry.value!.hour.toString().padLeft(2, '0')}:${expiry.value!.minute.toString().padLeft(2, '0')}",
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFEF5350),
                              onPrimary: Colors.white,
                              surface: Color(0xFF1A1A1A),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: const Color(0xFF1A1A1A),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (pickedDate != null && context.mounted) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 0, minute: 0),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFEF5350),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1A1A1A),
                                onSurface: Colors.white,
                              ),
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: const Color(0xFF1A1A1A),
                                hourMinuteTextColor: Colors.white,
                                dialHandColor: const Color(0xFFEF5350),
                                dialBackgroundColor: Colors.white10,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (pickedTime != null) {
                        expiry.value = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      } else {
                        // Default to end of day if no time picked? Or just date?
                        // Let's force user to pick time or keep just date at 00:00
                        expiry.value = pickedDate;
                      }
                    }
                  },
                ),
              ),

              if (expiry.value != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => expiry.value = null,
                    child: Text(
                      "Clear Expiry",
                      style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onExport(expiry.value?.toUtc(), allowSave.value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Export .blindkey",
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
    );
  }
}

class _FileThumbnail extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final bool allowSave;

  const _FileThumbnail({
    super.key,
    required this.file,
    required this.folderKey,
    required this.allowSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive(wantKeepAlive: true);
    final isMounted = useIsMounted();

    // State for metadata and image
    final metadataState = useState<FileMetadata?>(null);
    final imageBytesState = useState<Uint8List?>(null);
    // Track if we should show a loader for image
    final isImageLoading = useState(false);

    useEffect(() {
      bool isCancelled = false;

      Future<void> load() async {
        if (isCancelled) return;

        try {
          final vault = ref.read(vaultServiceProvider);

          // 1. Decrypt Metadata
          final metaRes = await vault.decryptMetadata(
            file: file,
            folderKey: folderKey,
          );
          if (isCancelled || !isMounted()) return;

          final meta = metaRes.getOrElse(
            () => throw Exception("Decryption failed"),
          );
          metadataState.value = meta;

          // 2. Determine if Image
          String mime = meta.mimeType;
          // Fix legacy mime types
          if (mime == 'application/octet-stream') {
            final ext = meta.fileName.split('.').last.toLowerCase();
            switch (ext) {
              case 'jpg':
              case 'jpeg':
                mime = 'image/jpeg';
                break;
              case 'png':
                mime = 'image/png';
                break;
              case 'gif':
                mime = 'image/gif';
                break;
              case 'webp':
                mime = 'image/webp';
                break;
            }
          }

          if (mime.startsWith('image/')) {
            isImageLoading.value = true;

            final stream = vault.decryptFileStream(
              file: file,
              folderKey: folderKey,
            );
            final bytes = <int>[];

            // OPTIMIZATION: Check cancellation during stream loop
            await for (final chunk in stream) {
              if (isCancelled || !isMounted()) break;
              bytes.addAll(chunk);

              // Optional: If image is huge, maybe break early?
              // For now, full load.
            }

            if (!isCancelled && isMounted()) {
              imageBytesState.value = Uint8List.fromList(bytes);
            }
            if (isMounted()) isImageLoading.value = false;
          }
        } catch (e) {
          if (isMounted()) {
            // Handle error if needed
            isImageLoading.value = false;
          }
        }
      }

      load();

      return () {
        isCancelled = true;
      };
    }, [file.id]); // Re-run if file ID changes

    final isExpired =
        file.expiryDate != null &&
        DateTime.now().toUtc().isAfter(file.expiryDate!.toUtc());

    return Hero(
      tag: file.id,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onLongPress: () {
              if (isExpired)
                return; // Expired files handle tap only (to delete/notify)

              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle Bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            margin: const EdgeInsets.only(bottom: 24),
                          ),
                        ),
                        // File Name Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            metadataState.value?.fileName ?? "File Options",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Option
                        if (allowSave)
                          ListTile(
                            leading: const Icon(
                              Icons.download_rounded,
                              color: Colors.white70,
                            ),
                            title: Text(
                              'Save to Device',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Decrypt and save to downloads',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              final vault = ref.read(vaultServiceProvider);
                              await _saveFileToDownloads(
                                context,
                                file,
                                folderKey,
                                vault,
                              );
                            },
                          ),

                        // Delete Option
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          title: Text(
                            'Delete File',
                            style: GoogleFonts.inter(color: Colors.redAccent),
                          ),
                          subtitle: Text(
                            'Permanently remove from vault',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  "Delete File?",
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                content: Text(
                                  "This file will be permanently deleted and cannot be recovered.",
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.inter(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final repo = ref.read(
                                        fileRepositoryProvider,
                                      );
                                      await repo.deleteFile(file.id);
                                      ref.invalidate(
                                        fileNotifierProvider(file.folderId),
                                      );
                                      ref.invalidate(
                                        folderStatsProvider(file.folderId),
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "File deleted",
                                              style: GoogleFonts.inter(),
                                            ),
                                            backgroundColor:
                                                Colors.red.shade900,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      "Delete",
                                      style: GoogleFonts.inter(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onTap: () async {
              if (isExpired) {
                // Delete expired file when user tries to access it
                final repo = ref.read(fileRepositoryProvider);
                await repo.deleteFile(file.id);

                // Refresh the file list to remove the deleted file
                ref.invalidate(fileNotifierProvider(file.folderId));
                // Invalidate folder stats to update size in real-time
                ref.invalidate(folderStatsProvider(file.folderId));

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "This file expired on ${file.expiryDate!.toLocal().toString().split('.')[0]} and has been deleted",
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.red.shade900,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false, // Important for Hero
                  barrierColor: Colors.black, // Background during transition
                  pageBuilder: (_, animation, __) => FadeTransition(
                    opacity: animation,
                    child: FileViewPage(
                      file: file,
                      folderKey: folderKey,
                      allowSave: allowSave,
                    ),
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                // Background / Content
                Positioned.fill(
                  child: _buildContent(
                    metadataState.value,
                    imageBytesState.value,
                    isImageLoading.value,
                  ),
                ),
                // Footer Gradient for Text
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                    child: Text(
                      isExpired
                          ? 'Expired'
                          : (metadataState.value?.fileName ?? '...'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isExpired
                            ? Colors.redAccent
                            : Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        decoration: isExpired
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Expired Overlay
                if (isExpired)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.5),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'EXPIRED',
                              style: GoogleFonts.blackOpsOne(
                                color: Colors.redAccent,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    FileMetadata? meta,
    Uint8List? imgBytes,
    bool isLoadingImg,
  ) {
    if (meta == null) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white10,
          ),
        ),
      );
    }

    String mime = meta.mimeType;
    if (mime == 'application/octet-stream') {
      final ext = meta.fileName.split('.').last.toLowerCase();
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          mime = 'image/jpeg';
          break;
        case 'png':
          mime = 'image/png';
          break;
        case 'gif':
          mime = 'image/gif';
          break;
        case 'webp':
          mime = 'image/webp';
          break;
        case 'mp4':
        case 'm4v':
        case 'mov':
          mime = 'video/mp4';
          break;
        case 'avi':
          mime = 'video/x-msvideo';
          break;
        case 'pdf':
          mime = 'application/pdf';
          break;
        case 'txt':
          mime = 'text/plain';
          break;
      }
    }

    if (mime.startsWith('image/')) {
      if (isLoadingImg) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white10,
          ),
        );
      }
      if (imgBytes != null) {
        return Image.memory(
          imgBytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white24),
          ),
          // Optimization: Resize in memory cache to save RAM
          cacheWidth: 300,
        );
      }
      return const Center(
        child: Icon(Icons.image_rounded, size: 32, color: Colors.white24),
      );
    } else if (mime.startsWith('video/')) {
      return const Center(
        child: Icon(Icons.movie_rounded, size: 32, color: Colors.redAccent),
      );
    } else if (mime == 'application/pdf') {
      return const Center(
        child: Icon(Icons.picture_as_pdf_rounded, size: 32, color: Colors.red),
      );
    } else if (mime.startsWith('text/')) {
      return const Center(
        child: Icon(
          Icons.description_rounded,
          size: 32,
          color: Colors.blueGrey,
        ),
      );
    } else if (mime.startsWith('audio/')) {
      return const Center(
        child: Icon(
          Icons.headphones_rounded,
          size: 36,
          color: Colors.blueAccent,
        ),
      );
    } else {
      return const Center(
        child: Icon(
          Icons.insert_drive_file_rounded,
          size: 32,
          color: Colors.grey,
        ),
      );
    }
  }

  Future<void> _saveFileToDownloads(
    BuildContext context,
    FileModel file,
    SecretKey folderKey,
    VaultService vault,
  ) async {
    try {
      // Show loading indicator for Metadata decryption
      // We can use a small snackbar or just await, as it is fast.
      // Keeping original behavior but removing the long-duration snackbar that was there for the whole process.
      
      // Decrypt metadata to get filename
      final metaRes = await vault.decryptMetadata(
        file: file,
        folderKey: folderKey,
      );

      final meta = metaRes.getOrElse(
        () => throw Exception("Failed to decrypt metadata"),
      );

      // Check storage permission on Android
      Directory? downloadDir;
      if (Platform.isAndroid) {
        bool hasPermission = false;

        // check manageExternalStorage first (Android 11+)
        final manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isRestricted) {
          // If it's valid for this platform (Android 11+), use it
          if (manageStatus.isGranted) {
            hasPermission = true;
          } else {
            // Show rationale if needed or just request
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Full storage access required to save files",
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            final newStatus = await Permission.manageExternalStorage.request();
            hasPermission = newStatus.isGranted;
          }
        } 
        
        // Fallback or specific check for older Android versions (Android < 11)
        if (!hasPermission && manageStatus.isRestricted) {
           var storageStatus = await Permission.storage.status;
           if (storageStatus.isGranted) {
             hasPermission = true;
           } else {
             if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Storage permission required to save files",
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
             }
             final newStatus = await Permission.storage.request();
             hasPermission = newStatus.isGranted;
           }
        }

        if (!hasPermission) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Storage permission denied. Cannot save file.",
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: "Settings",
                    textColor: Colors.white,
                    onPressed: () => openAppSettings(),
                  ),
                ),
             );
          }
          return;
        }

        // Try multiple common Downloads paths
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];

        // Also try using path_provider
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to Downloads from external storage directory
            final parentDir = externalDir.parent.parent.parent.parent; // usually /storage/emulated/0/Android/data/pkg -> /storage/emulated/0
            final downloadsPath = '${parentDir.path}/Download';
            possiblePaths.insert(0, downloadsPath);
          }
        } catch (e) {
          // path_provider failed, continue with hardcoded paths
        }

        // Try each path until we find one that exists
        for (final dirPath in possiblePaths) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            downloadDir = dir;
            break;
          }
        }

        // If no Downloads directory found, try to create it
        if (downloadDir == null && possiblePaths.isNotEmpty) {
          try {
            downloadDir = Directory(possiblePaths[0]);
            await downloadDir.create(recursive: true);
          } catch (e) {
            downloadDir = null;
          }
        } // End Android handling
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        downloadDir = appDocDir;
      }

      if (downloadDir == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Could not access Downloads folder",
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 1. Resolve 'BlindKey' subfolder in Downloads
      Directory? finalDir;
      if (downloadDir != null) {
        final blindKeyDir = Directory("${downloadDir.path}${Platform.pathSeparator}BlindKey");
         if (!await blindKeyDir.exists()) {
          try {
             await blindKeyDir.create(recursive: true);
             finalDir = blindKeyDir;
          } catch(e) {
             // If creation fails, fallback to root Downloads
             finalDir = downloadDir; 
          }
        } else {
             finalDir = blindKeyDir;
        }
      } else {
        return;
      }

      // Get filename from metadata
      final filename = meta.fileName;
      // Use finalDir
      final targetPath =
          "${finalDir.path}${Platform.pathSeparator}$filename";
      final targetFile = File(targetPath);

      // Handle file name conflicts
      String finalPath = targetPath;
      if (await targetFile.exists()) {
        final nameWithoutExt = filename.substring(0, filename.lastIndexOf('.'));
        final ext = filename.substring(filename.lastIndexOf('.'));
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newFilename = '$nameWithoutExt$timestamp$ext';
        finalPath = "${finalDir.path}${Platform.pathSeparator}$newFilename";
      }

      // Open Progress Dialog to handle the actual download
      if (context.mounted) {
        final success = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _DownloadProgressDialog(
             file: file, 
             fileName: meta.fileName,
             folderKey: folderKey, 
             savePath: finalPath,
             totalSize: meta.size,
          ),
        );

        if (success == true) {
             ScaffoldMessenger.of(context).clearSnackBars();
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text(
                   "Saved to ${Platform.isIOS ? 'Documents' : 'Downloads'}/BlindKey/${finalPath.split(Platform.pathSeparator).last}",
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Save failed: ${e.toString()}",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _ExportProgressDialog extends HookConsumerWidget {
  final FolderModel folder;
  final SecretKey folderKey;
  final DateTime? expiry;
  final bool allowSave;

  const _ExportProgressDialog({
    required this.folder,
    required this.folderKey,
    required this.expiry,
    required this.allowSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = useState(0.0);
    final status = useState("Initializing...");
    final resultPath = useState<String?>(null);
    final error = useState<String?>(null);

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      final subscription = vault
          .exportFolder(
            folder: folder,
            key: folderKey,
            expiry: expiry,
            allowSave: allowSave,
          )
          .listen(
            (event) {
              if (event is ExportProgress) {
                progress.value = event.progress;
                status.value = event.message;
              } else if (event is ExportSuccess) {
                progress.value = 1.0;
                status.value = "Export Complete";
                resultPath.value = event.path;
              } else if (event is ExportFailure) {
                error.value = event.error;
              }
            },
            onError: (e) {
              error.value = e.toString();
            },
          );

      return subscription.cancel;
    }, []);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        title: Text(
          "Exporting...",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error.value != null) ...[
                Center(
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade400,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Error: ${error.value}",
                  style: GoogleFonts.inter(color: Colors.red.shade200),
                ),
              ] else if (resultPath.value != null) ...[
                const Center(
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Package Created Successfully",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ] else ...[
                Text(
                  status.value,
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.value,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${(progress.value * 100).toInt()}%",
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: resultPath.value != null
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Close",
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _saveToDownloads(context, resultPath.value!);
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    "Save to Downloads",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Share.shareXFiles([
                      XFile(resultPath.value!),
                    ], text: 'Secure BlindKey Package');
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white70),
                  tooltip: 'Share',
                ),
              ]
            : [
                if (error.value != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Close",
                      style: GoogleFonts.inter(color: Colors.white54),
                    ),
                  ),
              ],
      ),
    );
  }

  Future<void> _saveToDownloads(BuildContext context, String path) async {
    try {
      Directory? downloadDir;

      if (Platform.isAndroid) {
        bool hasPermission = false;

        // check manageExternalStorage first (Android 11+)
        final manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isRestricted) {
          // If it's valid for this platform (Android 11+), use it
          if (manageStatus.isGranted) {
            hasPermission = true;
          } else {
            // Show rationale if needed or just request
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Full storage access required to save .blindkey file",
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: Colors.orange.shade800,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            final newStatus = await Permission.manageExternalStorage.request();
            hasPermission = newStatus.isGranted;
          }
        } 
        
        // Fallback for Android < 11
        if (!hasPermission && manageStatus.isRestricted) {
           var storageStatus = await Permission.storage.status;
           if (storageStatus.isGranted) {
             hasPermission = true;
           } else {
             if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Storage permission required to save files",
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: Colors.orange.shade800,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
             }
             final newStatus = await Permission.storage.request();
             hasPermission = newStatus.isGranted;
           }
        }

        if (!hasPermission) {
          if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Storage permission denied. Cannot save file.",
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: "Settings",
                    textColor: Colors.white,
                    onPressed: () => openAppSettings(),
                  ),
                ),
             );
          }
          return;
        }

        // Try multiple common Downloads paths
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];

        // Also try using path_provider
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // Navigate to Downloads from external storage directory
            final parentDir = externalDir.parent.parent.parent.parent;
            final downloadsPath = '${parentDir.path}/Download';
            possiblePaths.insert(0, downloadsPath);
          }
        } catch (e) {
          // path_provider failed, continue with hardcoded paths
        }

        // Try each path until we find one that exists
        for (final dirPath in possiblePaths) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            downloadDir = dir;
            break;
          }
        }

        // If no Downloads directory found, try to create it in the first possible location
        if (downloadDir == null && possiblePaths.isNotEmpty) {
          try {
            downloadDir = Directory(possiblePaths[0]);
            await downloadDir.create(recursive: true);
          } catch (e) {
            // Failed to create directory
            downloadDir = null;
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use the app's documents directory (iOS doesn't have a public Downloads folder)
        final appDocDir = await getApplicationDocumentsDirectory();
        downloadDir = appDocDir;
      }

      if (downloadDir == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Could not access Downloads folder",
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 1. Resolve 'BlindKey' subfolder in Downloads
      Directory? finalDir;
      if (downloadDir != null) {
        final blindKeyDir = Directory("${downloadDir.path}${Platform.pathSeparator}BlindKey");
         if (!await blindKeyDir.exists()) {
          try {
             await blindKeyDir.create(recursive: true);
             finalDir = blindKeyDir;
          } catch(e) {
             // If creation fails, fallback to root Downloads
             finalDir = downloadDir; 
          }
        } else {
             finalDir = blindKeyDir;
        }
      } else {
        // Should have returned early if null, but just in case
        return;
      }

      final sourceFile = File(path);
      if (!await sourceFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Source file not found",
                style: GoogleFonts.inter(),
              ),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final sourceSize = await sourceFile.length();
      final filename = path.split(Platform.pathSeparator).last;
      
      // Use finalDir instead of downloadDir
      final newPath = "${finalDir.path}${Platform.pathSeparator}$filename";
      final targetFile = File(newPath);

      // Check if file already exists and handle it
      if (await targetFile.exists()) {
        // Option 1: Overwrite
        // Option 2: Add timestamp to filename
        final nameWithoutExt = filename.substring(0, filename.lastIndexOf('.'));
        final ext = filename.substring(filename.lastIndexOf('.'));
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newFilename = '$nameWithoutExt$timestamp$ext';
        final altPath =
            "${finalDir.path}${Platform.pathSeparator}$newFilename";
        final altFile = File(altPath);

        // Copy to alternate path
        await sourceFile.copy(altPath);

        // Verify the file was actually copied
        if (!await altFile.exists()) {
          throw Exception("File copy verification failed");
        }

        // Verify file size matches
        final targetSize = await altFile.length();
        if (targetSize != sourceSize) {
          throw Exception("File size mismatch after copy");
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Saved to ${Platform.isIOS ? 'Documents' : 'Downloads'}/BlindKey/$newFilename",
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
        return;
      }

      // Copy the file
      await sourceFile.copy(newPath);

      // Verify the file was actually copied
      if (!await targetFile.exists()) {
        throw Exception("File copy verification failed - file does not exist");
      }

      // Verify file size matches
      final targetSize = await targetFile.length();
      if (targetSize != sourceSize) {
        throw Exception(
          "File size mismatch after copy (expected: $sourceSize, got: $targetSize)",
        );
      }

      // Only show success if file was actually saved and verified
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Saved to ${Platform.isIOS ? 'Documents' : 'Downloads'}/BlindKey/$filename",
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Save failed: ${e.toString()}",
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _DownloadProgressDialog extends HookConsumerWidget {
  final FileModel file;
  final String fileName;
  final SecretKey folderKey;
  final String savePath;
  final int totalSize;

  const _DownloadProgressDialog({
    required this.file,
    required this.fileName,
    required this.folderKey,
    required this.savePath,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = useState(0.0);
    final error = useState<String?>(null);
    final isDone = useState(false);

    useEffect(() {
      bool mounted = true;
      Future<void> startDownload() async {
        try {
          final vault = ref.read(vaultServiceProvider);
          final stream = vault.decryptFileStream(
              file: file, folderKey: folderKey);
          
          final sink = File(savePath).openWrite();
          int received = 0;

          try {
            await for (final chunk in stream) {
              if (!mounted) {
                 await sink.close();
                 return; // Cancelled
              }
              sink.add(chunk);
              received += chunk.length;
              if (totalSize > 0) {
                progress.value = received / totalSize;
              }
            }
            await sink.flush();
          } finally {
            await sink.close();
          }
          
          if (!mounted) return;
          
          isDone.value = true;
          // Verify
          final savedFile = File(savePath);
          if (!await savedFile.exists() || await savedFile.length() != totalSize) {
             throw Exception("File verification failed (size mismatch or missing)");
          }

          if (context.mounted) {
             Navigator.pop(context, true); // Return true for success
          }
        } catch (e) {
          if (mounted) error.value = e.toString();
        }
      }

      startDownload();
      return () {
        mounted = false;
      };
    }, []);

    return PopScope(
      canPop: false, // Prevent dismissal while downloading
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text(
            isDone.value ? "Download Complete" : "Downloading...",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error.value != null) ...[
                  Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${error.value}",
                    style: GoogleFonts.inter(color: Colors.red.shade200),
                  ),
                ] else ...[
                  Text(
                    "Decrypting $fileName...",
                    style: GoogleFonts.inter(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalSize > 0 ? progress.value : null,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.blueAccent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      totalSize > 0 ? "${(progress.value * 100).toInt()}%" : "...",
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: error.value != null
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Close", style: GoogleFonts.inter(color: Colors.white70)),
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
