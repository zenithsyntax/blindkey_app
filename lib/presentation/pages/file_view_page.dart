import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';

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
    
    // Helper to get raw file details (name/mime/size)
    // We should expose this in VaultService properly but for now assume we can decrypt metadata cheaply.
    final fileDetailsFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      
      return res.fold(
        (l) => throw Exception(l.toString()),
        (meta) {
          // Fix for legacy files with "application/octet-stream"
          if (meta.mimeType == 'application/octet-stream') {
             final ext = meta.fileName.split('.').last.toLowerCase();
             String newMime = 'application/octet-stream';
             switch (ext) {
                case 'jpg': case 'jpeg': newMime = 'image/jpeg'; break;
                case 'png': newMime = 'image/png'; break;
                case 'gif': newMime = 'image/gif'; break;
                case 'webp': newMime = 'image/webp'; break;
                case 'bmp': newMime = 'image/bmp'; break;
                case 'tif': case 'tiff': newMime = 'image/tiff'; break;
                case 'mp4': case 'm4v': case 'mov': newMime = 'video/mp4'; break;
                case 'avi': newMime = 'video/x-msvideo'; break;
                case 'mkv': newMime = 'video/x-matroska'; break;
                case 'webm': newMime = 'video/webm'; break;
                case 'txt': 
                case 'css': case 'xml': case 'json': case 'yaml': case 'dart': case 'md': case 'csv':
                  newMime = 'text/plain'; break;
                case 'html': newMime = 'text/html'; break;
                case 'svg': newMime = 'image/svg+xml'; break;
                case 'pdf': newMime = 'application/pdf'; break;
                case 'doc': case 'docx': newMime = 'application/msword'; break;
                case 'xls': case 'xlsx': newMime = 'application/vnd.ms-excel'; break;
                case 'ppt': case 'pptx': newMime = 'application/vnd.ms-powerpoint'; break;
                case 'mp3': case 'wav': case 'aac': case 'wma': case 'flac': newMime = 'audio/mpeg'; break;
             }
             return meta.copyWith(mimeType: newMime);
          }
          return meta;
        },
      );
    });
    
    final fileDetails = useFuture(fileDetailsFuture);
    
    final isVideo = fileDetails.hasData && (fileDetails.data!.mimeType.startsWith('video'));

    return Scaffold(
      appBar: AppBar(
        title: Text(fileDetails.data?.fileName ?? 'File Viewer'),
        actions: [
          if (allowSave) // Only if permitted
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in External App',
              onPressed: () async {
                 if (!fileDetails.hasData) return;
                 
                 // Warning: Cannot prevent screenshots in external apps
                 final confirm = await showDialog<bool>(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: const Text('Leave Secure Vault?'),
                     content: const Text(
                       'You are about to open this file in an external application.\n\n'
                       '• Screenshot protection will be LOST.\n'
                       '• The file will be temporarily decrypted.\n\n'
                       'Do you want to proceed?',
                     ),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.pop(context, false), 
                         child: const Text('Cancel'),
                       ),
                       TextButton(
                         onPressed: () => Navigator.pop(context, true), 
                         child: const Text('Open Externally', style: TextStyle(color: Colors.red)),
                       ),
                     ],
                   ),
                 );
                 
                 if (confirm != true) return;

                 // Decrypt to temp file and open
                 final vault = ref.read(vaultServiceProvider);
                 final dir = await getTemporaryDirectory();
                 final tempPath = '${dir.path}/${fileDetails.data!.fileName}'; // Use real name for extension recognition
                 final tempFile = File(tempPath);
                 
                 if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Decrypting for external view...')));
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
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${res.message}')));
                      }
                   }
                 } catch (e) {
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                   }
                 }
              },
            ),
        ],
      ),
      body: Center(
         child: fileDetails.hasError ? Text('Error: ${fileDetails.error}')
         : !fileDetails.hasData ? const CircularProgressIndicator()
         : isVideo 
           ? _VideoView(file: file, folderKey: folderKey)
           : (fileDetails.data!.mimeType.startsWith('image/svg')
               ? _SvgView(file: file, folderKey: folderKey)
               : (fileDetails.data!.mimeType.startsWith('image/')
                   ? _ImageView(file: file, folderKey: folderKey)
                   : (fileDetails.data!.mimeType.startsWith('text/')
                       ? _TextView(file: file, folderKey: folderKey) // handles html/json too
                       : (fileDetails.data!.mimeType == 'application/pdf'
                           ? _PdfView(file: file, folderKey: folderKey)
                           : (fileDetails.data!.mimeType.startsWith('audio/')
                               ? _AudioView(file: file, folderKey: folderKey)
                               : _HexFileView(file: file, folderKey: folderKey, mimeType: fileDetails.data!.mimeType)))))),
      ),
    );
  }
}

class _ImageView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _ImageView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final contentFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final bytes = <int>[];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    });
    final snapshot = useFuture(contentFuture);
    
    if (snapshot.hasError) {
      return Center(child: Text('Error decrypting file: ${snapshot.error}'));
    }
    
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    
    return Image.memory(
      snapshot.data!,
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Text('Invalid Image Data: $error'));
      },
    );
  }
}

// Video Player - decrypts video to temp file and plays it
class _VideoView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _VideoView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      
      // Get proper file extension from metadata for format recognition
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      String ext = 'mp4'; // default
      res.fold((l) {}, (meta) {
        final fileName = meta.fileName;
        if (fileName.contains('.')) {
          ext = fileName.split('.').last.toLowerCase();
        }
      });
      
      final tempPath = '${dir.path}/${file.id}.$ext';
      final tempFile = File(tempPath);
      
      // Always overwrite to ensure freshness/security
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final sink = tempFile.openWrite();
      await for (final chunk in stream) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      return tempPath;
    });
    
    final pathSnapshot = useFuture(pathFuture);
    
    // Cleanup temp file when widget is disposed
    useEffect(() {
      return () {
        if (pathSnapshot.data != null) {
          final f = File(pathSnapshot.data!);
          if (f.existsSync()) {
            try {
              f.deleteSync();
            } catch (e) {
              debugPrint('Failed to delete temp video file: $e');
            }
          }
        }
      };
    }, [pathSnapshot.data]);

    if (pathSnapshot.hasError) {
      return Center(child: Text('Error preparing video: ${pathSnapshot.error}'));
    }
    if (!pathSnapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    return _VideoPlayerView(filePath: pathSnapshot.data!);
  }
}

// Minimal Video Player Wrapper
class _VideoPlayerView extends StatefulWidget {
  final String filePath;
  const _VideoPlayerView({required this.filePath});
  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Error loading video: $_error'));
    }
    
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          // Play/Pause overlay
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: _controller.value.isPlaying 
              ? const SizedBox.shrink() 
              : const Icon(Icons.play_arrow, size: 50, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TextView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _TextView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final contentFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final bytes = <int>[];
      await for (final chunk in stream) {
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes); // Warning: large files?
    });
    final snapshot = useFuture(contentFuture);
    
    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
    if (!snapshot.hasData) return const CircularProgressIndicator();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(snapshot.data!),
    );
  }
}

class _PdfView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _PdfView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      final tempPath = '${dir.path}/${file.id}.pdf';
      final tempFile = File(tempPath);
      
      // Always overwrite to ensure freshness/security
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final sink = tempFile.openWrite();
      await for (final chunk in stream) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      return tempPath;
    });
    
    final pathSnapshot = useFuture(pathFuture);
    
    useEffect(() {
      return () {
        if (pathSnapshot.data != null) {
           final f = File(pathSnapshot.data!);
           if (f.existsSync()) f.deleteSync();
        }
      };
    }, [pathSnapshot.data]);

    if (pathSnapshot.hasError) return Center(child: Text('Error preparing PDF: ${pathSnapshot.error}'));
    if (!pathSnapshot.hasData) return const CircularProgressIndicator();

    return PDFView(
      filePath: pathSnapshot.data!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: false,
      onError: (error) => debugPrint(error.toString()),
      onPageError: (page, error) => debugPrint('$page: ${error.toString()}'),
    );
  }
}

class _HexFileView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final String mimeType;
  
  const _HexFileView({required this.file, required this.folderKey, required this.mimeType});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We load first 10KB for preview. Loading 1GB Hex is bad.
    final contentFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final bytes = <int>[];
      int count = 0;
      await for (final chunk in stream) {
        bytes.addAll(chunk);
        count += chunk.length;
        if (count > 10240) break; // Limit to 10KB
      }
      return Uint8List.fromList(bytes.sublist(0, bytes.length > 10240 ? 10240 : bytes.length));
    });
    final snapshot = useFuture(contentFuture);

    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
    if (!snapshot.hasData) return const CircularProgressIndicator();

    final data = snapshot.data!;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text('Binary Viewer ($mimeType)\nShowing first ${data.length} bytes', 
                     textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Format not natively supported. Use the button above to open in an external app.',
                     style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: (data.length / 16).ceil(),
            itemBuilder: (context, index) {
              final start = index * 16;
              final end = (start + 16 > data.length) ? data.length : start + 16;
              final row = data.sublist(start, end);
              
              final hex = row.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
              final ascii = row.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.').join('');
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: index % 2 == 0 ? Colors.white10 : Colors.transparent, 
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(start.toRadixString(16).padLeft(6, '0'), 
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(hex, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Text(ascii, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AudioView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _AudioView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = useMemoized(() => AudioPlayer());
    final isPlaying = useState(false);
    final duration = useState(Duration.zero);
    final position = useState(Duration.zero);
    
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      // Use proper extension for player to detect format
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      String ext = 'mp3';
      res.fold((l){}, (r) => ext = r.fileName.split('.').last);
      
      final tempPath = '${dir.path}/${file.id}.$ext';
      final tempFile = File(tempPath);
      
      // Overwrite for security/freshness
      final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
      final sink = tempFile.openWrite();
      await for (final chunk in stream) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      return tempPath;
    });
    
    final pathSnapshot = useFuture(pathFuture);
    
    useEffect(() {
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
        sub1.cancel();
        sub2.cancel();
        sub3.cancel();
        player.dispose();
         if (pathSnapshot.data != null) {
           final f = File(pathSnapshot.data!);
           if (f.existsSync()) f.deleteSync();
        }
      };
    }, [pathSnapshot.data]);

    if (pathSnapshot.hasError) return Center(child: Text('Error: ${pathSnapshot.error}'));
    if (!pathSnapshot.hasData) return const CircularProgressIndicator();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(formatDuration(position.value) + " / " + formatDuration(duration.value)),
          Slider(
            value: position.value.inSeconds.toDouble().clamp(0, duration.value.inSeconds.toDouble()),
            max: duration.value.inSeconds.toDouble(),
            onChanged: (v) {
              player.seek(Duration(seconds: v.toInt()));
            },
          ),
          IconButton(
            icon: Icon(isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 64),
            onPressed: () {
               if (isPlaying.value) {
                 player.pause();
               } else {
                 player.play(DeviceFileSource(pathSnapshot.data!));
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
  const _SvgView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentFuture = useMemoized(() async {
       final vault = ref.read(vaultServiceProvider);
       final stream = vault.decryptFileStream(file: file, folderKey: folderKey);
       final bytes = <int>[];
       await for (final chunk in stream) {
         bytes.addAll(chunk);
       }
       return utf8.decode(bytes);
    });
    
    final snapshot = useFuture(contentFuture);
    
    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
    if (!snapshot.hasData) return const CircularProgressIndicator();
    
    return SvgPicture.string(snapshot.data!);
  }
}
