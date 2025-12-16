import 'package:blindkey_app/domain/failures/failures.dart';
import 'package:blindkey_app/domain/models/folder_model.dart';
import 'package:dartz/dartz.dart';

abstract class FolderRepository {
  Future<Either<Failure, List<FolderModel>>> getFolders();
  Future<Either<Failure, Unit>> saveFolder(FolderModel folder);
  Future<Either<Failure, FolderModel>> getFolder(String id);
  Future<Either<Failure, Unit>> deleteFolder(String id);
}
