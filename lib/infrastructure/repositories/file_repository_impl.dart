import 'dart:io' as io;
import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/repositories/file_repository.dart';
import 'package:blindkey_app/infrastructure/repositories/metadata_repository.dart';
import 'package:blindkey_app/infrastructure/storage/file_storage_service.dart';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';

class FileRepositoryImpl implements FileRepository {
  final MetadataRepository metadataRepository;
  final FileStorageService fileStorageService;

  FileRepositoryImpl(this.metadataRepository, this.fileStorageService);

  @override
  Future<Either<Failure, Unit>> deleteFile(String fileId) async {
    // We need to get the file first to know its path?
    // Actually, physically deleting the file is one thing. Deleting metadata is another.
    // The FileModel stores `encryptedMetadata` but `encryptedFilePath` is INSIDE that metadata.
    // So we can't delete the physical file without decrypting the metadata first?
    // Wait, `FileModel` has `encryptedMetadata`. `FileMetadata` has `encryptedFilePath`.
    // This creates a catch-22: We cannot delete the physical file if we can't decrypt the metadata
    // to find where it is.
    // UNLESS we store the physical path in `FileModel` too (but that leaks info?).
    // Or we use a deterministic path ID. e.g. `vault/{fileId}.enc`.
    // Yes, using deterministic paths simplifies this.
    // Let's assume `vault/{fileId}.enc` and `vault/{fileId}_thumb.enc`.

    try {
      final db = await metadataRepository.database;

      // Delete physical files (using deterministic paths)
      final vaultPath = await fileStorageService.createEncryptedFileDir();
      vaultPath.fold(
        (l) => null, // logging
        (dir) async {
          await fileStorageService.deleteFile('$dir/$fileId.enc');
          await fileStorageService.deleteFile('$dir/${fileId}_thumb.enc');
        },
      );

      // Delete from DB
      await db.delete('files', where: 'id = ?', whereArgs: [fileId]);

      return right(unit);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FileMetadata>> getFileMetadata({
    required FileModel file,
    required String folderKey,
  }) {
    // This requires decryption of metadata.
    // Repository shouldn't do decryption logic?
    // This belongs in Application Service.
    // The Interface `getFileMetadata` implies retrieval.
    // Let's implement this later or stub it.
    // Actually, this interface method should PROBABLY just return the raw FileModel
    // and let the Service decrypt it.
    // But `FileRepository.getFiles` returns `List<FileModel>`.
    // The `getFileMetadata` helper seems like a Service method.
    return Future.value(
      left(
        const Failure.unexpected('Use EncryptionService to decrypt metadata'),
      ),
    );
  }

  @override
  Future<Either<Failure, List<FileModel>>> getFiles(
    String folderId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await metadataRepository.database;
      final maps = await db.query(
        'files',
        where: 'folderId = ?',
        whereArgs: [folderId],
        limit: limit,
        offset: offset,
        orderBy:
            'rowid DESC', // or createdAt if available, matching file list order
      );
      return right(maps.map((e) => FileModel.fromJson(e)).toList());
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FileModel>> saveFileEncrypted({
    required String folderId,
    required FileMetadata metadata,
    required String folderKey,
  }) {
    // This again mixes concerns. Repository shouldn't be Encrypting.
    // It should be `saveFile(FileModel)`.
    // I will stub this and rely on `saveFileModel`.
    return Future.value(
      left(const Failure.unexpected('Refactor: Use saveFileModel')),
    );
  }

  // Custom method matching Clean Architecture better
  Future<Either<Failure, Unit>> saveFileModel(FileModel file) async {
    try {
      final db = await metadataRepository.database;
      await db.insert(
        'files',
        file.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return right(unit);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getFolderTotalSize(String folderId) async {
    try {
      final db = await metadataRepository.database;
      final ids = await db.query(
        'files',
        columns: ['id'],
        where: 'folderId = ?',
        whereArgs: [folderId],
      );

      final vaultPathRes = await fileStorageService.createEncryptedFileDir();
      return vaultPathRes.fold((Failure l) => left(l), (dir) async {
        int totalSize = 0;
        for (final row in ids) {
          final id = row['id'] as String;
          // Use aliased io.File to ensure correct type
          final file = io.File('$dir/$id.enc');
          if (await file.exists()) {
            final len = await file.length();
            totalSize += len;
          }
        }
        return right(totalSize);
      });
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getFileCount(String folderId) async {
    try {
      final db = await metadataRepository.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM files WHERE folderId = ?',
        [folderId],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return right(count);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FileModel>>> getExpiredFiles(DateTime now) async {
    try {
      final db = await metadataRepository.database;
      // Fetch all files that have an expiry date
      final maps = await db.query('files', where: 'expiryDate IS NOT NULL');

      final allFiles = maps.map((e) => FileModel.fromJson(e)).toList();

      // Filter in Dart to ensure correct DateTime comparison
      final expiredFiles = allFiles.where((file) {
        if (file.expiryDate == null) return false;
        return file.expiryDate!.isBefore(now);
      }).toList();

      return right(expiredFiles);
    } catch (e) {
      return left(Failure.databaseError(e.toString()));
    }
  }
}
