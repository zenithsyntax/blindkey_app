import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
               await showDialog(
                 context: context,
                 builder: (context) => _ShareDialog(
                   onExport: (expiry, allowSave) {
                     // Close the share dialog options
                     // Note: The dialog itself handles pop in its onPressed, but here we invoke logic.
                     // The _ShareDialog calls onExport AFTER popping.
                     
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
        ],
      ),
      body: Stack(
        children: [
          filesAsync.when(
            data: (files) {
              if (files.isEmpty) {
                return const Center(child: Text('No encrypted files. Upload one!'));
              }
              
              return GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: files.length + (ref.read(fileNotifierProvider(folder.id).notifier).hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == files.length) {
                     return const Center(child: Padding(
                       padding: EdgeInsets.all(8.0),
                       child: CircularProgressIndicator(strokeWidth: 2),
                     ));
                  }
                  
                  final file = files[index];
                  // Pass keys to force recycle if needed, but ValueKey(file.id) is good.
                  return _FileThumbnail(
                    key: ValueKey(file.id),
                    file: file,
                    folderKey: folderKey,
                    allowSave: folder.allowSave,
                  );
                },
              );
            },
            error: (e, s) => Center(child: Text('Error: $e')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          
          // Upload Progress Overlay
          if (uploadProgress.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: uploadProgress.entries.map((e) {
                      return Row(
                        children: [
                          const Icon(Icons.upload, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(value: e.value),
                          ),
                          const SizedBox(width: 8),
                          Text('${(e.value * 100).toInt()}%'),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: uploadProgress.isNotEmpty 
        ? null 
        : FloatingActionButton(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              withReadStream: false, // We use path
            );
          
            if (result != null) {
              final files = result.paths.whereType<String>().map((e) => File(e)).toList();
              
              // 1. Check Max Files per Batch
              if (files.length > 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can only select up to 10 files at a time.')),
                );
                return;
              }

              // 2. Check each file size (Max 100MB)
              int newBatchSize = 0;
              for (final f in files) {
                final len = await f.length();
                if (len > 100 * 1024 * 1024) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('File ${f.path.split(Platform.pathSeparator).last} is too large (>100MB).')),
                   );
                   return;
                }
                newBatchSize += len;
              }

              // 3. Check Folder Capacity (Max 500MB)
              final repo = ref.read(fileRepositoryProvider);
              final sizeRes = await repo.getFolderTotalSize(folder.id);
              
              // Handle result purely
              bool canUpload = false;
              await sizeRes.fold(
                (l) async {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not verify folder quota: ${l.toString()}')));
                },
                (currentSize) async {
                  if (currentSize + newBatchSize > 500 * 1024 * 1024) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Folder capacity reached (500MB). Current: ${(currentSize/1024/1024).toStringAsFixed(1)}MB')),
                     );
                  } else {
                    canUpload = true;
                  }
                }
              );

              if (canUpload) {
                ref.read(fileNotifierProvider(folder.id).notifier).uploadFiles(
                  files,
                  folder,
                  folderKey,
                );
              }
            }
          },
          child: const Icon(Icons.upload_file),
        ),
    );
  }

  Future<String> _getFileName(WidgetRef ref, FileModel file) async {
    try {
      final vault = ref.read(vaultServiceProvider);
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      
      return res.fold(
        (l) => 'Error', // Or specific error like "?"
        (meta) => meta.fileName,
      );
    } catch (e) {
      return '?';
    }
  }
}

class _ShareDialog extends HookWidget {
  final Function(DateTime?, bool) onExport;
  
  const _ShareDialog({required this.onExport});
  
  @override
  Widget build(BuildContext context) {
    final expiry = useState<DateTime?>(null);
    final allowSave = useState(true);
    
    return AlertDialog(
      title: const Text("Share Folder"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text("Allow Download"),
            value: allowSave.value,
            onChanged: (v) => allowSave.value = v,
          ),
          ListTile(
            title: Text(expiry.value == null ? "No Expiry" : "Expires: ${expiry.value.toString().split(' ')[0]}"),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) expiry.value = picked;
            },
          ),
          if (expiry.value != null)
             TextButton(
               onPressed: () => expiry.value = null, 
               child: const Text("Clear Expiry")
             ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onExport(expiry.value, allowSave.value);
          },
          child: const Text("Export .blindkey"),
        ),
      ],
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
          final metaRes = await vault.decryptMetadata(file: file, folderKey: folderKey);
          if (isCancelled || !isMounted()) return;
          
          final meta = metaRes.getOrElse(() => throw Exception("Decryption failed"));
          metadataState.value = meta;
          
          // 2. Determine if Image
          String mime = meta.mimeType;
          // Fix legacy mime types
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

    return Card(
      clipBehavior: Clip.antiAlias,
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
        child: Stack(
          children: [
            // Background / Content
            Positioned.fill(
              child: _buildContent(metadataState.value, imageBytesState.value, isImageLoading.value),
            ),
            // Footer Gradient for Text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: Colors.black54,
                child: Text(
                  metadataState.value?.fileName ?? '...',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FileMetadata? meta, Uint8List? imgBytes, bool isLoadingImg) {
    if (meta == null) {
       return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
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
       if (isLoadingImg) {
         return const Center(child: CircularProgressIndicator(strokeWidth: 2));
       }
       if (imgBytes != null) {
         return Image.memory(
           imgBytes,
           fit: BoxFit.cover,
           errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image)),
           // Optimization: Resize in memory cache to save RAM
           cacheWidth: 200, 
         );
       }
       return const Center(child: Icon(Icons.image, size: 40));
    } else if (mime.startsWith('video/')) {
       return const Center(child: Icon(Icons.movie, size: 40, color: Colors.redAccent));
    } else if (mime == 'application/pdf') {
       return const Center(child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.red));
    } else if (mime.startsWith('text/')) {
       return const Center(child: Icon(Icons.description, size: 40, color: Colors.blueGrey));
    } else {
       return const Center(child: Icon(Icons.insert_drive_file, size: 40, color: Colors.grey));
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
      // Listen to the stream
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

    return AlertDialog(
      title: const Text("Exporting .blindkey"),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error.value != null) ...[
               const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 48)),
               const SizedBox(height: 16),
               Text("Error: ${error.value}", style: const TextStyle(color: Colors.red)),
            ] else if (resultPath.value != null) ...[
               const Center(child: Icon(Icons.check_circle_outline, color: Colors.green, size: 48)),
               const SizedBox(height: 16),
               Center(child: Text("Successfully created ${folder.name}.blindkey", textAlign: TextAlign.center)),
            ] else ...[
               Text(status.value),
               const SizedBox(height: 8),
               LinearProgressIndicator(
                 value: progress.value,
                 backgroundColor: Colors.grey[800],
                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
               ),
               const SizedBox(height: 4),
               Align(
                 alignment: Alignment.centerRight, 
                 child: Text("${(progress.value * 100).toInt()}%", style: const TextStyle(fontSize: 12))
               ),
            ]
          ],
        ),
      ),
      actions: resultPath.value != null 
          ? [
             TextButton(
               onPressed: () => Navigator.pop(context), 
               child: const Text("Close"),
             ),
             ElevatedButton.icon(
               onPressed: () async {
                 await _saveToDownloads(context, resultPath.value!);
               },
               icon: const Icon(Icons.download),
               label: const Text("Save to Downloads"),
             ),
             FilledButton.icon(
               onPressed: () {
                 Share.shareXFiles([XFile(resultPath.value!)], text: 'Secure BlindKey Package');
               },
               icon: const Icon(Icons.share),
               label: const Text("Share"),
             ),
            ]
          : [
             if (error.value != null)
               TextButton(
                 onPressed: () => Navigator.pop(context), 
                 child: const Text("Close"),
               )
          ],
    );
  }

  Future<void> _saveToDownloads(BuildContext context, String path) async {
       try {
         // Determine download directory
         Directory? downloadDir;
         if (Platform.isAndroid) {
            downloadDir = Directory('/storage/emulated/0/Download');
            if (!await downloadDir.exists()) {
               downloadDir = null; // Fallback? or Try finding it
            }
            
            // Permissions
            var status = await Permission.storage.status;
            if (!status.isGranted) {
              await Permission.storage.request();
            }
         } else if (Platform.isWindows) {
            // Windows download path usually in user profile
            // Not handled in original code, but good to add if needed.
         }
         
         if (downloadDir != null) {
             final filename = path.split(Platform.pathSeparator).last;
             final newPath = "${downloadDir.path}/$filename";
             
             // Check if exists
             if (await File(newPath).exists()) {
                // Rename or overwrite? Overwrite for now as user requested download.
             }
             
             await File(path).copy(newPath);
             
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text("Saved to Downloads/$filename"),
                   backgroundColor: Colors.green,
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
