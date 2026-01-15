import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final fileIntentServiceProvider =
    StateNotifierProvider<FileIntentNotifier, String?>((ref) {
      return FileIntentNotifier();
    });

class FileIntentNotifier extends StateNotifier<String?> {
  late AppLinks _appLinks;
  StreamSubscription? _sub;
  static const platform = MethodChannel('com.example.blindkey_app/file_utils');

  // Debounce tracking
  Uri? _lastProcessedUri;
  DateTime? _lastProcessedTime;

  FileIntentNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Initial link error: $e');
    }

    // Listen to stream
    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('Link stream error: $err');
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    // Debounce duplicate intents
    if (_lastProcessedUri == uri &&
        _lastProcessedTime != null &&
        DateTime.now().difference(_lastProcessedTime!) <
            const Duration(seconds: 2)) {
      debugPrint("Ignoring duplicate intent for URI: $uri");
      return;
    }
    _lastProcessedUri = uri;
    _lastProcessedTime = DateTime.now();

    debugPrint("FileIntentNotifier received URI: $uri");
    debugPrint("FileIntentNotifier Scheme: ${uri.scheme}");
    debugPrint("FileIntentNotifier Path: ${uri.path}");

    // Logic updated: WE MUST TRUST THE INTENT FILTER.
    // If the app was opened, it's likely a valid file.
    // If scheme is content, we might not see .blindkey in the URI path itself.
    // So we should attempt to resolve it if it's content, regardless of extension check on the URI.

    try {
      if (uri.scheme == 'file') {
        if (uri.path.toLowerCase().endsWith('.blindkey') ||
            uri.toString().toLowerCase().contains('.blindkey')) {
          state = uri.toFilePath();
        }
      } else if (uri.scheme == 'content') {
        // Content URIs often don't have the filename or extension in the path part.
        // We should try to resolve it.
        try {
          debugPrint("Attempting to resolve content URI: $uri");
          final String? path = await platform.invokeMethod(
            'resolveContentUri',
            {'uri': uri.toString()},
          );
          debugPrint("Resolved path from native: $path");
          if (path != null) {
            state = path;
          }
        } catch (e) {
          debugPrint("Error resolving content URI via channel: $e");
        }
      }
    } catch (e) {
      debugPrint("Handle URI Error: $e");
    }
  }

  void clearIntent() {
    if (mounted) {
      state = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
