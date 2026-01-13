import 'package:blindkey_app/domain/failures/failures.dart';

class ErrorMapper {
  static String getUserFriendlyError(Object error) {
    if (error is Failure) {
      return error.when(
        databaseError: (_) => "Something went wrong with the app's data. Please restart.",
        fileSystemError: (_) => "We couldn't access the storage. Check your permissions or space.",
        encryptionError: (_) => "Access denied. Please check your password.",
        invalidPassword: () => "The password is incorrect. Please try again.",
        fileExpired: () => "This file has expired and is no longer available.",
        permissionDenied: () => "We need permission to save files. Please allow it in Settings.",
        unexpected: (msg) => _cleanUnexpectedError(msg),
      );
    }
    return _cleanUnexpectedError(error.toString());
  }

  static String _cleanUnexpectedError(String message) {
    // Strip "Exception:" or "Error:" prefix if present
    var clean = message.replaceAll(RegExp(r'^(Exception|Error):\s*'), '');
    
    // Common technical error substrings mapping
    if (clean.contains("Internet connection") || clean.contains("SocketException") || clean.contains("Network is unreachable") || clean.contains("HandshakeException")) {
      return "Please check your internet connection and try again.";
    }
    if (clean.contains("Corrupt block") || clean.contains("Padding") || clean.contains("Mac mismatch")) {
      return "This file seems to be damaged and cannot be opened.";
    }
    if (clean.contains("Storage Error") || clean.contains("FileSystemException")) {
      return "We encountered a problem saving or reading this file.";
    }
    if (clean.contains("Folder not found") || clean.contains("File not found")) {
      return "We couldn't find that item. It may have been deleted.";
    }
    if (clean.contains("Metadata") || clean.contains("decrypt")) {
      return "We couldn't unlock this Item. Please ensure you have the right access.";
    }
    if (clean.contains("Invalid time") || clean.contains("Time")) {
      return "We couldn't ensure the time is correct. Check your connection.";
    }
    
    // Fallback for truly unknown errors
    return "Something went wrong ($clean). Please try again.";
  }
}
