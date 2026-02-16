import 'dart:io';

import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:blindkey_app/domain/failures/failures.dart'; // Added explicit import
import 'package:blindkey_app/presentation/utils/error_mapper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_notifier.g.dart';

@riverpod
class FolderNotifier extends _$FolderNotifier {
  @override
  FutureOr<List<FolderModel>> build() async {
    final repo = ref.watch(folderRepositoryImplProvider);
    final result = await repo.getFolders();
    return result.fold((failure) => throw failure, (folders) => folders);
  }

  Future<void> createFolder(String name, String password) async {
    final vault = ref.read(vaultServiceProvider);

    // Preserve current state to restore on error
    final previousState = state;
    state = const AsyncValue.loading();

    final result = await vault.createFolder(name, password);

    result.fold(
      (failure) {
        // Restore previous state so we don't show full screen error or get stuck in loading
        if (previousState.hasValue) {
          state = previousState;
        } else {
          // If no previous value, just invalidate to reload
          ref.invalidateSelf();
        }
        throw failure;
      },
      (_) {
        // Refresh list
        ref.invalidateSelf();
      },
    );
  }

  Future<void> deleteFolder(String id) async {
    final repo = ref.read(folderRepositoryImplProvider);
    await repo.deleteFolder(id);
    ref.invalidateSelf();
  }

  Future<void> renameFolder(String id, String newName) async {
    final repo = ref.read(folderRepositoryImplProvider);
    final currentState = state.value;
    if (currentState == null) return;

    final folder = currentState.firstWhere(
      (f) => f.id == id,
      orElse: () =>
          throw Exception(ErrorMapper.getUserFriendlyError("Folder not found")),
    );
    final updatedFolder = folder.copyWith(name: newName);

    await repo.saveFolder(updatedFolder);
    ref.invalidateSelf();
  }

  Future<void> importFolder(String path, String password) async {
    final vault = ref.read(vaultServiceProvider);
    // Preserve current state instead of setting to loading
    // This prevents the home page from showing error state if import fails
    final previousState = state;

    final result = await vault.importBlindKey(path, password);

    result.fold(
      (failure) {
        // Don't set global state to error - let the dialog handle it
        // Restore previous state to prevent error from persisting
        if (previousState.hasValue) {
          state = previousState;
        } else {
          // If there was no previous state, just invalidate to rebuild
          ref.invalidateSelf();
        }
        // Throw the failure so the dialog can catch and display it
        throw failure;
      },
      (_) {
        ref.invalidateSelf(); // Refresh list to show imported folder
      },
    );
  }

  Future<int> importLocalFolder({
    required String folderPath,
    required String vaultName,
    required String password,
    required Function(double) onProgress,
  }) async {
    final vault = ref.read(vaultServiceProvider);

    // 1. Create the Vault
    final createResult = await vault.createFolder(vaultName, password);

    int processedCount = 0;
    int successCount = 0;

    await createResult.fold((failure) => throw failure, (folder) async {
      try {
        // 2. Derive Key (Need it for encryption)
        // Since we just created it with 'password', we can verify/get it.
        // Or just re-derive it manually to save a "Decrypt Verify" step,
        // but verifyPasswordAndGetKey is safer as it handles salt reading.
        final keyResult = await vault.verifyPasswordAndGetKey(folder, password);

        await keyResult.fold((failure) => throw failure, (folderKey) async {
          // 3. List Files from Directory (Recursive)
          final dir = Directory(folderPath);
          if (!await dir.exists())
            throw Exception(
              ErrorMapper.getUserFriendlyError("Folder not found"),
            ); // Changed to Exception for consistency

          final entities = await dir
              .list(recursive: true, followLinks: false)
              .toList();
          final files = entities.whereType<File>().toList();

          print(
            "IMPORT DEBUG: Found ${entities.length} entities, ${files.length} files in ${dir.path}",
          );

          if (files.isEmpty) {
            throw Failure.unexpected(
              "No files found in selected folder. (Found ${entities.length} items in ${dir.path})",
            );
          }

          final total = files.length;

          for (final file in files) {
            print("IMPORT DEBUG: Processing ${file.path}");
            // Encrypt and Save
            // This is a stream, we wait for it to finish.
            // We might want to use a pool if we want parallel, but sequential is safer for now.
            try {
              final stream = vault.encryptAndSaveFile(
                originalFile: file,
                folderId: folder.id,
                folderKey: folderKey,
              );

              await for (final _ in stream) {
                // We don't track per-file progress here efficiently yet,
                // just chunk completion.
              }
              print("IMPORT DEBUG: Successfully imported ${file.path}");
              successCount++;
            } catch (e) {
              // Log error but continue? Or fail entire import?
              // For a large folder, failing everything on one file is annoying.
              // But we want "Atomic" feel?
              // Let's continue and report errors?
              // For now: continue.
              print(
                "IMPORT DEBUG: Failed to import file: ${file.path} error: $e",
              );
            }

            processedCount++;
            onProgress(processedCount / total);
          }
        });
      } catch (e) {
        // If something fails AFTER creating folder, we might want to delete the folder?
        // User can manually delete it.
        rethrow;
      }
    });

    ref.invalidateSelf();
    return successCount;
  }

  Future<dynamic> unlockFolder(String folderId, String password) async {
    // We need to find the folder model first.
    // We can get it from current state if valid.
    final currentState = state.value;
    if (currentState == null) return null;

    final folder = currentState.firstWhere(
      (f) => f.id == folderId,
      orElse: () =>
          throw Exception(ErrorMapper.getUserFriendlyError("Folder not found")),
    );

    final vault = ref.read(vaultServiceProvider);
    final result = await vault.verifyPasswordAndGetKey(folder, password);

    return result.fold(
      (failure) => null, // Return null on failure (wrong password)
      (key) => key, // Return Key on success
    );
  }
}
