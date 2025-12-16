// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FolderModelImpl _$$FolderModelImplFromJson(Map<String, dynamic> json) =>
    _$FolderModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      salt: json['salt'] as String,
      verificationHash: json['verificationHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$FolderModelImplToJson(_$FolderModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'salt': instance.salt,
      'verificationHash': instance.verificationHash,
      'createdAt': instance.createdAt.toIso8601String(),
    };
