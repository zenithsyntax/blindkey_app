import 'dart:typed_data';

import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dartz/dartz.dart';

class CryptographyService {
  final _algorithm = AesGcm.with256bits();
  final _argon2 = Argon2id(
    parallelism: 1,
    memory: 65536, // 64 MB
    iterations: 4,
    hashLength: 32,
  );

  Future<SecretKey> generateRandomKey() async {
    return _algorithm.newSecretKey();
  }

  Future<SecretKey> deriveKeyFromPassword(String password, List<int> salt) async {
    return _argon2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  /// Encrypts a chunk of data.
  /// For streaming large files, we might treat each chunk as a separate message 
  /// or use a streaming cipher mode. 
  /// However, AES-GCM is meant for discrete messages. 
  /// For file encryption, it's often better to encrypt chunks with a counter nonce 
  /// or using AesCtr + HMAC if we want random access.
  /// 
  /// Requirement: "Streaming encryption (chunk-based)".
  /// Requirement: "View files instantly inside the app (no lag)".
  /// Random access for video seeking suggests AES-CTR is better than GCM for the file content 
  /// if we want efficient seeking without decrypting everything.
  /// BUT, usually simpler is safer. GCM is authenticated. CTR is not (needs HMAC).
  /// 
  /// Let's stick to a standard approach:
  /// Encrypting the WHOLE file as one stream might be hard with GCM because of tag at the end? 
  /// Actually, standard GCM produces tag at end.
  /// 
  /// If we want random access (seeking video), we should probably use chunks of fixed size (e.g. 1MB),
  /// each encrypted with GCM and its own nonce (derived from base nonce + chunk index).
  /// This allows decrypting just byte 50MB-51MB.
  /// 
  /// Let's implement `encryptData` and `decryptData` for small blobs (metadata, keys).
  /// File encryption will be handled by `FileEncryptionService` consuming this.
  
  Future<Either<Failure, List<int>>> encryptData({
    required List<int> data,
    required SecretKey key,
  }) async {
    try {
      final secretBox = await _algorithm.encrypt(
        data,
        secretKey: key,
      );
      return right(secretBox.concatenation());
    } catch (e) {
      return left(Failure.encryptionError(e.toString()));
    }
  }

  Future<Either<Failure, List<int>>> decryptData({
    required List<int> encryptedData,
    required SecretKey key,
  }) async {
    try {
      final secretBox = SecretBox.fromConcatenation(
        encryptedData,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );
      final clearText = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
      );
      return right(clearText);
    } catch (e) {
      return left(Failure.encryptionError('Decryption failed: $e'));
    }
  }
}
