import 'package:blindkey_app/application/providers.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_stats_provider.g.dart';

class FolderStats {
  final int fileCount;
  final int totalSize;

  FolderStats({required this.fileCount, required this.totalSize});
  
  String get sizeString {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

@riverpod
Future<FolderStats> folderStats(FolderStatsRef ref, String folderId) async {
  final repo = ref.watch(fileRepositoryProvider);
  
  final countRes = await repo.getFileCount(folderId);
  final sizeRes = await repo.getFolderTotalSize(folderId);
  
  // Combine results
  // If either fails, we can throw or return zero stats.
  // Using naive approach: throw on error.
  
  final count = countRes.fold((l) => throw Exception(l), (r) => r);
  final size = sizeRes.fold((l) => throw Exception(l), (r) => r);
  
  return FolderStats(fileCount: count, totalSize: size);
}
