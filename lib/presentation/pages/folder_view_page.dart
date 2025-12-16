import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/file_notifier.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:blindkey_app/presentation/pages/file_view_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cryptography/cryptography.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
                   onExport: (expiry, allowSave) async {
                     final vault = ref.read(vaultServiceProvider);
                     final result = await vault.exportFolder(
                       folder: folder,
                       key: folderKey,
                       expiry: expiry,
                       allowSave: allowSave,
                     );
                     
                     result.fold(
                       (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.toString()))),
                       (path) {
                         // Share using share_plus
                         // We need to add import 'package:share_plus/share_plus.dart';
                         Share.shareXFiles([XFile(path)], text: 'Secure BlindKey Package');
                       }
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
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  // If we don't have metadata decrypted yet, we can't show name.
                  // Wait, FileModel only has ENCRYPTED metadata.
                  // We need to decrypt metadata to show filename!
                  // This is a UI performance potential bottleneck.
                  // We should probably cache decrypted metadata in a Provider?
                  // Or `FileNotifier` should return `List<DecryptedFileView>`.
                  // For now, let's just show "Encrypted File" or async decrypt.
                  
                  return _FileThumbnail(file: file, folderKey: folderKey);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            withReadStream: false, // We use path
          );
          
          if (result != null) {
            final files = result.paths.whereType<String>().map((e) => File(e)).toList();
            // Start upload
            ref.read(fileNotifierProvider(folder.id).notifier).uploadFiles(
              files,
              folder,
              folderKey,
            );
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

  const _FileThumbnail({
    required this.file,
    required this.folderKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Decrypt Metadata to get MimeType and Name
    final metadataFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      // We reuse the update logic from FileViewPage: fix legacy mime types
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      return res.getOrElse(() => throw Exception("Decryption failed"));
    });
    
    final metadataSnapshot = useFuture(metadataFuture);

    // 2. If it is an image, decrypt content (small chunk or full? Full for now, resizing in memory. Not optimal for list but functional).
    // Note: Creating a separate future for content to avoid re-decrypting if just name changes? No, content is static.
    
    final imageContentFuture = useMemoized(() async {
      if (!metadataSnapshot.hasData) return null;
      final meta = metadataSnapshot.data!;
      
      // Fix legacy mime
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
        final vault = ref.read(vaultServiceProvider);
        final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
        final bytes = <int>[];
        // Limit to 5MB for thumbnail? Or just decrypt all?
        // Flutter Image.memory can crash if too big.
        // But we don't have a way to request "thumbnail" from encryption stream yet.
        await for (final chunk in stream) {
          bytes.addAll(chunk);
        }
        return Uint8List.fromList(bytes);
      }
      return null;
    }, [metadataSnapshot.data]);

    final imageContentSnapshot = useFuture(imageContentFuture);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => FileViewPage(file: file, folderKey: folderKey),
            ),
          );
        },
        child: Stack(
          children: [
            // Background / Content
            Positioned.fill(
              child: _buildContent(metadataSnapshot, imageContentSnapshot),
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
                  metadataSnapshot.data?.fileName ?? '...',
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

  Widget _buildContent(AsyncSnapshot<FileMetadata> metaSnap, AsyncSnapshot<Uint8List?> imgSnap) {
    if (metaSnap.hasError) {
       return const Center(child: Icon(Icons.error, color: Colors.red));
    }
    if (!metaSnap.hasData) {
       return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    
    final meta = metaSnap.data!;
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
       if (imgSnap.connectionState == ConnectionState.waiting) {
         return const Center(child: CircularProgressIndicator(strokeWidth: 2));
       }
       if (imgSnap.hasData && imgSnap.data != null) {
         return Image.memory(
           imgSnap.data!,
           fit: BoxFit.cover,
           errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image)),
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
