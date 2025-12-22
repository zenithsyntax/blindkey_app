import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Added for BackdropFilter

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/file_notifier.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
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
    // 1. Preload Trusted Time if file has expiry
    final trustedTimeFuture = useMemoized(() async {
      if (file.expiryDate != null) {
        // Enforce Internet Check
        try {
          return await ref.read(trustedTimeServiceProvider).getTrustedTime();
        } catch (e) {
          throw Exception("Internet connection is required to verify this shared file.");
        }
      }
      return null;
    }, [file.id]); // Keyed by ID

    final trustedTimeSnapshot = useFuture(trustedTimeFuture);

    // Helper to get raw file details (name/mime/size)
    final fileDetailsFuture = useMemoized(() async {
      // Wait for time check if needed
      DateTime? trustedNow;
      if (file.expiryDate != null) {
         if (trustedTimeSnapshot.hasError) throw trustedTimeSnapshot.error!;
         if (!trustedTimeSnapshot.hasData) return null; // Wait...
         // Actually, useFuture returns null data if loading OR if future returned null.
         // If file.expiryDate is NOT null, we expect data.
         // If file.expiryDate IS null, data is null (correct).
         trustedNow = trustedTimeSnapshot.data;
      }

      final vault = ref.read(vaultServiceProvider);
      final res = await vault.decryptMetadata(
          file: file, 
          folderKey: folderKey,
          trustedNow: trustedNow,
      );

      return res.fold((l) => throw Exception(l.toString()), (meta) {
        // ... (legacy fix logic) ...
        // Fix for legacy files with "application/octet-stream"
        if (meta.mimeType == 'application/octet-stream') {
           // ... same logic ...
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
              newMime = 'application/msword';
              break;
            case 'xls':
            case 'xlsx':
              newMime = 'application/vnd.ms-excel';
              break;
            case 'ppt':
            case 'pptx':
              newMime = 'application/vnd.ms-powerpoint';
              break;
            case 'mp3':
            case 'wav':
            case 'aac':
            case 'wma':
            case 'flac':
              newMime = 'audio/mpeg';
              break;
          }
          return meta.copyWith(mimeType: newMime);
        }
        return meta;
      });
    }, [file.id, trustedTimeSnapshot.data, trustedTimeSnapshot.error]); // Re-run when time is ready

    final fileDetails = useFuture(fileDetailsFuture);

    // Loading State handling (Time check OR Decrypt)
    if (file.expiryDate != null && trustedTimeSnapshot.connectionState == ConnectionState.waiting) {
       // Showing loading for verification
    }

    final isVideo =
        fileDetails.hasData && (fileDetails.data!.mimeType.startsWith('video'));

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

                // Decrypt logic kept same
                // ...
                _openExternally(
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
      body: Stack(
        children: [
          // Background
          Positioned.fill(child: Container(color: const Color(0xFF0F0F0F))),

          SafeArea(
            child: Center(
              child: fileDetails.hasError
                  ? Text(
                      'Error: ${fileDetails.error}',
                      style: GoogleFonts.inter(color: Colors.red),
                    )
                  : !fileDetails.hasData
                  ? const SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        color: Colors.white30,
                        backgroundColor: Colors.white10,
                      ),
                    )
                  : Hero(
                      tag: file.id,
                      child: Material(
                        type: MaterialType.transparency,
                        child: isVideo
                            ? _VideoView(
                                file: file,
                                folderKey: folderKey,
                                fileSize: fileDetails.data!.size,
                                trustedNow: trustedTimeSnapshot.data,
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
                                            fileSize: fileDetails.data!.size,
                                            trustedNow: trustedTimeSnapshot.data,
                                          )
                                        : (fileDetails.data!.mimeType
                                                  .startsWith('text/')
                                              ? _TextView(
                                                  file: file,
                                                  folderKey: folderKey,
                                                  fileSize:
                                                      fileDetails.data!.size,
                                                  trustedNow: trustedTimeSnapshot.data,
                                                )
                                              : (fileDetails.data!.mimeType ==
                                                        'application/pdf'
                                                    ? _PdfView(
                                                        file: file,
                                                        folderKey: folderKey,
                                                        fileSize: fileDetails
                                                            .data!
                                                            .size,
                                                        trustedNow: trustedTimeSnapshot.data,
                                                      )
                                                    : (fileDetails
                                                              .data!
                                                              .mimeType
                                                              .startsWith(
                                                                'audio/',
                                                              )
                                                          ? _AudioView(
                                                              file: file,
                                                              folderKey:
                                                                  folderKey,
                                                              fileSize:
                                                                  fileDetails
                                                                      .data!
                                                                      .size,
                                                              trustedNow: trustedTimeSnapshot.data,
                                                            )
                                                          : _HexFileView(
                                                              file: file,
                                                              folderKey:
                                                                  folderKey,
                                                              mimeType:
                                                                  fileDetails
                                                                      .data!
                                                                      .mimeType,
                                                              fileSize:
                                                                  fileDetails
                                                                      .data!
                                                                      .size,
                                                              trustedNow: trustedTimeSnapshot.data,
                                                            )))))),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternally(
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

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;

      final subscription = vault
          .decryptFileStream(file: file, folderKey: folderKey, trustedNow: trustedNow)
          .listen(
            (chunk) {
              if (isCancelled) return;
              // We can't easily stream into Image.memory until done for regular images,
              // but we need to accumulate bytes.
              // Using a builder is inefficient re-allocating?
              // Just accumulate in list.
            },
            onError: (e) {
              if (!isCancelled) error.value = e;
            },
          );

      // Manually accumulate to avoid closure capture issues with 'subscription'
      final bytes = <int>[];
      subscription.onData((chunk) {
        if (isCancelled) return;
        bytes.addAll(chunk);
        received += chunk.length;
        // Avoid division by zero
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
      };
    }, []);

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

    return InteractiveViewer(
      clipBehavior: Clip.none,
      minScale: 0.5,
      maxScale: 4.0,
      child: Image.memory(
        imageBytes.value!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, color: Colors.white24, size: 50),
      ),
    );
  }
}

class _VideoView extends HookConsumerWidget {
  final FileModel file;
  final SecretKey folderKey;
  final int fileSize;
  final DateTime? trustedNow;

  const _VideoView({
    required this.file,
    required this.folderKey,
    required this.fileSize,
    this.trustedNow,
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

    return _VideoPlayerView(filePath: videoPath.value!);
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
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _initialized = true;
              });
              _controller.play();
            }
          })
          .catchError((error) {
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
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
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
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
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
          .decryptFileStream(file: file, folderKey: folderKey, trustedNow: trustedNow)
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

    useEffect(() {
      bool isCancelled = false;
      String? tempPath;

      Future<void> load() async {
        try {
          final vault = ref.read(vaultServiceProvider);
          final dir = await getTemporaryDirectory();
          tempPath = '${dir.path}/${file.id}.pdf';
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

          if (!isCancelled) {
            pdfPath.value = tempPath;
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

    if (error.value != null)
      return Center(
        child: Text('Error: ${error.value}', style: GoogleFonts.inter()),
      );
    if (pdfPath.value == null)
      return _LoadingProgressView(progress: progress.value);

    return PDFView(
      filePath: pdfPath.value!,
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
  final int fileSize;
  final DateTime? trustedNow;

  const _HexFileView({
    required this.file,
    required this.folderKey,
    required this.mimeType,
    required this.fileSize,
    this.trustedNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hexData = useState<Uint8List?>(null);
    final error = useState<Object?>(null);
    final progress = useState<double>(0.0);

    useEffect(() {
      final vault = ref.read(vaultServiceProvider);
      int received = 0;
      bool isCancelled = false;
      final bytes = <int>[];
      int count = 0;

      final subscription = vault
          .decryptFileStream(file: file, folderKey: folderKey, trustedNow: trustedNow)
          .listen(
            (chunk) {
              if (isCancelled) return;

              if (count < 10240) {
                bytes.addAll(chunk);
                count += chunk.length;
                received += chunk.length;
                progress.value = (received / 10240).clamp(0.0, 1.0);
              } else {
                // We have enough.
              }
            },
            onDone: () {
              if (!isCancelled) {
                hexData.value = Uint8List.fromList(
                  bytes.sublist(0, bytes.length > 10240 ? 10240 : bytes.length),
                );
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
    if (hexData.value == null)
      return _LoadingProgressView(progress: progress.value);

    final data = hexData.value!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Binary Preview ($mimeType)',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Showing first ${data.length} bytes',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
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

              final hex = row
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(' ');
              final ascii = row
                  .map(
                    (b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.',
                  )
                  .join('');

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        start.toRadixString(16).padLeft(4, '0'),
                        style: GoogleFonts.robotoMono(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        hex,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Text(
                        ascii,
                        style: GoogleFonts.robotoMono(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
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
          .decryptFileStream(file: file, folderKey: folderKey, trustedNow: trustedNow)
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
