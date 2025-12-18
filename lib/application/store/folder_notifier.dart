import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
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
    state = const AsyncValue.loading();

    final result = await vault.createFolder(name, password);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
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
      orElse: () => throw Exception("Folder not found"),
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

  Future<dynamic> unlockFolder(String folderId, String password) async {
    // We need to find the folder model first.
    // We can get it from current state if valid.
    final currentState = state.value;
    if (currentState == null) return null;

    final folder = currentState.firstWhere(
      (f) => f.id == folderId,
      orElse: () => throw Exception("Folder not found"),
    );

    final vault = ref.read(vaultServiceProvider);
    final result = await vault.verifyPasswordAndGetKey(folder, password);

    return result.fold(
      (failure) => null, // Return null on failure (wrong password)
      (key) => key, // Return Key on success
    );
  }
}
