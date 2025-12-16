import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_model.freezed.dart';
part 'folder_model.g.dart';

@freezed
class FolderModel with _$FolderModel {
  const factory FolderModel({
    required String id,
    required String name,
    required String salt, // Base64 encoded salt for key derivation
    required String verificationHash, // Base64 encoded hash to verify password
    required DateTime createdAt,
  }) = _FolderModel;

  factory FolderModel.fromJson(Map<String, dynamic> json) => _$FolderModelFromJson(json);
}
