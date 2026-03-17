import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:blindkey_app/domain/repositories/file_repository.dart';
import 'package:blindkey_app/domain/repositories/folder_repository.dart';
import 'package:blindkey_app/infrastructure/encryption/cryptography_service.dart'; // Direct dependency for now, or via DI
import 'package:blindkey_app/infrastructure/storage/file_storage_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:blindkey_app/application/services/trusted_time_service.dart';
import 'package:blindkey_app/application/services/thumbnail_service.dart';

abstract class ExportStatus {}

class ExportProgress extends ExportStatus {
  final double progress; // 0.0 to 1.0
  final String message;
  ExportProgress(this.progress, this.message);
}

class ExportSuccess extends ExportStatus {
  final String path;
  ExportSuccess(this.path);
}

class ExportFailure extends ExportStatus {
  final String error;
  ExportFailure(this.error);
}

class VaultService {
  final FolderRepository _folderRepository;
  final FileRepository _fileRepository;
  final CryptographyService _cryptoService;
  final FileStorageService _storageService;
  final TrustedTimeService _trustedTimeService;
  final ThumbnailService _thumbnailService;

  VaultService(
    this._folderRepository,
    this._fileRepository,
    this._cryptoService,
    this._storageService,
    this._trustedTimeService,
    this._thumbnailService,
  );

  Future<Either<Failure, FolderModel>> createFolder(
    String name,
    String password,
  ) async {
    try {
      final salt = await _cryptoService.generateRandomKey().then(
        (k) => k.extractBytes(),
      );
      final key = await _cryptoService.deriveKeyFromPassword(password, salt);
      // final keyBytes = await key.extractBytes(); // Unused

      // WE ENCRYPT 'VERIFY' TO VALIDATE PASSWORD LATER
      final verificationEnc = await _cryptoService.encryptData(
        data: utf8.encode('VERIFY'),
        key: key,
      );

      return verificationEnc.fold((l) => left(l), (encryptedBytes) async {
        final folder = FolderModel(
          id: const Uuid().v4(),
          name: name,
          salt: base64Encode(salt),
          verificationHash: base64Encode(encryptedBytes),
          createdAt: DateTime.now(),
        );
        final saveResult = await _folderRepository.saveFolder(folder);
        return saveResult.fold((l) => left(l), (_) => right(folder));
      });
    } on FileSystemException catch (e) {
      return left(Failure.fileSystemError(e.message));
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Future<Either<Failure, SecretKey>> verifyPasswordAndGetKey(
    FolderModel folder,
    String password,
  ) async {
    try {
      final salt = base64Decode(folder.salt);
      final key = await _cryptoService.deriveKeyFromPassword(password, salt);

      final encryptedVerify = base64Decode(folder.verificationHash);
      final decrypted = await _cryptoService.decryptData(
        encryptedData: encryptedVerify,
        key: key,
      );

      return decrypted.fold((l) => left(const Failure.invalidPassword()), (
        data,
      ) {
        final str = utf8.decode(data);
        if (str == 'VERIFY') {
          return right(key);
        } else {
          return left(const Failure.invalidPassword());
        }
      });
    } catch (e) {
      return left(const Failure.invalidPassword());
    }
  }

  Future<Either<Failure, SecretKey>> changeFolderPassword({
    required FolderModel folder,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // 1. Verify Old Password & Get Old Key
      final oldKeyRes = await verifyPasswordAndGetKey(folder, oldPassword);
      return oldKeyRes.fold((l) => left(l), (oldKey) async {
        // 2. Generate New Salt & New Key
        final newSalt = await _cryptoService.generateRandomKey().then(
          (k) => k.extractBytes(),
        );
        final newKey = await _cryptoService.deriveKeyFromPassword(
          newPassword,
          newSalt,
        );

        // 3. Get All Files
        final filesRes = await _fileRepository.getFiles(folder.id);
        if (filesRes.isLeft()) {
          return left(const Failure.unexpected("Could not access files"));
        }
        final files = filesRes.getOrElse(() => []);

        // 4. Re-encrypt Metadata for each file
        for (final file in files) {
          // Decrypt with Old Key
          final encMeta = base64Decode(file.encryptedMetadata);
          final decRes = await _cryptoService.decryptData(
            encryptedData: encMeta,
            key: oldKey,
          );

          if (decRes.isLeft()) {
            return left(
              const Failure.unexpected(
                "Failed to decrypt file metadata during migration",
              ),
            );
          }

          final metaBytes = decRes.getOrElse(() => []);

          // Re-encrypt with New Key
          final encRes = await _cryptoService.encryptData(
            data: metaBytes,
            key: newKey,
          );

          if (encRes.isLeft()) {
            return left(
              const Failure.unexpected("Failed to re-encrypt file metadata"),
            );
          }

          final newEncMeta = encRes.getOrElse(() => []);

          // Save updated file
          final updatedFile = file.copyWith(
            encryptedMetadata: base64Encode(newEncMeta),
          );
          final saveRes = await _fileRepository.saveFileModel(updatedFile);
          if (saveRes.isLeft()) {
            return left(
              const Failure.unexpected(
                "Failed to save re-encrypted file metadata",
              ),
            );
          }
        }

        // 5. Update Folder Verification
        final verificationEnc = await _cryptoService.encryptData(
          data: utf8.encode('VERIFY'),
          key: newKey,
        );

        return verificationEnc.fold((l) => left(l), (encryptedBytes) async {
          final updatedFolder = folder.copyWith(
            salt: base64Encode(newSalt),
            verificationHash: base64Encode(encryptedBytes),
          );

          await _folderRepository.saveFolder(updatedFolder);
          return right(newKey);
        });
      });
    } on FileSystemException catch (e) {
      return left(Failure.fileSystemError(e.message));
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Stream<double> encryptAndSaveFile({
    required File originalFile,
    required String folderId,
    required SecretKey folderKey,
  }) async* {
    // This needs to be a Stream because it reports progress.
    // However, the actual return value (success) is also needed.
    // Maybe Stream<EncryptionStatus>.
    // For now, assume this yields progress 0.0 to 1.0.
    // If error, throws.

    // 1. Generate File Key (DEK)
    final fileKey = await _cryptoService.generateRandomKey();
    final fileKeyBytes = await fileKey.extractBytes();

    // 2. Encrypt the File Content (IN ISOLATE)
    final vaultPathResult = await _storageService.createEncryptedFileDir();
    if (vaultPathResult.isLeft()) throw Exception("Storage Error");
    final vaultPath = vaultPathResult.getOrElse(() => '');

    final fileId = const Uuid().v4();
    final destPath = '$vaultPath/$fileId.enc';

    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateEncryptionEntry,
      _IsolateEncryptionArgs(
        checkSendPort: receivePort.sendPort,
        inputPath: originalFile.path,
        outputPath: destPath,
        keyBytes: fileKeyBytes,
      ),
    );

    // Listen to progress
    // We need to wait for completion.
    await for (final message in receivePort) {
      if (message is double) {
        yield message;
      } else if (message == "DONE") {
        break;
      } else if (message is String && message.startsWith("ERROR")) {
        throw Exception(message);
      }
    }

    // 3. Create Metadata
    // We need to encrypt the Metadata using the Folder Key.
    // Metadata includes the DEK (`fileKeyBytes`).
    // So we are wrapping the DEK with KEK.

    // Encrypt the File Key itself?
    // Metadata contains `fileKey` string.

    final metadata = FileMetadata(
      id: fileId,
      fileName: originalFile.path.split(Platform.pathSeparator).last,
      size: await originalFile.length(),
      mimeType: _getMimeType(originalFile.path),
      encryptedFilePath: destPath,
      fileKey: base64Encode(fileKeyBytes),
      nonce:
          "", // If using stream cipher with internal nonce, or AesGcm with random nonce.
      // My isolate logic needs to return the Nonce used!
      // Updated Isolate args to return nonce.
      allowSaveToDownloads: true,
      expiryDate: null,
    );

    final metadataJson = jsonEncode(metadata.toJson());
    // Encrypt Metadata with Folder Key
    final encryptedMetadataRes = await _cryptoService.encryptData(
      data: utf8.encode(metadataJson),
      key: folderKey,
    );

    if (encryptedMetadataRes.isLeft()) {
      throw Exception("Metadata Encryption Failed");
    }
    final encryptedMetadata = encryptedMetadataRes.getOrElse(() => []);

    // 4. Generate Thumbnail (Local, unencrypted for performance)
    // We generate it BEFORE deleting the original file (if that happens later)
    await _thumbnailService.generateThumbnail(
      originalPath: originalFile.path,
      fileId: fileId,
      key: folderKey,
    );

    // 5. Save FileModel
    final fileModel = FileModel(
      id: fileId,
      folderId: folderId,
      encryptedMetadata: base64Encode(encryptedMetadata),
      encryptedPreviewPath: "", // Implement later
      expiryDate: null,
    );

    await _fileRepository.saveFileModel(fileModel);
    yield 1.0;
  }

  Stream<List<int>> decryptFileStream({
    required FileModel file,
    required SecretKey folderKey,
    DateTime? trustedNow,
  }) async* {
    // 1. Decrypt Metadata to get File Key and File Path
    final encMetadataBytes = base64Decode(file.encryptedMetadata);
    // decryptData returns Either. We strictly need the result.
    final metadataResult = await _cryptoService.decryptData(
      encryptedData: encMetadataBytes,
      key: folderKey,
    );

    if (metadataResult.isLeft()) throw Exception("Failed to decrypt metadata");
    final metadataJson = utf8.decode(metadataResult.getOrElse(() => []));
    final metadata = FileMetadata.fromJson(jsonDecode(metadataJson));

    // Check Expiry
    if (metadata.expiryDate != null) {
      DateTime now;
      if (trustedNow != null) {
        now = trustedNow;
      } else {
        try {
          now = await _trustedTimeService.getTrustedTime();
        } catch (e) {
          throw Exception(
            "Internet connection is required to verify this shared file.",
          );
        }
      }

      if (now.toUtc().isAfter(metadata.expiryDate!.toUtc())) {
        await _fileRepository.deleteFile(file.id);
        await _thumbnailService.deleteThumbnail(file.id);
        throw Exception("File has expired and has been deleted.");
      }
    }

    // 2. Get File Key (DEK)
    final dekBytes = base64Decode(metadata.fileKey);
    final dek = SecretKey(dekBytes);

    // 3. Stream Decrypt
    // We need to read the encrypted file and decrypt chunks.
    // CAUTION: We used a simplified GCM in Isolate which outputted [Block1][Block2]...
    // where Block1 includes Tag.
    // If we simply `openRead` the file, we get arbitrary chunks.
    // We must respect the block boundaries.
    // Our Isolate combined (Nonce + Ciphertext + Tag) for each chunk.
    // Size = 12 + 1024*1024 + 16.

    final blockSize = 12 + (1024 * 1024) + 16;
    final fileObj = File(metadata.encryptedFilePath);

    if (!await fileObj.exists()) throw Exception("File not found on disk");

    final stream = fileObj.openRead();

    // We need to buffer until we have a full block.
    List<int> buffer = [];
    final algorithm = AesGcm.with256bits();

    await for (final chunk in stream) {
      buffer.addAll(chunk);

      while (buffer.length >= blockSize) {
        final block = buffer.sublist(0, blockSize);
        buffer = buffer.sublist(blockSize);

        // nonce and ciphertextWithTag are extracted via SecretBox.fromConcatenation below

        // GCM: ciphertext includes tag at end?
        // `secretBox.concatenation()` puts nonce then ciphertext then tag.
        // Wait, `SecretBox.fromConcatenation` handles this if we know lengths.
        // `AesGcm` default nonce=12, tag=16.

        final secretBox = SecretBox.fromConcatenation(
          block,
          nonceLength: 12,
          macLength: 16,
        );

        final clearText = await algorithm.decrypt(secretBox, secretKey: dek);

        yield clearText;
      }
    }

    // Last block might be smaller.
    if (buffer.isNotEmpty) {
      final secretBox = SecretBox.fromConcatenation(
        buffer,
        nonceLength: 12,
        macLength: 16,
      );
      final clearText = await algorithm.decrypt(secretBox, secretKey: dek);
      yield clearText;
    }
  }

  /// Decrypts the entire file in a background isolate and returns the full bytes.
  /// Ideal for small to medium files (like most images) to prevent UI jank.
  Future<Uint8List> decryptFileCompute({
    required FileModel file,
    required SecretKey folderKey,
  }) async {
    // 1. Decrypt Metadata to get File Key and File Path
    final encMetadataBytes = base64Decode(file.encryptedMetadata);
    final metadataResult = await _cryptoService.decryptData(
      encryptedData: encMetadataBytes,
      key: folderKey,
    );

    if (metadataResult.isLeft()) throw Exception("Failed to decrypt metadata");
    final metadataJson = utf8.decode(metadataResult.getOrElse(() => []));
    final metadata = FileMetadata.fromJson(jsonDecode(metadataJson));

    final dekBytes = base64Decode(metadata.fileKey);

    return await Isolate.run(() => _backgroundDecryption(
          _IsolateDecryptionArgs(
            encryptedPath: metadata.encryptedFilePath,
            dekBytes: dekBytes,
          ),
        ));
  }

  Stream<List<int>> decryptFileRange({
    required FileModel file,
    required SecretKey folderKey,
    required int start,
    int? end,
    DateTime? trustedNow,
  }) async* {
    // 1. Decrypt Metadata
    final encMetadataBytes = base64Decode(file.encryptedMetadata);
    final metadataResult = await _cryptoService.decryptData(
      encryptedData: encMetadataBytes,
      key: folderKey,
    );

    if (metadataResult.isLeft()) throw Exception("Failed to decrypt metadata");
    final metadataJson = utf8.decode(metadataResult.getOrElse(() => []));
    final metadata = FileMetadata.fromJson(jsonDecode(metadataJson));

    // Check Expiry
    if (metadata.expiryDate != null) {
      DateTime now;
      if (trustedNow != null) {
        now = trustedNow;
      } else {
        try {
          now = await _trustedTimeService.getTrustedTime();
        } catch (e) {
          throw Exception("Internet connection is required.");
        }
      }
      if (now.toUtc().isAfter(metadata.expiryDate!.toUtc())) {
        await _fileRepository.deleteFile(file.id);
        await _thumbnailService.deleteThumbnail(file.id);
        throw Exception("File has expired.");
      }
    }

    // 2. Setup
    final dekBytes = base64Decode(metadata.fileKey);
    final dek = SecretKey(dekBytes);
    final fileObj = File(metadata.encryptedFilePath);
    if (!await fileObj.exists()) throw Exception("File not found");

    final fileSize = metadata.size;
    final effectiveEnd = end ?? (fileSize - 1);

    if (start > effectiveEnd) return;

    // 3. Calculate Chunks
    const chunkSize = 1024 * 1024;
    const overhead = 12 + 16;
    const blockSize = chunkSize + overhead;

    final startChunkIndex = start ~/ chunkSize;
    final endChunkIndex = effectiveEnd ~/ chunkSize;

    final algorithm = AesGcm.with256bits();

    final openFile = await fileObj.open();

    try {
      for (var i = startChunkIndex; i <= endChunkIndex; i++) {
        final blockOffset = i * blockSize;
        await openFile.setPosition(blockOffset);

        final block = await openFile.read(blockSize);
        if (block.isEmpty) break;

        if (block.length < overhead) throw Exception("Corrupt block");

        final secretBox = SecretBox.fromConcatenation(
          block,
          nonceLength: 12,
          macLength: 16,
        );

        final clearText = await algorithm.decrypt(secretBox, secretKey: dek);

        final chunkStartOffset = i * chunkSize;
        // final chunkEndOffset = chunkStartOffset + clearText.length - 1;

        // Calculate intersection
        final intersectStart = start > chunkStartOffset
            ? start
            : chunkStartOffset;
        final intersectEnd =
            effectiveEnd < (chunkStartOffset + clearText.length - 1)
            ? effectiveEnd
            : (chunkStartOffset + clearText.length - 1);

        if (intersectStart <= intersectEnd) {
          final relativeStart = intersectStart - chunkStartOffset;
          final relativeEnd = intersectEnd - chunkStartOffset;
          yield clearText.sublist(relativeStart, relativeEnd + 1);
        }
      }
    } finally {
      await openFile.close();
    }
  }

  Stream<ExportStatus> exportFolder({
    required FolderModel folder,
    required SecretKey key,
    required DateTime? expiry,
    required bool allowSave,
  }) async* {
    try {
      final salt = base64Decode(folder.salt);

      // 1. Get all files
      final filesRes = await _fileRepository.getFiles(folder.id);
      if (filesRes.isLeft()) {
        yield ExportFailure("Could not read files");
        return;
      }
      final files = filesRes.getOrElse(() => []);

      yield ExportProgress(0.05, "Preparing files...");

      // Get Trusted Time for Manifest 'createdAt'
      DateTime trustedNow;
      try {
        if (expiry != null) {
          trustedNow = await _trustedTimeService.getTrustedTime();
        } else {
          // Try get trusted time, fallback to device time if offline allowed (no expiry)
          try {
            trustedNow = await _trustedTimeService.getTrustedTime();
          } catch (_) {
            trustedNow = DateTime.now();
          }
        }
      } catch (e) {
        yield ExportFailure(
          "Internet connection is required to create a secure expiry timestamp.",
        );
        return;
      }

      // 2. Prepare Metadata for Isolate
      // We need to decrypt metadata here to check validity and prepare export items
      final exportItems = <_IsolateExportItem>[];
      final keyBytes = await key.extractBytes();

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final encMeta = base64Decode(file.encryptedMetadata);
        final metaRes = await _cryptoService.decryptData(
          encryptedData: encMeta,
          key: key,
        );

        if (metaRes.isRight()) {
          final metaJson = utf8.decode(metaRes.getOrElse(() => []));
          final originalMeta = FileMetadata.fromJson(jsonDecode(metaJson));

          // Check for expiry BEFORE exporting
          if (originalMeta.expiryDate != null) {
            if (trustedNow.isAfter(originalMeta.expiryDate!)) {
              // File is expired. Delete it and skip.
              await _fileRepository.deleteFile(file.id);
              await _thumbnailService.deleteThumbnail(file.id);
              continue;
            }
          }

          exportItems.add(
            _IsolateExportItem(
              id: file.id,
              originalEncryptedPath: originalMeta.encryptedFilePath,
              originalMetadataJson: metaJson,
            ),
          );
        }
      }

      final tempDir = await getTemporaryDirectory();

      // 3. Spawn Isolate
      final receivePort = ReceivePort();

      await Isolate.spawn(
        _isolateExportEntry,
        _IsolateExportArgs(
          sendPort: receivePort.sendPort,
          tempDirPath: tempDir.path,
          folderName: folder.name,
          folderId: folder.id,
          folderVerificationHash: folder.verificationHash,
          folderSalt: salt,
          folderKeyBytes: keyBytes,
          exportItems: exportItems,
          expiry: expiry,
          allowSave: allowSave,
          trustedCreatedAt: trustedNow.toIso8601String(),
        ),
      );

      // 4. Listen to Isolate
      await for (final message in receivePort) {
        if (message is ExportStatus) {
          yield message;
          if (message is ExportSuccess || message is ExportFailure) {
            break;
          }
        }
      }
    } catch (e) {
      yield ExportFailure(e.toString());
    }
  }

  Future<Either<Failure, Unit>> importBlindKey(
    String path,
    String password,
  ) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return left(const Failure.fileSystemError("File not found"));
      }

      // 1. Mandatory Internet Check
      DateTime trustedNow;
      try {
        trustedNow = await _trustedTimeService.getTrustedTime();
      } catch (e) {
        return left(
          const Failure.unexpected(
            "Internet connection is required for security verification.",
          ),
        );
      }

      // 2. Perform Native Argon2id derivation on Main Isolate for speed
      // (Background isolates often fail to bind native MethodChannels)
      final derivedSalt = await file.open().then((f) async {
        final s = await f.read(32);
        await f.close();
        return s;
      });

      final argon2 = Argon2id(
        parallelism: 1,
        memory: 65536,
        iterations: 4,
        hashLength: 32,
      );
      
      final derivedKey = await argon2.deriveKeyFromPassword(
        password: password,
        nonce: derivedSalt,
      );
      final derivedKeyBytes = await derivedKey.extractBytes();

      // 3. Spawn verification isolate for heavy ZIP processing
      final receivePort = ReceivePort();
      await Isolate.spawn(
        _isolateImportVerifyEntry,
        _IsolateImportVerifyArgs(
          sendPort: receivePort.sendPort,
          filePath: path,
          password: password,
          trustedNowIso: trustedNow.toIso8601String(),
          keyBytes: derivedKeyBytes,
          salt: derivedSalt,
        ),
      );

      final result = await receivePort.first as _IsolateImportVerifyResult;

      if (result.status != ImportResultStatus.success) {
        if (result.status == ImportResultStatus.invalidPassword) {
          return left(const Failure.invalidPassword());
        } else if (result.status == ImportResultStatus.expired) {
          return left(const Failure.fileExpired());
        } else {
          return left(Failure.unexpected(result.errorMessage ?? "Unknown error"));
        }
      }

      final map = result.manifest!;
      final salt = result.salt!;
      final key = SecretKey(result.keyBytes!);

      // 3. Import Folder (DB operation must be on main thread)
      final newFolderId = const Uuid().v4();
      final folder = FolderModel(
        id: newFolderId,
        name: map['name'] + " (Imported)",
        salt: base64Encode(salt),
        verificationHash: map['verificationHash'],
        createdAt: trustedNow,
        allowSave: map['allowSave'] ?? true,
      );

      await _folderRepository.saveFolder(folder);

      // 4. Import Files
      final filesList = (map['files'] as List)
          .map((e) => FileMetadata.fromJson(e))
          .toList();

      final vaultPathRes = await _storageService.createEncryptedFileDir();
      final vaultPath = vaultPathRes.getOrElse(() => '');

      // Re-open archive in isolate or here? 
      // Since we already verified, we can do the heavy extraction here OR in another isolate.
      // To keep it simple and responsive, let's do the extraction in the main thread for now, 
      // as it's mostly I/O bound and we already passed the "wait time for error" bottleneck.
      // However, to be fully optimized, we should stream extraction too.
      
      // We need the archive again.
      final inputStream = InputFileStream(path);
      inputStream.skip(32); // Skip salt
      final archive = ZipDecoder().decodeBuffer(inputStream);

      for (final meta in filesList) {
        if (meta.expiryDate != null &&
            trustedNow.toUtc().isAfter(meta.expiryDate!.toUtc())) {
          continue;
        }

        final zipFile = archive.findFile(meta.encryptedFilePath);
        if (zipFile != null) {
          final newFileId = const Uuid().v4();
          final newPath = '$vaultPath/$newFileId.enc';

          // EFFICIENT WRITE: Stream from ZIP to Disk
          final outputStream = OutputFileStream(newPath);
          zipFile.writeContent(outputStream);
          await outputStream.close();

          // Update Metadata
          final newMeta = meta.copyWith(
            id: newFileId,
            encryptedFilePath: newPath,
          );

          final metaJson = jsonEncode(newMeta.toJson());
          final encMetaRes = await _cryptoService.encryptData(
            data: utf8.encode(metaJson),
            key: key,
          );
          final encMeta = encMetaRes.getOrElse(() => []);

          final fileModel = FileModel(
            id: newFileId,
            folderId: newFolderId,
            encryptedMetadata: base64Encode(encMeta),
            encryptedPreviewPath: "",
            expiryDate: meta.expiryDate,
          );

          await _fileRepository.saveFileModel(fileModel);
        }
      }

      await inputStream.close();
      return right(unit);
    } catch (e) {
      if (e.toString().contains("Internet") ||
          e.toString().contains("SocketException")) {
        return left(
          const Failure.unexpected("Internet connection is required."),
        );
      }
      return left(Failure.unexpected(e.toString()));
    }
  }


  Future<Either<Failure, FileMetadata>> decryptMetadata({
    required FileModel file,
    required SecretKey folderKey,
    DateTime? trustedNow,
  }) async {
    try {
      final encMetadataBytes = base64Decode(file.encryptedMetadata);
      final metadataResult = await _cryptoService.decryptData(
        encryptedData: encMetadataBytes,
        key: folderKey,
      );

      return await metadataResult.fold((l) => left(l), (bytes) async {
        try {
          final metadataJson = utf8.decode(bytes);
          final metadata = FileMetadata.fromJson(jsonDecode(metadataJson));

          if (metadata.expiryDate != null) {
            DateTime now;
            if (trustedNow != null) {
              now = trustedNow;
            } else {
              try {
                now = await _trustedTimeService.getTrustedTime();
              } catch (e) {
                return left(
                  const Failure.unexpected(
                    "Internet connection is required for security verification.",
                  ),
                );
              }
            }

            if (now.toUtc().isAfter(metadata.expiryDate!.toUtc())) {
              // Expired
              await _fileRepository.deleteFile(file.id);
              return left(const Failure.fileExpired());
            }
          }

          return right(metadata);
        } catch (e) {
          return left(Failure.unexpected("Metadata JSON error: $e"));
        }
      });
    } catch (e) {
      return left(Failure.unexpected("Metadata access error: $e"));
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
      case 'm4v':
      case 'mov':
        return 'video/mp4'; 
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'txt':
      case 'css':
      case 'xml':
      case 'json':
      case 'yaml':
      case 'yml':
      case 'dart':
      case 'md':
      case 'csv':
        return 'text/plain';
      case 'html': 
        return 'text/html';
      case 'svg':
        return 'image/svg+xml';
      case 'tif':
      case 'tiff':
        return 'image/tiff'; 
      case 'bmp':
        return 'image/bmp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'wma':
      case 'flac':
      case 'm4a':
        return 'audio/mpeg'; 
      default:
        return 'application/octet-stream';
    }
  }

  Stream<double> importFilesBulk({
    required List<File> files,
    required String folderId,
    required SecretKey folderKey,
  }) async* {
    if (files.isEmpty) return;

    final items = <_IsolateBulkEncryptionItem>[];
    final fileModels = <int, FileModel>{};
    for (var i = 0; i < files.length; i++) {
      final originalFile = files[i];
      final fileKey = await _cryptoService.generateRandomKey();
      final fileKeyBytes = await fileKey.extractBytes();

      final vaultPathResult = await _storageService.createEncryptedFileDir();
      if (vaultPathResult.isLeft()) throw Exception("Storage Error");
      final vaultPath = vaultPathResult.getOrElse(() => '');

      final fileId = const Uuid().v4();
      final destPath = '$vaultPath/$fileId.enc';

      items.add(
        _IsolateBulkEncryptionItem(
          index: i,
          inputPath: originalFile.path,
          outputPath: destPath,
          keyBytes: fileKeyBytes,
        ),
      );

      final metadata = FileMetadata(
        id: fileId,
        fileName: originalFile.path.split(Platform.pathSeparator).last,
        size: await originalFile.length(),
        mimeType: _getMimeType(originalFile.path),
        encryptedFilePath: destPath,
        fileKey: base64Encode(fileKeyBytes),
        nonce: "",
        allowSaveToDownloads: true,
        expiryDate: null,
      );

      final metadataJson = jsonEncode(metadata.toJson());
      final encryptedMetadataRes = await _cryptoService.encryptData(
        data: utf8.encode(metadataJson),
        key: folderKey,
      );
      if (encryptedMetadataRes.isLeft()) continue;
      final encryptedMetadata = encryptedMetadataRes.getOrElse(() => []);

      fileModels[i] = FileModel(
        id: fileId,
        folderId: folderId,
        encryptedMetadata: base64Encode(encryptedMetadata),
        encryptedPreviewPath: "",
        expiryDate: null,
      );
    }

    final receivePort = ReceivePort();
    await Isolate.spawn(
      _isolateBulkEncryptionEntry,
      _IsolateBulkEncryptionArgs(sendPort: receivePort.sendPort, items: items),
    );

    int completed = 0;
    await for (final message in receivePort) {
      if (message is int) {
        final index = message;
        if (fileModels.containsKey(index)) {
          final fileModel = fileModels[index]!;
          await _fileRepository.saveFileModel(fileModel);

          await _thumbnailService.generateThumbnail(
            originalPath: files[index].path,
            fileId: fileModel.id,
            key: folderKey,
          );
        }
        completed++;
        yield completed / files.length;
      } else if (message == "DONE") {
        break;
      } else if (message is String && message.startsWith("ERROR")) {
        print("Bulk Import Error: $message");
      }
    }
  }
} // Properly closing VaultService

class _IsolateBulkEncryptionItem {
  final int index;
  final String inputPath;
  final String outputPath;
  final List<int> keyBytes;

  _IsolateBulkEncryptionItem({
    required this.index,
    required this.inputPath,
    required this.outputPath,
    required this.keyBytes,
  });
}

class _IsolateBulkEncryptionArgs {
  final SendPort sendPort;
  final List<_IsolateBulkEncryptionItem> items;

  _IsolateBulkEncryptionArgs({required this.sendPort, required this.items});
}

Future<void> _isolateBulkEncryptionEntry(
  _IsolateBulkEncryptionArgs args,
) async {
  final algorithm = AesGcm.with256bits();
  final chunkSize = 1024 * 1024; // 1MB

  for (final item in args.items) {
    try {
      final inFile = File(item.inputPath);
      final outFile = File(item.outputPath);

      // Ensure file exists
      if (!inFile.existsSync()) {
        args.sendPort.send("ERROR:${item.index}:File not found");
        continue;
      }

      final inStream = inFile.openRead();
      final outSink = outFile.openWrite();
      final secretKey = SecretKey(item.keyBytes);

      int chunkIndex = 0;
      List<int> buffer = [];

      await for (final chunk in inStream) {
        buffer.addAll(chunk);
        while (buffer.length >= chunkSize) {
          final toProcess = buffer.sublist(0, chunkSize);
          buffer = buffer.sublist(chunkSize);

          final nonce = List<int>.filled(12, 0);
          var tempIndex = chunkIndex;
          for (var i = 11; i >= 8; i--) {
            nonce[i] = tempIndex & 0xFF;
            tempIndex >>= 8;
          }

          final secretBox = await algorithm.encrypt(
            toProcess,
            secretKey: secretKey,
            nonce: nonce,
          );

          outSink.add(secretBox.concatenation());
          chunkIndex++;
        }
      }

      if (buffer.isNotEmpty) {
        final nonce = List<int>.filled(12, 0);
        var tempIndex = chunkIndex;
        for (var i = 11; i >= 8; i--) {
          nonce[i] = tempIndex & 0xFF;
          tempIndex >>= 8;
        }

        final secretBox = await algorithm.encrypt(
          buffer,
          secretKey: secretKey,
          nonce: nonce,
        );
        outSink.add(secretBox.concatenation());
      }

      await outSink.flush();
      await outSink.close();

      args.sendPort.send(item.index); // Success, send index back
    } catch (e) {
      args.sendPort.send("ERROR:${item.index}:$e");
    }
  }
  args.sendPort.send("DONE");
}

class _IsolateEncryptionArgs {
  final SendPort checkSendPort;
  final String inputPath;
  final String outputPath;
  final List<int> keyBytes;

  _IsolateEncryptionArgs({
    required this.checkSendPort,
    required this.inputPath,
    required this.outputPath,
    required this.keyBytes,
  });
}

Future<void> _isolateEncryptionEntry(_IsolateEncryptionArgs args) async {
  try {
    final inFile = File(args.inputPath);
    final outFile = File(args.outputPath);
    final inStream = inFile.openRead();
    final outSink = outFile.openWrite();

    final totalSize = await inFile.length();
    int processed = 0;

    // Use AES-GCM for chunks?
    // Or AES-CTR (Counter mode).
    // CTR is best for streaming without expansion issues (ciphertext size = plaintext size).
    // GCM adds tags.
    // Let's use `cryptography` package inside isolate.
    // Note: We need to import `cryptography` here which is fine.

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(args.keyBytes);

    // For GCM streaming: We can't easily stream one GCM block for huge files.
    // We should chunk it. e.g. 1MB blocks.
    // Output format: [Nonce (12)][Block1 (Size+Tag)][Block2]...
    // Or just [Nonce] and then implicit blocks.
    // Simpler: Use a unique Nonce for each block: Nonce + BlockIndex.
    // But GCM tag is 16 bytes.
    // So 1MB plaintext -> 1MB + 16 bytes ciphertext.

    final chunkSize = 1024 * 1024; // 1MB
    int chunkIndex = 0;

    // Listen to stream and buffer chunks
    List<int> buffer = [];

    await for (final chunk in inStream) {
      buffer.addAll(chunk);
      while (buffer.length >= chunkSize) {
        final toProcess = buffer.sublist(0, chunkSize);
        buffer = buffer.sublist(chunkSize);

        // Encrypt chunk
        // Construct nonce: 12 bytes. Last 4 bytes = chunkIndex.
        // Or random nonce for first, increment for next?
        // Standard GCM 96-bit nonce.
        // DANGER: Reusing nonce with same key is FATAL.
        // Since `fileKey` is random per file, we can use Counter for nonce.
        // Nonce = 0, 1, 2...

        final nonce = List<int>.filled(12, 0);
        // encode chunkIndex into nonce (Big Endian)
        var tempIndex = chunkIndex;
        for (var i = 11; i >= 8; i--) {
          nonce[i] = tempIndex & 0xFF;
          tempIndex >>= 8;
        }

        final secretBox = await algorithm.encrypt(
          toProcess,
          secretKey: secretKey,
          nonce: nonce,
        );

        outSink.add(secretBox.concatenation());

        processed += toProcess.length;
        args.checkSendPort.send(processed / totalSize);

        chunkIndex++;
      }
    }

    // Final chunk
    if (buffer.isNotEmpty) {
      final nonce = List<int>.filled(12, 0);
      var tempIndex = chunkIndex;
      for (var i = 11; i >= 8; i--) {
        nonce[i] = tempIndex & 0xFF;
        tempIndex >>= 8;
      }

      final secretBox = await algorithm.encrypt(
        buffer,
        secretKey: secretKey,
        nonce: nonce,
      );
      outSink.add(secretBox.concatenation());
      processed += buffer.length;
      args.checkSendPort.send(1.0);
    }

    await outSink.flush();
    await outSink.close();

    args.checkSendPort.send("DONE");
  } catch (e) {
    args.checkSendPort.send("ERROR: $e");
  }
}

class _IsolateExportItem {
  final String id;
  final String originalEncryptedPath;
  final String originalMetadataJson;

  _IsolateExportItem({
    required this.id,
    required this.originalEncryptedPath,
    required this.originalMetadataJson,
  });
}

class _IsolateExportArgs {
  final SendPort sendPort;
  final String tempDirPath;
  final String folderName;
  final String folderId;
  final String folderVerificationHash;
  final List<int> folderSalt;
  final List<int> folderKeyBytes;
  final List<_IsolateExportItem> exportItems;
  final DateTime? expiry;
  final bool allowSave;
  final String trustedCreatedAt;

  _IsolateExportArgs({
    required this.sendPort,
    required this.tempDirPath,
    required this.folderName,
    required this.folderId,
    required this.folderVerificationHash,
    required this.folderSalt,
    required this.folderKeyBytes,
    required this.exportItems,
    required this.expiry,
    required this.allowSave,
    required this.trustedCreatedAt,
  });
}

Future<void> _isolateExportEntry(_IsolateExportArgs args) async {
  Directory? stagingDir;
  try {
    args.sendPort.send(ExportProgress(0.1, "Initializing export..."));

    // Create staging area
    stagingDir = Directory(
      '${args.tempDirPath}/export_staging_${const Uuid().v4()}',
    );
    await stagingDir.create();

    final zipPath = '${stagingDir.path}/archive.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);

    final exportMetadataList = <FileMetadata>[];

    // Process Files
    final totalFiles = args.exportItems.length;

    for (var i = 0; i < totalFiles; i++) {
      final item = args.exportItems[i];

      // Report Progress
      // Range 0.1 to 0.8
      final progress = 0.1 + ((i / totalFiles) * 0.7);
      args.sendPort.send(
        ExportProgress(progress, "Processing file ${i + 1}/$totalFiles..."),
      );

      final originalMeta = FileMetadata.fromJson(
        jsonDecode(item.originalMetadataJson),
      );

      // Create Export Metadata
      final exportMeta = originalMeta.copyWith(
        expiryDate: args.expiry,
        allowSaveToDownloads: args.allowSave,
        encryptedFilePath: 'files/${item.id}.enc',
      );
      exportMetadataList.add(exportMeta);

      // Add physical file to ZIP
      final fileObj = File(item.originalEncryptedPath);
      if (await fileObj.exists()) {
        // We are moving ENCRYPTED file 'as-is' into the zip.
        // This is efficient (no re-encryption).
        // Use Store (level 0) because encrypted data is not compressible.
        // This prevents high memory usage from Deflate and speeds up export.
        await encoder.addFile(fileObj, 'files/${item.id}.enc', 0);
      }
    }

    args.sendPort.send(ExportProgress(0.85, "Finalizing package..."));

    // Create Manifest
    final manifest = {
      'id': args.folderId,
      'name': args.folderName,
      'verificationHash': args.folderVerificationHash,
      'files': exportMetadataList.map((e) => e.toJson()).toList(),
      'expiryDate': args.expiry?.toIso8601String(),
      'allowSave': args.allowSave,
      'createdAt': args.trustedCreatedAt,
    };

    final manifestJson = jsonEncode(manifest);

    // Encrypt Manifest manually using AesGcm
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(args.folderKeyBytes);
    final nonce = algorithm.newNonce(); // Random nonce

    final secretBox = await algorithm.encrypt(
      utf8.encode(manifestJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    final encManifest = secretBox.concatenation();

    // Write manifest to temp file then add to zip
    final manifestFile = File('${stagingDir.path}/manifest.enc');
    await manifestFile.writeAsBytes(encManifest);
    await encoder.addFile(manifestFile, 'manifest.enc');

    encoder.close();

    args.sendPort.send(ExportProgress(0.9, "Writing .blindkey file..."));

    // Create Final .blindkey file [Salt][ZipFileContent]
    final finalPath = '${args.tempDirPath}/${args.folderName}.blindkey';
    final finalFile = File(finalPath);
    final sink = finalFile.openWrite();

    // Write Salt
    sink.add(args.folderSalt);

    // Stream Zip Content
    final zipFile = File(zipPath);
    await sink.addStream(zipFile.openRead());

    await sink.flush();
    await sink.close();

    args.sendPort.send(ExportSuccess(finalPath));
  } catch (e) {
    args.sendPort.send(ExportFailure(e.toString()));
  } finally {
    if (stagingDir != null && await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
  }
}

class _IsolateDecryptionArgs {
  final String encryptedPath;
  final List<int> dekBytes;
  _IsolateDecryptionArgs({required this.encryptedPath, required this.dekBytes});
}

Future<Uint8List> _backgroundDecryption(_IsolateDecryptionArgs args) async {
  final file = File(args.encryptedPath);
  if (!file.existsSync()) throw Exception("File not found");

  final algorithm = AesGcm.with256bits();
  final dek = SecretKey(args.dekBytes);
  final blockSize = 12 + (1024 * 1024) + 16;
  final builder = BytesBuilder();

  final stream = file.openRead();
  List<int> buffer = [];

  await for (final chunk in stream) {
    buffer.addAll(chunk);
    while (buffer.length >= blockSize) {
      final block = buffer.sublist(0, blockSize);
      buffer = buffer.sublist(blockSize);

      final secretBox = SecretBox.fromConcatenation(
        block,
        nonceLength: 12,
        macLength: 16,
      );

      final clearText = await algorithm.decrypt(secretBox, secretKey: dek);
      builder.add(clearText);
    }
  }

  if (buffer.isNotEmpty) {
    final secretBox = SecretBox.fromConcatenation(
      buffer,
      nonceLength: 12,
      macLength: 16,
    );
    final clearText = await algorithm.decrypt(secretBox, secretKey: dek);
    builder.add(clearText);
  }

  return builder.takeBytes();
}

enum ImportResultStatus { success, invalidPassword, expired, error }

class _IsolateImportVerifyResult {
  final ImportResultStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? manifest;
  final List<int>? salt;
  final List<int>? keyBytes;

  _IsolateImportVerifyResult({
    required this.status,
    this.errorMessage,
    this.manifest,
    this.salt,
    this.keyBytes,
  });
}

class _IsolateImportVerifyArgs {
  final SendPort sendPort;
  final String filePath;
  final String password;
  final String trustedNowIso;

  final List<int> keyBytes;
  final List<int> salt;

  _IsolateImportVerifyArgs({
    required this.sendPort,
    required this.filePath,
    required this.password,
    required this.trustedNowIso,
    required this.keyBytes,
    required this.salt,
  });
}

Future<void> _isolateImportVerifyEntry(_IsolateImportVerifyArgs args) async {
  try {
    final salt = args.salt;
    final keyBytes = args.keyBytes;
    final secretKey = SecretKey(keyBytes);

    final trustedNow = DateTime.parse(args.trustedNowIso);

    final rawStream = InputFileStream(args.filePath);
    final inputStream = InputFileStream.clone(rawStream, position: 32);

    final archive = ZipDecoder().decodeBuffer(inputStream);

    // 3. Decrypt Manifest
    final manifestFile = archive.findFile('manifest.enc');
    if (manifestFile == null) {
      await inputStream.close();
      args.sendPort.send(_IsolateImportVerifyResult(
        status: ImportResultStatus.error,
        errorMessage: "Invalid blindkey file structure",
      ));
      return;
    }

    final encManifest = manifestFile.content as List<int>;
    final algorithm = AesGcm.with256bits();
    
    try {
      final secretBox = SecretBox.fromConcatenation(
        encManifest,
        nonceLength: algorithm.nonceLength,
        macLength: algorithm.macAlgorithm.macLength,
      );
      final clearBytes = await algorithm.decrypt(secretBox, secretKey: secretKey);
      final json = utf8.decode(clearBytes);
      final map = jsonDecode(json);

      // Check Expiry
      if (map.containsKey('expiryDate') && map['expiryDate'] != null) {
        final expiryIso = map['expiryDate'] as String;
        final expiryDate = DateTime.tryParse(expiryIso);
        if (expiryDate != null && trustedNow.toUtc().isAfter(expiryDate.toUtc())) {
          await inputStream.close();
          args.sendPort.send(_IsolateImportVerifyResult(status: ImportResultStatus.expired));
          return;
        }
      }

      await inputStream.close();
      args.sendPort.send(_IsolateImportVerifyResult(
        status: ImportResultStatus.success,
        manifest: map,
        salt: salt,
        keyBytes: keyBytes,
      ));
    } catch (e) {
      await inputStream.close();
      args.sendPort.send(_IsolateImportVerifyResult(status: ImportResultStatus.invalidPassword));
    }
  } catch (e) {
    args.sendPort.send(_IsolateImportVerifyResult(
      status: ImportResultStatus.error,
      errorMessage: e.toString(),
    ));
  }
}
