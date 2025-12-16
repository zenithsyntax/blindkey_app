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
    return result.fold(
      (failure) => throw failure, 
      (folders) => folders,
    );
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
}
