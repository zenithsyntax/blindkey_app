// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileNotifierHash() => r'7f9d8a1a4d9b6deed36dc7fbfcb6db2c3bfb2fda';

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

abstract class _$FileNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<FileModel>> {
  late final String folderId;

  FutureOr<List<FileModel>> build(String folderId);
}

/// See also [FileNotifier].
@ProviderFor(FileNotifier)
const fileNotifierProvider = FileNotifierFamily();

/// See also [FileNotifier].
class FileNotifierFamily extends Family<AsyncValue<List<FileModel>>> {
  /// See also [FileNotifier].
  const FileNotifierFamily();

  /// See also [FileNotifier].
  FileNotifierProvider call(String folderId) {
    return FileNotifierProvider(folderId);
  }

  @override
  FileNotifierProvider getProviderOverride(
    covariant FileNotifierProvider provider,
  ) {
    return call(provider.folderId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fileNotifierProvider';
}

/// See also [FileNotifier].
class FileNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<FileNotifier, List<FileModel>> {
  /// See also [FileNotifier].
  FileNotifierProvider(String folderId)
    : this._internal(
        () => FileNotifier()..folderId = folderId,
        from: fileNotifierProvider,
        name: r'fileNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fileNotifierHash,
        dependencies: FileNotifierFamily._dependencies,
        allTransitiveDependencies:
            FileNotifierFamily._allTransitiveDependencies,
        folderId: folderId,
      );

  FileNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  FutureOr<List<FileModel>> runNotifierBuild(covariant FileNotifier notifier) {
    return notifier.build(folderId);
  }

  @override
  Override overrideWith(FileNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FileNotifierProvider._internal(
        () => create()..folderId = folderId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<FileNotifier, List<FileModel>>
  createElement() {
    return _FileNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FileNotifierProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FileNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<FileModel>> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _FileNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<FileNotifier, List<FileModel>>
    with FileNotifierRef {
  _FileNotifierProviderElement(super.provider);

  @override
  String get folderId => (origin as FileNotifierProvider).folderId;
}

String _$uploadProgressHash() => r'd252b59668041ecabebc639e092d58c214e85407';

/// See also [UploadProgress].
@ProviderFor(UploadProgress)
final uploadProgressProvider =
    NotifierProvider<UploadProgress, Map<String, double>>.internal(
      UploadProgress.new,
      name: r'uploadProgressProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadProgressHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UploadProgress = Notifier<Map<String, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
