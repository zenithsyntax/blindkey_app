// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FileModelImpl _$$FileModelImplFromJson(Map<String, dynamic> json) =>
    _$FileModelImpl(
      id: json['id'] as String,
      folderId: json['folderId'] as String,
      encryptedMetadata: json['encryptedMetadata'] as String,
      encryptedPreviewPath: json['encryptedPreviewPath'] as String,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
    );

Map<String, dynamic> _$$FileModelImplToJson(_$FileModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'folderId': instance.folderId,
      'encryptedMetadata': instance.encryptedMetadata,
      'encryptedPreviewPath': instance.encryptedPreviewPath,
      'expiryDate': instance.expiryDate?.toIso8601String(),
    };

_$FileMetadataImpl _$$FileMetadataImplFromJson(Map<String, dynamic> json) =>
    _$FileMetadataImpl(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      encryptedFilePath: json['encryptedFilePath'] as String,
      fileKey: json['fileKey'] as String,
      nonce: json['nonce'] as String,
      allowSaveToDownloads: json['allowSaveToDownloads'] as bool,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
    );

Map<String, dynamic> _$$FileMetadataImplToJson(_$FileMetadataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'size': instance.size,
      'mimeType': instance.mimeType,
      'encryptedFilePath': instance.encryptedFilePath,
      'fileKey': instance.fileKey,
      'nonce': instance.nonce,
      'allowSaveToDownloads': instance.allowSaveToDownloads,
      'expiryDate': instance.expiryDate?.toIso8601String(),
    };
