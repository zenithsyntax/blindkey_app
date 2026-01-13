import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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

  VaultService(
    this._folderRepository,
    this._fileRepository,
    this._cryptoService,
    this._storageService,
    this._trustedTimeService,
  );

  Future<Either<Failure, Unit>> createFolder(
    String name,
    String password,
  ) async {
    try {
      final salt = await _cryptoService.generateRandomKey().then(
        (k) => k.extractBytes(),
      );
      final key = await _cryptoService.deriveKeyFromPassword(password, salt);
      final keyBytes = await key.extractBytes();

      // We store HASH of the key to verify password.
      // Actually, standard is: Store Salt.
      // On Login: Derive Key(Pass, Salt).
      // To Verify: We need a "Verification Hash".
      // Usually, we verify by successfully decrypting a known value (e.g. metadata).
      // Or we store Hash(Key).
      // Let's store Hash(Key) as verificationHash.
      // But we shouldn't store Hash(Key) directly if Key is used for encryption?
      // Better: Derive TWO keys from password? Or Key and Auth Key?
      // Simple approach: Store Hash(Password, Salt). Use Key(Password, Salt) for encryption.
      // Wait, Argon2 produces a key.
      // If we use the SAME parameters, we get the same 32 bytes.
      // If we store Hash(OutputBytes), and attacker gets DB, they have Hash(Key).
      // If they crack Hash(Key), they have Key.
      // So verificationHash should be a SEPARATE derivation or hash of the key.
      // Let's just use a known encrypted string.
      // "FolderModel" has `verificationHash`.
      // Let's treat `verificationHash` as: Encrypt("BlindKey", Key).
      // If we can decrypt it and get "BlindKey", password is correct.

      // IMPLEMENTATION:
      // 1. Generate Salt.
      // 2. Derive Key.
      // 3. Encrypt string "VERIFY" with Key.
      // 4. Store Salt and EncryptedString.

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
        return await _folderRepository.saveFolder(folder);
      });
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
      return oldKeyRes.fold(
        (l) => left(l),
        (oldKey) async {
          // 2. Generate New Salt & New Key
          final newSalt = await _cryptoService.generateRandomKey().then((k) => k.extractBytes());
          final newKey = await _cryptoService.deriveKeyFromPassword(newPassword, newSalt);

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
               return left(const Failure.unexpected("Failed to decrypt file metadata during migration"));
            }
            
            final metaBytes = decRes.getOrElse(() => []);
            
            // Re-encrypt with New Key
            final encRes = await _cryptoService.encryptData(
               data: metaBytes,
               key: newKey,
            );
            
            if (encRes.isLeft()) {
               return left(const Failure.unexpected("Failed to re-encrypt file metadata"));
            }
            
            final newEncMeta = encRes.getOrElse(() => []);
            
            // Save updated file
            final updatedFile = file.copyWith(
               encryptedMetadata: base64Encode(newEncMeta),
            );
            final saveRes = await _fileRepository.saveFileModel(updatedFile);
            if (saveRes.isLeft()) {
               return left(const Failure.unexpected("Failed to save re-encrypted file metadata"));
            }
          }

          // 5. Update Folder Verification
          final verificationEnc = await _cryptoService.encryptData(
            data: utf8.encode('VERIFY'),
            key: newKey,
          );
          
          return verificationEnc.fold(
             (l) => left(l),
             (encryptedBytes) async {
               final updatedFolder = folder.copyWith(
                 salt: base64Encode(newSalt),
                 verificationHash: base64Encode(encryptedBytes),
               );
               
               await _folderRepository.saveFolder(updatedFolder);
               return right(newKey);
             }
          );
        },
      );
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

    if (encryptedMetadataRes.isLeft())
      throw Exception("Metadata Encryption Failed");
    final encryptedMetadata = encryptedMetadataRes.getOrElse(() => []);

    // 4. Generate Thumbnail (if applicable) -- Placeholder
    // requirement: "Thumbnails must be generated efficiently"
    // We can use `video_thumbnail` on `originalFile` (plaintext) BEFORE it is deleted (if user deletes it).
    // Then encrypt the thumbnail.
    // For now, leaving empty string.

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
           throw Exception("Internet connection is required to verify this shared file.");
         }
       }
       
       if (now.toUtc().isAfter(metadata.expiryDate!.toUtc())) {
          await _fileRepository.deleteFile(file.id);
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

        final nonce = block.sublist(0, 12);
        final ciphertextWithTag = block.sublist(12);

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
         yield ExportFailure("Internet connection is required to create a secure expiry timestamp.");
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
    File? tempZipFile;
    try {
      final file = File(path);
      if (!await file.exists())
        return left(const Failure.fileSystemError("File not found"));

      // 1. Mandatory Internet Check
      DateTime trustedNow;
      try {
        trustedNow = await _trustedTimeService.getTrustedTime();
      } catch (e) {
        return left(const Failure.unexpected("Internet connection is required for security verification."));
      }

      final fileLen = await file.length();
      if (fileLen < 32 + 22) { // 32 byte salt + min zip size
        return left(const Failure.unexpected("Invalid file"));
      }

      // 2. Read Salt (First 32 bytes)
      final saltBytes = await file.openRead(0, 32).first;
      // .first might not give full 32 bytes if chunked differently, but typically does for small read.
      // Safer: read specific amount.
      final openFile = await file.open();
      final salt = await openFile.read(32);
      await openFile.close();
      
      if (salt.length != 32) return left(const Failure.unexpected("Invalid file header"));

      // 3. Extract ZIP portion to Temp File
      // We cannot read the ZIP directly from offset 32 because ZipDecoder expects 0-based offsets.
      // Copying the ZIP stream to a temporary file allows efficient random access without RAM overhead.
      final tempDir = await getTemporaryDirectory();
      final tempZipPath = '${tempDir.path}/import_${const Uuid().v4()}.zip';
      tempZipFile = File(tempZipPath);
      
      // Stream copy from offset 32 to temp file
      final zipSink = tempZipFile.openWrite();
      await file.openRead(32).pipe(zipSink); // pipes stream to sink and closes sink
      
      // 4. Decode ZIP from Temp File (Disk-based)
      final inputStream = InputFileStream(tempZipPath);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      // 5. Derive Key
      final key = await _cryptoService.deriveKeyFromPassword(password, salt);

      // 6. Manifest
      final manifestFile = archive.findFile('manifest.enc');
      if (manifestFile == null) {
        await inputStream.close();
        return left(const Failure.unexpected("Invalid blindkey file structure"));
      }

      // Manifest is small, safe to load into memory
      final encManifest = manifestFile.content as List<int>;
      final decManifestRes = await _cryptoService.decryptData(
        encryptedData: encManifest,
        key: key,
      );

      return await decManifestRes.fold(
        (l) async {
          await inputStream.close();
          return left(const Failure.invalidPassword());
        },
        (clearBytes) async {
          final json = utf8.decode(clearBytes);
          final map = jsonDecode(json);

          // Check Global Expiry
          if (map.containsKey('expiryDate') && map['expiryDate'] != null) {
            final expiryIso = map['expiryDate'] as String;
            final expiryDate = DateTime.tryParse(expiryIso);
            if (expiryDate != null && trustedNow.toUtc().isAfter(expiryDate.toUtc())) {
              await inputStream.close();
              return left(const Failure.fileExpired());
            }
          }

          // Import Folder
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

          // Import Files
          final filesList = (map['files'] as List)
              .map((e) => FileMetadata.fromJson(e))
              .toList();
          
          final vaultPathRes = await _storageService.createEncryptedFileDir();
          final vaultPath = vaultPathRes.getOrElse(() => '');

          for (final meta in filesList) {
             if (meta.expiryDate != null && trustedNow.toUtc().isAfter(meta.expiryDate!.toUtc())) {
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
        },
      );
    } catch (e) {
      if (e.toString().contains("Internet")) {
         return left(const Failure.unexpected("Internet connection is required."));
      }
      return left(Failure.unexpected(e.toString()));
    } finally {
      // Cleanup Temp Zip
      if (tempZipFile != null && await tempZipFile.exists()) {
        try {
          await tempZipFile.delete();
        } catch (_) {}
      }
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
                 return left(const Failure.unexpected("Internet connection is required for security verification."));
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
        return 'video/mp4'; // basic mapping
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
      case 'html': // Special handling maybe?
        return 'text/html';
      case 'svg':
        return 'image/svg+xml';
      case 'tif':
      case 'tiff':
        return 'image/tiff'; // Not fully supported by Flutter Image, may need conversion or open external
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
        return 'audio/mpeg'; // Generic audio
      default:
        return 'application/octet-stream';
    }
  }
} // Closed VaultService

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
    final nonce = await algorithm.newNonce(); // Random nonce

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
