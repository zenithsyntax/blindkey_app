import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_model.freezed.dart';
part 'file_model.g.dart';

@freezed
class FileModel with _$FileModel {
  const factory FileModel({
    required String id,
    required String folderId,
    required String encryptedMetadata, // Base64 encoded encrypted JSON of FileMetadata
    required String encryptedPreviewPath, // Path to encrypted thumbnail (optional)
    DateTime? expiryDate, // Plaintext expiry to allow background cleanup? 
    // "Expiry enforced locally inside app... Remove file from app database".
    // If we encrypt expiry, we can't check it without unlocking. 
    // "Delete decrypted data... Remove file from app database"
    // "If receiver opens file after expiry... Show message... Delete" 
    // This implies we check on open. But "Upload .blindkey... Checks expiry... If valid -> imports".
    // So Expiry should probably be readable or checked against current time.
    // If we want "No plaintext...", we can't store expiry in plaintext.
    // However, if we only check expiry when we TRY to view/decrypt, then it's fine to be encrypted.
    // But "deletes automatically" suggests a background job? 
    // User said: "If receiver opens file after expiry: Show message... Immediately Delete"
    // So it happens ON ACTION. So encrypted expiry is fine.
  }) = _FileModel;

  factory FileModel.fromJson(Map<String, dynamic> json) => _$FileModelFromJson(json);
}

@freezed
class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    required String id,
    required String fileName,
    required int size,
    required String mimeType,
    required String encryptedFilePath, // Path to the actual encrypted content file on disk
    required String fileKey, // Base64 encoded random key for this file
    required String nonce, // Base64 encoded IV/Nonce for the file content encryption
    required bool allowSaveToDownloads,
    DateTime? expiryDate,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) => _$FileMetadataFromJson(json);
}
