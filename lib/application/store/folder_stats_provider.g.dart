// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$folderStatsHash() => r'ecd597b2169445c06ec49991fa99d5aaf5729498';

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

/// See also [folderStats].
@ProviderFor(folderStats)
const folderStatsProvider = FolderStatsFamily();

/// See also [folderStats].
class FolderStatsFamily extends Family<AsyncValue<FolderStats>> {
  /// See also [folderStats].
  const FolderStatsFamily();

  /// See also [folderStats].
  FolderStatsProvider call(String folderId) {
    return FolderStatsProvider(folderId);
  }

  @override
  FolderStatsProvider getProviderOverride(
    covariant FolderStatsProvider provider,
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
  String? get name => r'folderStatsProvider';
}

/// See also [folderStats].
class FolderStatsProvider extends AutoDisposeFutureProvider<FolderStats> {
  /// See also [folderStats].
  FolderStatsProvider(String folderId)
    : this._internal(
        (ref) => folderStats(ref as FolderStatsRef, folderId),
        from: folderStatsProvider,
        name: r'folderStatsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$folderStatsHash,
        dependencies: FolderStatsFamily._dependencies,
        allTransitiveDependencies: FolderStatsFamily._allTransitiveDependencies,
        folderId: folderId,
      );

  FolderStatsProvider._internal(
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
  Override overrideWith(
    FutureOr<FolderStats> Function(FolderStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FolderStatsProvider._internal(
        (ref) => create(ref as FolderStatsRef),
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
  AutoDisposeFutureProviderElement<FolderStats> createElement() {
    return _FolderStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FolderStatsProvider && other.folderId == folderId;
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
mixin FolderStatsRef on AutoDisposeFutureProviderRef<FolderStats> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _FolderStatsProviderElement
    extends AutoDisposeFutureProviderElement<FolderStats>
    with FolderStatsRef {
  _FolderStatsProviderElement(super.provider);

  @override
  String get folderId => (origin as FolderStatsProvider).folderId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
