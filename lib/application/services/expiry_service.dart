import 'dart:async';
import 'package:blindkey_app/application/services/thumbnail_service.dart';
import 'package:blindkey_app/application/services/trusted_time_service.dart';
import 'package:blindkey_app/domain/repositories/file_repository.dart';

class ExpiryService {
  final FileRepository _fileRepository;
  final TrustedTimeService _trustedTimeService;
  final ThumbnailService _thumbnailService;

  Timer? _timer;
  final _deletionController = StreamController<void>.broadcast();
  Stream<void> get onFileDeleted => _deletionController.stream;

  ExpiryService(
    this._fileRepository,
    this._trustedTimeService,
    this._thumbnailService,
  );

  void initialize() {
    _checkExpiry(); // Check immediately on startup
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkExpiry());
  }

  void dispose() {
    _timer?.cancel();
    _deletionController.close();
  }

  Future<void> _checkExpiry() async {
    try {
      // Use trusted time if available, else device time
      DateTime now;
      try {
        now = await _trustedTimeService.getTrustedTime();
      } catch (_) {
        now = DateTime.now();
      }

      final result = await _fileRepository.getExpiredFiles(now);

      result.fold(
        (failure) {
          // Silent failure or log if you have a logger
        },
        (expiredFiles) async {
          bool anyDeleted = false;
          for (final file in expiredFiles) {
            // Delete file and thumbnail
            // We ignore errors here to ensure loop continues
            try {
              await _fileRepository.deleteFile(file.id);
              anyDeleted = true;
            } catch (_) {}

            try {
              await _thumbnailService.deleteThumbnail(file.id);
            } catch (_) {}
          }
          if (anyDeleted) {
            _deletionController.add(null);
          }
        },
      );
    } catch (_) {
      // Silent error handling for background service
    }
  }
}
