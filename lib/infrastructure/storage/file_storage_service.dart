import 'dart:io';

import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileStorageService {
  Future<String> get _documentPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<Either<Failure, String>> createEncryptedFileDir() async {
    try {
      final path = await _documentPath;
      final dir = Directory(p.join(path, 'vault'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return right(dir.path);
    } catch (e) {
      return left(Failure.fileSystemError(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      return right(unit);
    } catch (e) {
      return left(Failure.fileSystemError(e.toString()));
    }
  }
}
