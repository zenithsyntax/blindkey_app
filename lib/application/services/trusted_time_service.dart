import 'package:ntp/ntp.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class TrustedTimeService {
  /// Fetches the current time from a trusted source (NTP or HTTPS).
  /// Throws an exception if internet is unavailable or sources are unreachable.
  Future<DateTime> getTrustedTime() async {
    try {
      // 1. Try NTP (Network Time Protocol) - fast and accurate
      // Uses pool.ntp.org by default
      final offset = await NTP.getNtpOffset(localTime: DateTime.now());
      return DateTime.now().add(Duration(milliseconds: offset));
    } catch (e) {
      // 2. Fallback to HTTPS Time (Google) if NTP fails (e.g. firewall)
      return await _getHttpTime();
    }
  }

  Future<DateTime> _getHttpTime() async {
    try {
      // Using google.com as a reliable high-availability server
      final response = await http.head(Uri.parse('https://www.google.com'));
      if (response.statusCode == 200) {
        final dateStr = response.headers['date'];
        if (dateStr != null) {
          // HTTP Date format: "Tue, 15 Nov 1994 08:12:31 GMT"
          return HttpDate.parse(dateStr).toLocal(); 
        }
      }
      throw Exception('Invalid time response');
    } catch (e) {
      throw Exception('Internet connection is required to verify time: $e');
    }
  }
}
