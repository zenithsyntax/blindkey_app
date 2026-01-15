import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@riverpod
Stream<List<ConnectivityResult>> connectivityStatus(ConnectivityStatusRef ref) {
  return Connectivity().onConnectivityChanged;
}

/// Simplified provider that returns true if there is probably internet access
/// (Note: connectivity doesn't guarantee internet, just network connection, but good enough for UI hint)
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return !results.contains(ConnectivityResult.none);
  });
});
