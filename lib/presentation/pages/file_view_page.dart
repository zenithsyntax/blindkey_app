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

// Simple Local Server for Streaming
class LocalStreamingService {
  HttpServer? _server;
  
  Future<String> startServer(
    Stream<List<int>> Function(int start, int? end) streamFactory,
    int fileSize,
    String mimeType,
  ) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((HttpRequest request) {
      // Handle Range Requests for Video seeking
      final response = request.response;
      response.headers.contentType = ContentType.parse(mimeType);
      response.headers.add('Accept-Ranges', 'bytes');
      
      final rangeHeader = request.headers.value('range');
      if (rangeHeader != null) {
        final range = _parseRange(rangeHeader, fileSize);
        final start = range.start;
        final end = range.end;
        final length = end - start + 1;
        
        response.statusCode = HttpStatus.partialContent;
        response.headers.add('Content-Range', 'bytes $start-$end/$fileSize');
        response.headers.contentLength = length;
        
        // Stream just the requested chunk
        // Note: Our decryption stream is continuous. 
        // Seeking in AES-GCM stream is hard without independent blocks.
        // But our `decryptFileStream` decrypts whole file.
        // Optimization: `decryptFileRange(start, end)`.
        // For now, assume linear streaming (bad for seeking but functional).
        // Or we pipe the whole stream and skip?
        // Streaming efficiently requires Random Access Decryption.
        // My Vault implementation uses GCM with 1MB blocks.
        // I CAN implement random access!
        
        response.addStream(streamFactory(start, end)).then((_) => response.close());
      } else {
        response.statusCode = HttpStatus.ok;
        response.headers.contentLength = fileSize;
        response.addStream(streamFactory(0, fileSize)).then((_) => response.close());
      }
    });
    return 'http://${_server!.address.address}:${_server!.port}/stream';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  _Range _parseRange(String rangeHeader, int fileSize) {
    if (rangeHeader.startsWith('bytes=')) {
      final parts = rangeHeader.substring(6).split('-');
      final start = int.parse(parts[0]);
      int end = parts.length > 1 && parts[1].isNotEmpty ? int.parse(parts[1]) : fileSize - 1;
      return _Range(start, end);
    }
    return _Range(0, fileSize - 1);
  }
}

class _Range {
  final int start;
  final int end;
  _Range(this.start, this.end);
}

class FileViewPage extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;

  const FileViewPage({
    super.key,
    required this.file,
    required this.folderKey,
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
                case 'mp4': case 'm4v': case 'mov': newMime = 'video/mp4'; break;
                case 'avi': newMime = 'video/x-msvideo'; break;
                case 'mkv': newMime = 'video/x-matroska'; break;
                case 'webm': newMime = 'video/webm'; break;
                case 'txt': newMime = 'text/plain'; break;
                case 'pdf': newMime = 'application/pdf'; break;
             }
             return meta.copyWith(mimeType: newMime);
          }
          return meta;
        },
      );
    });
    
    final fileDetails = useFuture(fileDetailsFuture);
    
    // Streaming logic
    final streamingUrl = useState<String?>(null);
    final isVideo = fileDetails.hasData && (fileDetails.data!.mimeType.startsWith('video'));
    
    useEffect(() {
      if (isVideo) {
        final service = LocalStreamingService();
        final vault = ref.read(vaultServiceProvider);
        
        service.startServer(
          (start, end) => vault.decryptFileRange(
            file: file,
            folderKey: folderKey,
            start: start,
            end: end,
          ),
          fileDetails.data!.size,
          fileDetails.data!.mimeType,
        ).then((url) => streamingUrl.value = url);
        
        return () => service.stop();
      }
      return null;
    }, [isVideo ? fileDetails.data : null]); // Re-run if video detected

    return Scaffold(
      appBar: AppBar(title: Text(fileDetails.data?.fileName ?? 'File Viewer')),
      body: Center(
         child: fileDetails.hasError ? Text('Error: ${fileDetails.error}')
         : !fileDetails.hasData ? const CircularProgressIndicator()
         : isVideo 
           ? (streamingUrl.value != null 
               ? _VideoPlayerView(url: streamingUrl.value!) 
               : const CircularProgressIndicator())
           : (fileDetails.data!.mimeType.startsWith('image/')
               ? _ImageView(file: file, folderKey: folderKey)
               : (fileDetails.data!.mimeType.startsWith('text/')
                   ? _TextView(file: file, folderKey: folderKey)
                   : (fileDetails.data!.mimeType == 'application/pdf'
                       ? _PdfView(file: file, folderKey: folderKey)
                       : _HexFileView(file: file, folderKey: folderKey, mimeType: fileDetails.data!.mimeType)))),
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

// Minimal Video Player Wrapper
class _VideoPlayerView extends StatefulWidget {
  final String url;
  const _VideoPlayerView({required this.url});
  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const CircularProgressIndicator();
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
          child: Text('Binary Viewer ($mimeType)\nShowing first ${data.length} bytes', 
             textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
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
