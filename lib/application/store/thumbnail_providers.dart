import 'dart:typed_data';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/services/thumbnail_queue_service.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/presentation/utils/error_mapper.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'thumbnail_providers.g.dart';

// Cache for decrypted metadata to avoid repeated decryption on scroll
@riverpod
Future<FileMetadata> fileMetadata(
  FileMetadataRef ref,
  FileModel file,
  SecretKey key,
) async {
  final vault = ref.watch(vaultServiceProvider);
  // Decrypt Metadata
  final metaRes = await vault.decryptMetadata(file: file, folderKey: key);

  return metaRes.fold(
    (l) =>
        throw Exception(ErrorMapper.getUserFriendlyError("Decryption failed")),
    (meta) => meta,
  );
}

// Optimized Thumbnail Provider
// 1. Checks memory/disk cache first.
// 2. If missing, queues generation.
// 3. Listens to completion stream to trigger self-refresh.
@riverpod
Future<Uint8List?> fileThumbnail(
  FileThumbnailRef ref,
  FileModel file,
  SecretKey key,
) async {
  final thumbService = ref.watch(thumbnailServiceProvider);
  final queueService = ref.watch(thumbnailQueueServiceProvider);

  // 1. Check existing
  // We can't access `thumbnailBytesState` here as we are in a provider.
  // `getThumbnail` is fast (file check).
  final bytes = await thumbService.getThumbnail(fileId: file.id, key: key);

  if (bytes != null) return bytes;

  // 2. If missing, we need to know if we SHOULD generate.
  // We need metadata to know if it is an image.
  // But we don't want to block this provider on metadata decryption if possible.
  // Ideally, we start metadata fetch in parallel?
  // Let's rely on the `fileMetadataProvider` being called by the UI anyway.
  // Wait, if we return null, UI shows placeholder.

  // We listen to the completion stream to invalidate ourselves
  final subscription = queueService.onThumbnailCompleted.listen((completedId) {
    if (completedId == file.id) {
      ref.invalidateSelf();
    }
  });
  ref.onDispose(() => subscription.cancel());

  return null;
  // We return null initially. The UI handles "enqueue if null and image".
  // OR: We can enqueue here?
  // If we enqueue here, we might enqueue non-images.
  // It's safer to let the UI (which knows it's an image from metadata) call enqueue.
}
