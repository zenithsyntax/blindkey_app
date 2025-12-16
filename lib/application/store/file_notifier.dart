import 'dart:io';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_notifier.g.dart';

@riverpod
class FileNotifier extends _$FileNotifier {
  @override
  FutureOr<List<FileModel>> build(String folderId) async {
    final repo = ref.watch(fileRepositoryProvider);
    final result = await repo.getFiles(folderId);
    return result.fold(
      (failure) => throw failure,
      (files) => files,
    );
  }

  Future<void> uploadFiles(List<File> files, FolderModel folder, SecretKey folderKey) async {
    // We update state optimistically or show progress?
    // "Show real-time progress bar per file"
    // We should probably expose a separate provider for Upload Progress.
    // Or we can add a transient state here? 
    // Usually, Uploads are managed by a separate Controller/Provider that UI listens to.
    
    final vault = ref.read(vaultServiceProvider);
    
    // For simplicity, we just run them one by one or parallel?
    // "Encrypted one-by-one".
    
    for (final file in files) {
      // Start encryption
      // We need to track progress.
      // Ideally, we have a `UploadProgressNotifier`.
      // Let's trigger the upload via a different provider `uploadNotifierProvider(folderId)`.
      ref.read(uploadProgressProvider.notifier).startUpload(file, folder, folderKey);
    }
  }

  // Refresh
  void refresh() {
    ref.invalidateSelf();
  }
}

// Separate Notifier for Uploads (Global or Per Folder?)
// Global is easier to track "Background" uploads.
@Riverpod(keepAlive: true)
class UploadProgress extends _$UploadProgress {
  @override
  Map<String, double> build() => {};

  Future<void> startUpload(File file, FolderModel folder, SecretKey folderKey) async {
    final vault = ref.read(vaultServiceProvider);
    final path = file.path;
    
    state = {...state, path: 0.0};
    
    try {
      final stream = vault.encryptAndSaveFile(
        originalFile: file,
        folderId: folder.id,
        folderKey: folderKey,
      );
      
      await for (final progress in stream) {
        state = {...state, path: progress};
      }
      
      // Done
      state = {...state};
      state.remove(path); // Remove from progress list when done? Or mark as done?
      // Maybe keep it for a bit.
      
      // Invalidate file list of that folder
      ref.invalidate(fileNotifierProvider(folder.id));
      
    } catch (e) {
      // Handle error state
      state = {...state, path: -1.0}; // -1 for error
    }
  }
}
