import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Added for BackdropFilter

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
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts

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
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
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
                         side: BorderSide(color: Colors.white.withOpacity(0.08)),
                       ),
                       title: Text("Leave Secure Vault?", style: GoogleFonts.inter(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
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
                           child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
                         ),
                         TextButton(
                           onPressed: () => Navigator.pop(context, true), 
                           child: Text('Open Externally', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                         ),
                       ],
                     ),
                   ),
                 );
                 
                 if (confirm != true) return;

                 // Decrypt logic kept same
                 // ...
                 _openExternally(context, ref, file, folderKey, fileDetails.data!.fileName);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
           // Background
           Positioned.fill(
             child: Container(color: const Color(0xFF0F0F0F)),
           ),
           
           SafeArea(
             child: Center(
                child: fileDetails.hasError ? Text('Error: ${fileDetails.error}', style: GoogleFonts.inter(color: Colors.red))
                : !fileDetails.hasData ? const CircularProgressIndicator(color: Colors.white30)
                : Hero(
                    tag: file.id,
                    child: Material(
                      type: MaterialType.transparency,
                      child: isVideo 
                        ? _VideoView(file: file, folderKey: folderKey)
                        : (fileDetails.data!.mimeType.startsWith('image/svg')
                            ? _SvgView(file: file, folderKey: folderKey)
                            : (fileDetails.data!.mimeType.startsWith('image/')
                                ? _ImageView(file: file, folderKey: folderKey)
                                : (fileDetails.data!.mimeType.startsWith('text/')
                                    ? _TextView(file: file, folderKey: folderKey)
                                    : (fileDetails.data!.mimeType == 'application/pdf'
                                        ? _PdfView(file: file, folderKey: folderKey)
                                        : (fileDetails.data!.mimeType.startsWith('audio/')
                                            ? _AudioView(file: file, folderKey: folderKey)
                                            : _HexFileView(file: file, folderKey: folderKey, mimeType: fileDetails.data!.mimeType)))))),
                    ),
                  ),
             ),
           ),
        ],
      ),
    );
  }

  Future<void> _openExternally(BuildContext context, WidgetRef ref, FileModel file, SecretKey folderKey, String fileName) async {
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
            )
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
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.message}'), backgroundColor: Colors.red));
            }
         }
       } catch (e) {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
         }
       }
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
      return Center(child: Text('Error decrypting file: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.white54)));
    }
    
    if (!snapshot.hasData) {
      // Show loading but keep Hero placeholder if possible, or just loader
      return const Center(child: CircularProgressIndicator(color: Colors.white30));
    }
    
    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.memory(
        snapshot.data!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24, size: 50),
      ),
    );
  }
}


class _VideoView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _VideoView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... [Same logic as before, just needs dark theme context passed implicitly]
    // Refactoring fully for succinctness
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      String ext = 'mp4'; 
      res.fold((l) {}, (meta) {
        final fileName = meta.fileName;
        if (fileName.contains('.')) {
          ext = fileName.split('.').last.toLowerCase();
        }
      });
      final tempPath = '${dir.path}/${file.id}.$ext';
      final tempFile = File(tempPath);
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
          if (f.existsSync()) {
            try { f.deleteSync(); } catch (_) {}
          }
        }
      };
    }, [pathSnapshot.data]);

    if (pathSnapshot.hasError) {
      return Center(child: Text('Error: ${pathSnapshot.error}', style: GoogleFonts.inter(color: Colors.white54)));
    }
    if (!pathSnapshot.hasData) {
      return const CircularProgressIndicator(color: Colors.white30);
    }

    return _VideoPlayerView(filePath: pathSnapshot.data!);
  }
}

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
          setState(() { _initialized = true; });
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() { _error = error.toString(); });
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
      return Center(child: Text('Error playing video: $_error', style: GoogleFonts.inter(color: Colors.white54)));
    }
    
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white30));
    }
    
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(
            _controller, 
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: const Color(0xFFEF5350),
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white10,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.play_arrow_rounded, size: 48, color: Colors.white),
                  ),
                ),
              ),
            ),
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
      return utf8.decode(bytes); 
    });
    final snapshot = useFuture(contentFuture);
    
    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)));
    if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.white30);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        snapshot.data!,
        style: GoogleFonts.robotoMono(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PdfView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  const _PdfView({required this.file, required this.folderKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... [Same logic simpler]
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      final tempPath = '${dir.path}/${file.id}.pdf';
      final tempFile = File(tempPath);
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

    if (pathSnapshot.hasError) return Center(child: Text('Error: ${pathSnapshot.error}', style: GoogleFonts.inter()));
    if (!pathSnapshot.hasData) return const CircularProgressIndicator(color: Colors.white30);

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

    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)));
    if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.white30);

    final data = snapshot.data!;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Binary Preview ($mimeType)',
                textAlign: TextAlign.center, 
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)
              ),
              const SizedBox(height: 4),
              Text(
                'Showing first ${data.length} bytes', 
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (data.length / 16).ceil(),
            itemBuilder: (context, index) {
              final start = index * 16;
              final end = (start + 16 > data.length) ? data.length : start + 16;
              final row = data.sublist(start, end);
              
              final hex = row.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
              final ascii = row.map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.').join('');
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        start.toRadixString(16).padLeft(4, '0'), 
                        style: GoogleFonts.robotoMono(color: Colors.white30, fontSize: 11)
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(hex, style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Text(ascii, style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 11)),
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
    // ... [Same logic simpler]
    final player = useMemoized(() => AudioPlayer());
    final isPlaying = useState(false);
    final duration = useState(Duration.zero);
    final position = useState(Duration.zero);
    
    final pathFuture = useMemoized(() async {
      final vault = ref.read(vaultServiceProvider);
      final dir = await getTemporaryDirectory();
      final res = await vault.decryptMetadata(file: file, folderKey: folderKey);
      String ext = 'mp3';
      res.fold((l){}, (r) => ext = r.fileName.split('.').last);
      
      final tempPath = '${dir.path}/${file.id}.$ext';
      final tempFile = File(tempPath);
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
      final sub1 = player.onPlayerStateChanged.listen((state) { isPlaying.value = state == PlayerState.playing; });
      final sub2 = player.onDurationChanged.listen((d) { duration.value = d; });
      final sub3 = player.onPositionChanged.listen((p) { position.value = p; });
      
      return () {
        sub1.cancel(); sub2.cancel(); sub3.cancel(); player.dispose();
        if (pathSnapshot.data != null) {
           final f = File(pathSnapshot.data!);
           if (f.existsSync()) f.deleteSync();
        }
      };
    }, [pathSnapshot.data]);

    if (pathSnapshot.hasError) return Center(child: Text('Error: ${pathSnapshot.error}', style: GoogleFonts.inter()));
    if (!pathSnapshot.hasData) return const CircularProgressIndicator(color: Colors.white30);

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
            child: const Icon(Icons.music_note_rounded, size: 64, color: Colors.blueAccent),
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
              value: position.value.inSeconds.toDouble().clamp(0, duration.value.inSeconds.toDouble()),
              max: duration.value.inSeconds.toDouble(),
              onChanged: (v) {
                player.seek(Duration(seconds: v.toInt()));
              },
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(isPlaying.value ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 80, color: Colors.white),
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
    
    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter()));
    if (!snapshot.hasData) return const CircularProgressIndicator(color: Colors.white30);
    
    return SvgPicture.string(snapshot.data!);
  }
}

