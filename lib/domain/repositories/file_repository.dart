import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/domain/models/file_model.dart';
import 'package:dartz/dartz.dart';

abstract class FileRepository {
  Future<Either<Failure, List<FileModel>>> getFiles(String folderId);
  Future<Either<Failure, Unit>> saveFileModel(FileModel file);
  Future<Either<Failure, Unit>> deleteFile(String fileId);
}
