
import 'package:blindkey_app/application/services/vault_service.dart';
import 'package:blindkey_app/application/services/trusted_time_service.dart';
import 'package:blindkey_app/application/services/ad_service.dart';
import 'package:blindkey_app/domain/repositories/file_repository.dart';
import 'package:blindkey_app/domain/repositories/folder_repository.dart';
import 'package:blindkey_app/infrastructure/encryption/cryptography_service.dart';
import 'package:blindkey_app/infrastructure/repositories/file_repository_impl.dart';
import 'package:blindkey_app/infrastructure/repositories/metadata_repository.dart';
import 'package:blindkey_app/infrastructure/auth/app_lock_service.dart';
import 'package:blindkey_app/infrastructure/storage/file_storage_service.dart';
import 'package:blindkey_app/infrastructure/storage/secure_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'providers.g.dart';

final splashFinishedProvider = StateProvider<bool>((ref) => false);

@riverpod
TrustedTimeService trustedTimeService(TrustedTimeServiceRef ref) {
  return TrustedTimeService();
}

@riverpod
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  return SecureStorageService();
}

@riverpod
AppLockService appLockService(AppLockServiceRef ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return AppLockService(storage);
}

@riverpod
FolderRepository folderRepository(FolderRepositoryRef ref) {
  return MetadataRepository();
}

@riverpod
FileStorageService fileStorageService(FileStorageServiceRef ref) {
  return FileStorageService();
}

@riverpod
MetadataRepository metadataRepository(MetadataRepositoryRef ref) {
  // Required for FileRepo
  return MetadataRepository(); 
  // Ideally single instance if it holds DB connection?
  // MetadataRepository implementation handles singleton DB via `_database` field? 
  // Wait, `MetadataRepository` logic: `Database? _database; Future<Database> get database async`.
  // If we create new instance every time, `_database` will be null, and it will try to `openDatabase` again.
  // Sqflite `openDatabase` handles multiple connections usually, but it's better to keep one instance.
  // So we should use @Riverpod(keepAlive: true)
}

// We need a singleton specific provider for the actual instance if we want to share it.
@Riverpod(keepAlive: true)
MetadataRepository sharedMetadataRepository(SharedMetadataRepositoryRef ref) {
  return MetadataRepository();
}

@riverpod
CryptographyService cryptographyService(CryptographyServiceRef ref) {
  return CryptographyService();
}

@riverpod
FileRepository fileRepository(FileRepositoryRef ref) {
  final metadataRepo = ref.watch(sharedMetadataRepositoryProvider); // Use shared!
  final storage = ref.watch(fileStorageServiceProvider);
  return FileRepositoryImpl(metadataRepo, storage);
}

@riverpod
VaultService vaultService(VaultServiceRef ref) {
  // Use shared metadata repo via other repos
  return VaultService(
    ref.watch(folderRepositoryImplProvider),
    ref.watch(fileRepositoryProvider),
    ref.watch(cryptographyServiceProvider),
    ref.watch(fileStorageServiceProvider),
    ref.watch(trustedTimeServiceProvider),
  );
}

@riverpod
FolderRepository folderRepositoryImpl(FolderRepositoryImplRef ref) {
  return ref.watch(sharedMetadataRepositoryProvider);
}

@Riverpod(keepAlive: true)
AdService adService(AdServiceRef ref) {
  final service = AdService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
}
