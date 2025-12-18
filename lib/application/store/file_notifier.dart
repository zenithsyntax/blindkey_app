import 'dart:io';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/folder_stats_provider.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_notifier.g.dart';

@riverpod
class FileNotifier extends _$FileNotifier {
  // Pagination State
  int _page = 0;
  static const int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Getters for UI
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  FutureOr<List<FileModel>> build(String folderId) async {
    _page = 0;
    _hasMore = true;
    _isLoadingMore = false;

    // Initial fetch
    final repo = ref.watch(fileRepositoryProvider);
    final result = await repo.getFiles(folderId, limit: _limit, offset: 0);

    return result.fold((failure) => throw failure, (files) async {
      if (files.length < _limit) _hasMore = false;
      // Process expired files (currently just returns all files, including expired)
      return await _processExpiredFiles(files);
    });
  }

  Future<void> loadMore() async {
    // Prevent multiple calls or if no more data
    if (!_hasMore || _isLoadingMore || state.isLoading || state.hasError)
      return;

    _isLoadingMore = true;
    // We notify listeners implicitly because build() returns FutureOr, but
    // since we are just appending to the list, we don't need to invalidate the whole state,
    // just update it.

    try {
      final repo = ref.read(fileRepositoryProvider);
      _page++;
      final offset = _page * _limit;

      final result = await repo.getFiles(
        folderId,
        limit: _limit,
        offset: offset,
      );

      await result.fold(
        (l) async {
          _isLoadingMore = false;
          _page--;
        },
        (newFiles) async {
          if (newFiles.length < _limit) _hasMore = false;

          if (newFiles.isNotEmpty) {
            // Process files (including expired ones - they'll be shown with indicator)
            final processedFiles = await _processExpiredFiles(newFiles);

            final currentList = state.value ?? [];
            state = AsyncValue.data([...currentList, ...processedFiles]);
          }
          _isLoadingMore = false;
        },
      );
    } catch (e) {
      _isLoadingMore = false;
      _page--;
    }
  }

  Future<List<FileModel>> _processExpiredFiles(List<FileModel> files) async {
    // Don't delete expired files immediately - show them with expired indicator
    // They will be deleted when user tries to access them (handled in vault_service)
    return files;
  }

  Future<void> uploadFiles(
    List<File> files,
    FolderModel folder,
    SecretKey folderKey,
  ) async {
    final vault = ref.read(vaultServiceProvider);

    for (final file in files) {
      ref
          .read(uploadProgressProvider.notifier)
          .startUpload(file, folder, folderKey);
    }
  }

  // Refresh resets everything
  void refresh() {
    _page = 0;
    _hasMore = true;
    ref.invalidateSelf();
  }
}

// Separate Notifier for Uploads (Global or Per Folder?)
// Global is easier to track "Background" uploads.
@Riverpod(keepAlive: true)
class UploadProgress extends _$UploadProgress {
  @override
  Map<String, double> build() => {};

  Future<void> startUpload(
    File file,
    FolderModel folder,
    SecretKey folderKey,
  ) async {
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
      state.remove(
        path,
      ); // Remove from progress list when done? Or mark as done?
      // Maybe keep it for a bit.

      // Invalidate file list of that folder
      ref.invalidate(fileNotifierProvider(folder.id));
      // Invalidate folder stats to update size in real-time
      ref.invalidate(folderStatsProvider(folder.id));
    } catch (e) {
      // Handle error state
      state = {...state, path: -1.0}; // -1 for error
    }
  }
}
