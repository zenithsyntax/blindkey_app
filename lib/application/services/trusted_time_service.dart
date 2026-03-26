import 'package:http/http.dart' as http;
import 'dart:io';

class TrustedTimeService {
  /// Fetches the current time from a trusted HTTPS source (Google).
  /// This prevents MITM time spoofing attacks associated with unencrypted NTP.
  /// Throws an exception if internet is unavailable or sources are unreachable.
  Future<DateTime> getTrustedTime() async {
    try {
      // Using google.com as a reliable high-availability server.
      // The HTTPS connection ensures TLS protection against MITM time spoofing.
      final response = await http.head(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        final dateStr = response.headers['date'];
        if (dateStr != null) {
          // HTTP Date format: "Tue, 15 Nov 1994 08:12:31 GMT"
          return HttpDate.parse(dateStr).toLocal(); 
        }
      }
      throw Exception('Invalid time response from trusted server');
    } catch (e) {
      throw Exception('Internet connection is required to verify time: $e');
    }
  }
}
