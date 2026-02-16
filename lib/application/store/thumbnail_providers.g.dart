// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thumbnail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileMetadataHash() => r'f81a63ef9e808508083e80385f22afc0dfbd4aa5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [fileMetadata].
@ProviderFor(fileMetadata)
const fileMetadataProvider = FileMetadataFamily();

/// See also [fileMetadata].
class FileMetadataFamily extends Family<AsyncValue<FileMetadata>> {
  /// See also [fileMetadata].
  const FileMetadataFamily();

  /// See also [fileMetadata].
  FileMetadataProvider call(FileModel file, SecretKey key) {
    return FileMetadataProvider(file, key);
  }

  @override
  FileMetadataProvider getProviderOverride(
    covariant FileMetadataProvider provider,
  ) {
    return call(provider.file, provider.key);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fileMetadataProvider';
}

/// See also [fileMetadata].
class FileMetadataProvider extends AutoDisposeFutureProvider<FileMetadata> {
  /// See also [fileMetadata].
  FileMetadataProvider(FileModel file, SecretKey key)
    : this._internal(
        (ref) => fileMetadata(ref as FileMetadataRef, file, key),
        from: fileMetadataProvider,
        name: r'fileMetadataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fileMetadataHash,
        dependencies: FileMetadataFamily._dependencies,
        allTransitiveDependencies:
            FileMetadataFamily._allTransitiveDependencies,
        file: file,
        key: key,
      );

  FileMetadataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.file,
    required this.key,
  }) : super.internal();

  final FileModel file;
  final SecretKey key;

  @override
  Override overrideWith(
    FutureOr<FileMetadata> Function(FileMetadataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FileMetadataProvider._internal(
        (ref) => create(ref as FileMetadataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        file: file,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<FileMetadata> createElement() {
    return _FileMetadataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FileMetadataProvider &&
        other.file == file &&
        other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, file.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FileMetadataRef on AutoDisposeFutureProviderRef<FileMetadata> {
  /// The parameter `file` of this provider.
  FileModel get file;

  /// The parameter `key` of this provider.
  SecretKey get key;
}

class _FileMetadataProviderElement
    extends AutoDisposeFutureProviderElement<FileMetadata>
    with FileMetadataRef {
  _FileMetadataProviderElement(super.provider);

  @override
  FileModel get file => (origin as FileMetadataProvider).file;
  @override
  SecretKey get key => (origin as FileMetadataProvider).key;
}

String _$fileThumbnailHash() => r'8904f1f3dbd967c719282d3e3307a5c28d94c220';

/// See also [fileThumbnail].
@ProviderFor(fileThumbnail)
const fileThumbnailProvider = FileThumbnailFamily();

/// See also [fileThumbnail].
class FileThumbnailFamily extends Family<AsyncValue<Uint8List?>> {
  /// See also [fileThumbnail].
  const FileThumbnailFamily();

  /// See also [fileThumbnail].
  FileThumbnailProvider call(FileModel file, SecretKey key) {
    return FileThumbnailProvider(file, key);
  }

  @override
  FileThumbnailProvider getProviderOverride(
    covariant FileThumbnailProvider provider,
  ) {
    return call(provider.file, provider.key);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fileThumbnailProvider';
}

/// See also [fileThumbnail].
class FileThumbnailProvider extends AutoDisposeFutureProvider<Uint8List?> {
  /// See also [fileThumbnail].
  FileThumbnailProvider(FileModel file, SecretKey key)
    : this._internal(
        (ref) => fileThumbnail(ref as FileThumbnailRef, file, key),
        from: fileThumbnailProvider,
        name: r'fileThumbnailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fileThumbnailHash,
        dependencies: FileThumbnailFamily._dependencies,
        allTransitiveDependencies:
            FileThumbnailFamily._allTransitiveDependencies,
        file: file,
        key: key,
      );

  FileThumbnailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.file,
    required this.key,
  }) : super.internal();

  final FileModel file;
  final SecretKey key;

  @override
  Override overrideWith(
    FutureOr<Uint8List?> Function(FileThumbnailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FileThumbnailProvider._internal(
        (ref) => create(ref as FileThumbnailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        file: file,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Uint8List?> createElement() {
    return _FileThumbnailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FileThumbnailProvider &&
        other.file == file &&
        other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, file.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FileThumbnailRef on AutoDisposeFutureProviderRef<Uint8List?> {
  /// The parameter `file` of this provider.
  FileModel get file;

  /// The parameter `key` of this provider.
  SecretKey get key;
}

class _FileThumbnailProviderElement
    extends AutoDisposeFutureProviderElement<Uint8List?>
    with FileThumbnailRef {
  _FileThumbnailProviderElement(super.provider);

  @override
  FileModel get file => (origin as FileThumbnailProvider).file;
  @override
  SecretKey get key => (origin as FileThumbnailProvider).key;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
