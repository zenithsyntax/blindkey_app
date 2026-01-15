import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cryptography/cryptography.dart';

class ThumbnailService {
  final _algorithm = AesGcm.with256bits();

  Future<String> get _thumbnailsPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'thumbnails'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Retrieves and decrypts the thumbnail. Returns raw image bytes.
  Future<Uint8List?> getThumbnail({
    required String fileId,
    required SecretKey key,
  }) async {
    try {
      final dirPath = await _thumbnailsPath;
      final file = File(
        p.join(dirPath, '$fileId.enc'),
      ); // Changed extension to .enc
      if (!await file.exists()) return null;

      final encryptedBytes = await file.readAsBytes();

      // Decrypt
      final secretBox = SecretBox.fromConcatenation(
        encryptedBytes,
        nonceLength: 12,
        macLength: 16,
      );

      final clearText = await _algorithm.decrypt(secretBox, secretKey: key);

      return Uint8List.fromList(clearText);
    } catch (e) {
      print('ThumbnailService: Decryption error: $e');
      return null;
    }
  }

  Future<void> generateThumbnail({
    required String originalPath,
    required String fileId,
    required SecretKey key,
  }) async {
    try {
      // Check if file exists before starting isolate
      final originalFile = File(originalPath);
      if (!originalFile.existsSync()) return;

      final dirPath = await _thumbnailsPath;
      final destPath = p.join(dirPath, '$fileId.enc');
      final destFile = File(destPath);

      // If already exists, skip (idempotency)
      if (await destFile.exists()) return;

      // Check if it's an image by extension
      final ext = p.extension(originalPath).toLowerCase();
      const validExtensions = {
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
        '.gif',
        '.bmp',
      };
      if (!validExtensions.contains(ext)) return;

      final keyBytes = await key.extractBytes();

      // use compute for better Flutter integration
      await compute(
        _generateEncryptedThumbnailWorker,
        _GenThumbArgs(originalPath, destPath, keyBytes),
      );
    } catch (e) {
      print('ThumbnailService: Error generating from file: $e');
    }
  }

  Future<void> generateThumbnailFromBytes({
    required Uint8List bytes,
    required String fileId,
    required SecretKey key,
  }) async {
    try {
      final dirPath = await _thumbnailsPath;
      final destPath = p.join(dirPath, '$fileId.enc');
      final destFile = File(destPath);
      if (await destFile.exists()) return;

      final keyBytes = await key.extractBytes();

      await compute(
        _generateEncryptedThumbnailBytesWorker,
        _GenThumbBytesArgs(bytes, destPath, keyBytes),
      );
    } catch (e) {
      print('ThumbnailService: Error generating from bytes: $e');
    }
  }

  Future<void> deleteThumbnail(String fileId) async {
    try {
      final dirPath = await _thumbnailsPath;
      final file = File(p.join(dirPath, '$fileId.enc'));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

// Top-level functions for compute must be outside the class

class _GenThumbArgs {
  final String path;
  final String dest;
  final List<int> keyBytes;
  _GenThumbArgs(this.path, this.dest, this.keyBytes);
}

class _GenThumbBytesArgs {
  final Uint8List bytes;
  final String dest;
  final List<int> keyBytes;
  _GenThumbBytesArgs(this.bytes, this.dest, this.keyBytes);
}

Future<void> _generateEncryptedThumbnailWorker(_GenThumbArgs args) async {
  final file = File(args.path);
  if (!file.existsSync()) return;

  try {
    // 1. Image Processing
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final resized = img.copyResize(image, width: 300);
    final jpgBytes = img.encodeJpg(resized, quality: 70);

    // 2. Encryption
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(args.keyBytes);
    final secretBox = await algorithm.encrypt(jpgBytes, secretKey: secretKey);

    final encryptedBytes = secretBox.concatenation();

    // 3. Save
    await File(args.dest).writeAsBytes(encryptedBytes);
  } catch (e) {
    print("Worker error: $e");
  }
}

Future<void> _generateEncryptedThumbnailBytesWorker(
  _GenThumbBytesArgs args,
) async {
  try {
    // 1. Image Processing
    final image = img.decodeImage(args.bytes);
    if (image == null) return;

    final resized = img.copyResize(image, width: 300);
    final jpgBytes = img.encodeJpg(resized, quality: 70);

    // 2. Encryption
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(args.keyBytes);
    final secretBox = await algorithm.encrypt(jpgBytes, secretKey: secretKey);

    final encryptedBytes = secretBox.concatenation();

    // 3. Save
    await File(args.dest).writeAsBytes(encryptedBytes);
  } catch (e) {
    print("Worker bytes error: $e");
  }
}
