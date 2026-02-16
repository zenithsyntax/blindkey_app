import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/services/thumbnail_service.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'vault_service.dart';

final thumbnailQueueServiceProvider = Provider<ThumbnailQueueService>((ref) {
  return ThumbnailQueueService(
    ref.read(thumbnailServiceProvider),
    ref.read(vaultServiceProvider),
  );
});

class ThumbnailQueueService {
  final ThumbnailService _thumbnailService;
  final VaultService _vaultService;

  final Queue<_ThumbnailTask> _queue = Queue();
  final Set<String> _processing = {};

  final _completionController = StreamController<String>.broadcast();
  Stream<String> get onThumbnailCompleted => _completionController.stream;

  // Concurrent limit
  static const int _maxConcurrent = 2;
  int _activeCount = 0;

  ThumbnailQueueService(this._thumbnailService, this._vaultService);

  void dispose() {
    _completionController.close();
  }

  void enqueue(FileModel file, SecretKey key) {
    if (_processing.contains(file.id)) {
      return;
    }

    // Check if already in queue
    if (_queue.any((task) => task.file.id == file.id)) {
      return;
    }

    _queue.add(_ThumbnailTask(file, key));
    _processNext();
  }

  Future<void> _processNext() async {
    if (_activeCount >= _maxConcurrent || _queue.isEmpty) {
      return;
    }

    _activeCount++;
    final task = _queue.removeFirst();
    _processing.add(task.file.id);

    // Run in background but we need to coordinate with service which uses compute
    _generate(task).then((_) {
      _processing.remove(task.file.id);
      _activeCount--;
      _completionController.add(
        task.file.id,
      ); // Notify listeners of SPECIFIC completion
      _processNext();
    });
  }

  Future<void> _generate(_ThumbnailTask task) async {
    try {
      // 1. Get Metadata first (to get the file key and path)
      final metaRes = await _vaultService.decryptMetadata(
        file: task.file,
        folderKey: task.key,
      );

      await metaRes.fold(
        (failure) async {
          debugPrint(
            "ThumbnailQueue: Metadata decryption failed for ${task.file.id}",
          );
        },
        (metadata) async {
          // 2. Extract File Key (DEK)
          final fileKeyBytes = base64Decode(metadata.fileKey);
          final fileKey = SecretKey(fileKeyBytes);

          // 3. Generate Thumbnail in Background Isolate
          // We pass:
          // - Encrypted File Path (Source)
          // - File Key (to decrypt Source)
          // - Folder Key (to encrypt Resulting Thumbnail)
          await _thumbnailService.generateThumbnailFromEncryptedFile(
            encryptedFilePath: metadata.encryptedFilePath,
            fileId: task.file.id,
            fileKey: fileKey,
            folderKey: task.key,
            metadata: metadata,
          );
        },
      );
    } catch (e) {
      debugPrint("ThumbnailQueue: Error generating for ${task.file.id}: $e");
    }
  }

  bool isGenerating(String id) =>
      _processing.contains(id) || _queue.any((t) => t.file.id == id);
}

class _ThumbnailTask {
  final FileModel file;
  final SecretKey key;
  _ThumbnailTask(this.file, this.key);
}
