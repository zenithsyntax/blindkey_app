import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Added for BackdropFilter

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/file_notifier.dart';
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

    useEffect(() {
      scrollController.addListener(() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
           ref.read(fileNotifierProvider(folder.id).notifier).loadMore();
        }
      });
      return null;
    }, [scrollController]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep matte black
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          folder.name,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: Colors.white70, size: 22),
            tooltip: 'Export Vault',
            onPressed: () async {
               await showDialog(
                 context: context,
                 builder: (context) => _ShareDialog(
                   onExport: (expiry, allowSave) {
                     showDialog(
                       context: context,
                       barrierDismissible: false,
                       builder: (context) => _ExportProgressDialog(
                         folder: folder,
                         folderKey: folderKey,
                         expiry: expiry,
                         allowSave: allowSave,
                       ),
                     );
                   },
                 ),
               );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF141414),
                    const Color(0xFF0F0F0F),
                    const Color(0xFF0F0505), // Deep red tint at bottom
                  ],
                ),
              ),
            ),
          ),
          
          filesAsync.when(
            data: (files) {
              if (files.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 80), // Top padding for AppBar
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: files.length + (ref.read(fileNotifierProvider(folder.id).notifier).hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == files.length) {
                     return const Center(child: Padding(
                       padding: EdgeInsets.all(8.0),
                       child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30),
                     ));
                  }
                  
                  final file = files[index];
                  return _FileThumbnail(
                    key: ValueKey(file.id),
                    file: file,
                    folderKey: folderKey,
                    allowSave: folder.allowSave,
                  );
                },
              );
            },
            error: (e, s) => Center(
              child: Text(
                'Could not load files',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white30),
            ),
          ),
          
          // Upload Progress Overlay
          if (uploadProgress.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1A1A1A).withOpacity(0.9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: uploadProgress.entries.map((e) {
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 4),
                           child: Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white70),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: e.value,
                                    backgroundColor: Colors.white10,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF5350)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(e.value * 100).toInt()}%',
                                style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                         );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: uploadProgress.isNotEmpty 
        ? null 
        : Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  withReadStream: false, 
                );
              
                if (result != null) {
                  final files = result.paths.whereType<String>().map((e) => File(e)).toList();
                  if (files.isEmpty) return;
                  
                  // Validation Logic (Limit 10, Size 100MB, Folder 500MB)
                  // Simplified for brevity, kept consistent
                  _handleUpload(context, ref, files);
                }
              },
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text(
                'Upload', 
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.2)
              ),
            ),
        ),
    );
  }

  Future<void> _handleUpload(BuildContext context, WidgetRef ref, List<File> files) async {
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
           _showError(context, 'File ${f.path.split(Platform.pathSeparator).last} is too large (>100MB).');
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
        }
      );

      if (canUpload) {
        ref.read(fileNotifierProvider(folder.id).notifier).uploadFiles(files, folder, folderKey);
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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white38,
            ),
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
                  color: Colors.white
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
                  title: Text("Allow Extraction", style: GoogleFonts.inter(color: Colors.white70)),
                  subtitle: Text(
                    "Recipients can save files externally", 
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white30)
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
                    expiry.value == null ? "No Expiry Date" : "Expires: ${expiry.value.toString().split(' ')[0]}",
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, color: Colors.white30, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(
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
                      }
                    );
                    if (picked != null) expiry.value = picked;
                  },
                ),
              ),
              
              if (expiry.value != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                     onPressed: () => expiry.value = null, 
                     child: Text("Clear Expiry", style: GoogleFonts.inter(color: Colors.white30, fontSize: 12))
                  ),
                ),
                
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: GoogleFonts.inter(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onExport(expiry.value, allowSave.value);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("Export .blindkey", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
    final metadataState = useState<FileMetadata?>(null);
    final imageBytesState = useState<Uint8List?>(null);
    final isImageLoading = useState(false);

    useEffect(() {
      bool isCancelled = false;
      Future<void> load() async {
        if (isCancelled) return;
        try {
          final vault = ref.read(vaultServiceProvider);
          final metaRes = await vault.decryptMetadata(file: file, folderKey: folderKey);
          if (isCancelled || !isMounted()) return;
          
          final meta = metaRes.getOrElse(() => throw Exception("Decryption failed"));
          metadataState.value = meta;
          
          String mime = meta.mimeType;
          if (mime == 'application/octet-stream') {
             final ext = meta.fileName.split('.').last.toLowerCase();
             switch (ext) {
               case 'jpg': case 'jpeg': mime = 'image/jpeg'; break;
               case 'png': mime = 'image/png'; break;
               case 'gif': mime = 'image/gif'; break;
               case 'webp': mime = 'image/webp'; break;
             }
          }
          
          if (mime.startsWith('image/')) {
            isImageLoading.value = true;
            final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
            final bytes = <int>[];
            await for (final chunk in stream) {
              if (isCancelled || !isMounted()) break;
              bytes.addAll(chunk);
            }
            if (!isCancelled && isMounted()) {
              imageBytesState.value = Uint8List.fromList(bytes);
            }
            if (isMounted()) isImageLoading.value = false;
          }
        } catch (e) {
          if (isMounted()) isImageLoading.value = false;
        }
      }
      load();
      return () => isCancelled = true;
    }, [file.id]);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                 builder: (_) => FileViewPage(
                   file: file,
                   folderKey: folderKey,
                   allowSave: allowSave,
                 ),
              ),
            );
          },
          splashColor: Colors.white.withOpacity(0.1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildContent(metadataState.value, imageBytesState.value, isImageLoading.value),
              
              // Gradient Overlay
              Positioned(
                left: 0, right: 0, bottom: 0,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
              ),
              
              // Filename
              Positioned(
                left: 10, right: 10, bottom: 8,
                child: Text(
                  metadataState.value?.fileName ?? '',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(FileMetadata? meta, Uint8List? imgBytes, bool isLoadingImg) {
    if (meta == null) {
       return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10)));
    }
    
    String mime = meta.mimeType;
    if (mime == 'application/octet-stream') {
        final ext = meta.fileName.split('.').last.toLowerCase();
        switch (ext) {
          case 'jpg': case 'jpeg': mime = 'image/jpeg'; break;
          case 'png': mime = 'image/png'; break;
          case 'gif': mime = 'image/gif'; break;
          case 'webp': mime = 'image/webp'; break;
          case 'mp4': case 'm4v': case 'mov': mime = 'video/mp4'; break;
          case 'avi': mime = 'video/x-msvideo'; break;
          case 'pdf': mime = 'application/pdf'; break;
          case 'txt': mime = 'text/plain'; break;
        }
    }

    if (mime.startsWith('image/')) {
       if (isLoadingImg) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10));
       if (imgBytes != null) {
         return Image.memory(
           imgBytes,
           fit: BoxFit.cover,
           errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
           cacheWidth: 250, 
         );
       }
       return const Center(child: Icon(Icons.image, size: 32, color: Colors.white24));
    } else if (mime.startsWith('video/')) {
       return const Center(child: Icon(Icons.play_circle_outline_rounded, size: 40, color: Color(0xFFEF5350)));
    } else if (mime == 'application/pdf') {
       return const Center(child: Icon(Icons.picture_as_pdf_rounded, size: 36, color: Colors.white30));
    } else if (mime.startsWith('text/')) {
       return const Center(child: Icon(Icons.description_rounded, size: 36, color: Colors.white30));
    } else if (mime.startsWith('audio/')) {
       return const Center(child: Icon(Icons.headphones_rounded, size: 36, color: Colors.blueAccent));
    } else {
       return const Center(child: Icon(Icons.insert_drive_file_rounded, size: 36, color: Colors.white24));
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
      final subscription = vault.exportFolder(
        folder: folder,
        key: folderKey,
        expiry: expiry,
        allowSave: allowSave,
      ).listen(
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
        title: Text("Exporting...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 300,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                if (error.value != null) ...[
                   Center(child: Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48)),
                   const SizedBox(height: 16),
                   Text("Error: ${error.value}", style: GoogleFonts.inter(color: Colors.red.shade200)),
                ] else if (resultPath.value != null) ...[
                   const Center(child: Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48)),
                   const SizedBox(height: 16),
                   Center(
                     child: Text(
                       "Package Created Successfully", 
                       textAlign: TextAlign.center,
                       style: GoogleFonts.inter(color: Colors.white),
                     )
                   ),
                ] else ...[
                   Text(status.value, style: GoogleFonts.inter(color: Colors.white70)),
                   const SizedBox(height: 12),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(
                       value: progress.value,
                       backgroundColor: Colors.white10,
                       valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                       minHeight: 6,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Align(
                     alignment: Alignment.centerRight, 
                     child: Text(
                       "${(progress.value * 100).toInt()}%", 
                       style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white54)
                     )
                   ),
                ]
             ],
          ),
        ),
        actions: resultPath.value != null 
            ? [
               TextButton(
                 onPressed: () => Navigator.pop(context), 
                 child: Text("Close", style: GoogleFonts.inter(color: Colors.white54)),
               ),
               ElevatedButton.icon(
                 onPressed: () async {
                   await _saveToDownloads(context, resultPath.value!);
                 },
                 icon: const Icon(Icons.download_rounded, size: 18),
                 label: Text("Save to Downloads", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                 style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                 ),
               ),
               IconButton(
                  onPressed: () {
                    Share.shareXFiles([XFile(resultPath.value!)], text: 'Secure BlindKey Package');
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white70),
                  tooltip: 'Share',
               ),
              ]
            : [
               if (error.value != null)
                 TextButton(
                   onPressed: () => Navigator.pop(context), 
                   child: Text("Close", style: GoogleFonts.inter(color: Colors.white54)),
                 )
            ],
      ),
    );
  }

  Future<void> _saveToDownloads(BuildContext context, String path) async {
       try {
         Directory? downloadDir;
         if (Platform.isAndroid) {
            downloadDir = Directory('/storage/emulated/0/Download');
            if (!await downloadDir.exists()) downloadDir = null;
            
            var status = await Permission.storage.status;
            if (!status.isGranted) await Permission.storage.request();
         } 
         
         if (downloadDir != null) {
             final filename = path.split(Platform.pathSeparator).last;
             final newPath = "${downloadDir.path}/$filename";
             
             await File(path).copy(newPath);
             
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text("Saved to Downloads/$filename", style: GoogleFonts.inter()),
                   backgroundColor: Colors.green.shade800,
                   behavior: SnackBarBehavior.floating,
                 )
               );
             }
         } else {
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not find Downloads folder")));
             }
         }
       } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.red));
          }
       }
  }
}
